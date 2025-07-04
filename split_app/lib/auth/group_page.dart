import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage({super.key, required this.groupId});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _inviteController = TextEditingController();
  String error = '';
  bool loading = false;

  Future<void> inviteUser() async {
    setState(() {
      error = '';
      loading = true;
    });
    final input = _inviteController.text.trim();
    if (input.isEmpty) {
      setState(() {
        error = 'Enter username or email';
        loading = false;
      });
      return;
    }
    try {
      // Find user by username or email
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input)
              .get();
      final emailQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: input)
              .get();
      final userDoc =
          userQuery.docs.isNotEmpty
              ? userQuery.docs.first
              : (emailQuery.docs.isNotEmpty ? emailQuery.docs.first : null);
      if (userDoc == null) {
        setState(() {
          error = 'User not found';
          loading = false;
        });
        return;
      }
      final userId = userDoc.id;
      // Add user to group members
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
            'members': FieldValue.arrayUnion([userId]),
          });
      // Add group to user's groups
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'groups': FieldValue.arrayUnion([widget.groupId]),
      });
      setState(() {
        loading = false;
        _inviteController.clear();
      });
    } catch (e) {
      setState(() {
        error = 'Failed to invite user';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? '';
          final admin = data['admin'] ?? '';
          final members = List<String>.from(data['members'] ?? []);
          final isAdmin = user != null && user.uid == admin;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group Name: $name', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Admin: $admin', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Text(
                  'Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...members.map(
                  (uid) => FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const Text('Loading...');
                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>?;
                      if (userData == null) return Text(uid);
                      return Text(
                        userData['username'] ?? userData['email'] ?? uid,
                      );
                    },
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _inviteController,
                    decoration: const InputDecoration(
                      labelText: 'Invite by username or email',
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: inviteUser,
                        child: const Text('Invite User'),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
