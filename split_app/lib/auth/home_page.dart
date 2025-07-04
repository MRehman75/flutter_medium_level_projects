import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Logged in as: \\${user?.email ?? "Unknown"}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/profile'),
              child: const Text('View Profile'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/create_group'),
              child: const Text('Create Group'),
            ),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('groups').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final groups =
                      snapshot.data!.docs.map((doc) => doc.id).toList();
                  return groups.isEmpty
                      ? const Text('No groups yet.')
                      : ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final groupId = groups[index];
                          return ListTile(
                            title: FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(groupId)
                                      .get(),
                              builder: (context, groupSnap) {
                                if (!groupSnap.hasData)
                                  return const Text('Loading...');
                                final groupData =
                                    groupSnap.data!.data()
                                        as Map<String, dynamic>?;
                                if (groupData == null)
                                  return const Text('Group not found');
                                return Text(
                                  groupData['name'] ?? 'Unnamed Group',
                                );
                              },
                            ),
                            onTap:
                                () => Navigator.of(
                                  context,
                                ).pushNamed('/group', arguments: groupId),
                          );
                        },
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
