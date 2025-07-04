import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteUserPage extends StatefulWidget {
  final String groupId;
  const InviteUserPage({super.key, required this.groupId});

  @override
  State<InviteUserPage> createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
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
      // Add pending invite to user
      final groupDoc =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();
      final groupName = groupDoc['name'] ?? '';
      final currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pendingInvites')
          .add({
            'groupId': widget.groupId,
            'groupName': groupName,
            'invitedBy': currentUser?.uid ?? '',
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
          });
      setState(() {
        loading = false;
        _inviteController.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite sent!')));
    } catch (e) {
      setState(() {
        error = 'Failed to invite user';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inviteController,
              decoration: const InputDecoration(labelText: 'Username or Email'),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: inviteUser,
                  child: const Text('Send Invite'),
                ),
          ],
        ),
      ),
    );
  }
}
