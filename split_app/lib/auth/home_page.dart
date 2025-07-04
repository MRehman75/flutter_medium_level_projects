import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          ],
        ),
      ),
    );
  }
}
