import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _cashController = TextEditingController();
  String error = '';
  bool loading = false;

  Future<void> addCash(String userId, double amount) async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'cash': FieldValue.increment(amount),
      });
      _cashController.clear();
    } catch (e) {
      setState(() {
        error = 'Failed to add cash';
      });
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('No user logged in.'));
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
          final cash = (data['cash'] ?? 0.0) as num;
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
                Text(
                  'Cash Balance: Rs. ${cash.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cashController,
                        decoration: const InputDecoration(
                          labelText: 'Add Cash (Rs.)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          loading
                              ? null
                              : () {
                                final amount = double.tryParse(
                                  _cashController.text.trim(),
                                );
                                if (amount != null && amount > 0) {
                                  addCash(user.uid, amount);
                                }
                              },
                      child:
                          loading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Add'),
                    ),
                  ],
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
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
