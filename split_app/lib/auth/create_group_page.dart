import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  String error = '';
  bool loading = false;

  Future<void> createGroup() async {
    setState(() {
      error = '';
      loading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      setState(() {
        error = 'Group name required';
        loading = false;
      });
      return;
    }
    try {
      final groupRef = await FirebaseFirestore.instance
          .collection('groups')
          .add({
            'name': groupName,
            'admin': user.uid,
            'members': [user.uid],
          });
      // Add group to user's groups list
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'groups': FieldValue.arrayUnion([groupRef.id]),
        },
      );
      Navigator.of(context).pop(); // Go back after creation
    } catch (e) {
      setState(() {
        error = 'Failed to create group';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
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
                  onPressed: createGroup,
                  child: const Text('Create Group'),
                ),
          ],
        ),
      ),
    );
  }
}
