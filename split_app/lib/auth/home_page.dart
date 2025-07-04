import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in.'));
    }
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final groupIds = List<String>.from(data['groups'] ?? []);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Logged in as: ${user.email ?? "Unknown"}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/profile'),
                  child: const Text('View Profile'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).pushNamed('/create_group'),
                  child: const Text('Create Group'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Groups:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child:
                      groupIds.isEmpty
                          ? const Text('No groups yet.')
                          : FutureBuilder<QuerySnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('groups')
                                    .where(
                                      FieldPath.documentId,
                                      whereIn: groupIds,
                                    )
                                    .get(),
                            builder: (context, groupSnap) {
                              if (!groupSnap.hasData)
                                return const CircularProgressIndicator();
                              final groupDocs = groupSnap.data!.docs;
                              if (groupDocs.isEmpty)
                                return const Text('No groups found.');
                              return ListView.builder(
                                itemCount: groupDocs.length,
                                itemBuilder: (context, index) {
                                  final groupData =
                                      groupDocs[index].data()
                                          as Map<String, dynamic>;
                                  final groupId = groupDocs[index].id;
                                  final groupName =
                                      groupData['name'] ?? 'Unnamed Group';
                                  return ListTile(
                                    title: Text(groupName),
                                    onTap:
                                        () => Navigator.of(context).pushNamed(
                                          '/group',
                                          arguments: groupId,
                                        ),
                                  );
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
