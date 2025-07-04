import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final username = data['username'] ?? '';
          final email = data['email'] ?? '';
          final groups = List<String>.from(data['groups'] ?? []);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Username: $username',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text('Email: $email', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                const Text(
                  'Groups:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...groups.isEmpty
                    ? [const Text('No groups yet.')]
                    : groups.map((g) => Text(g)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
