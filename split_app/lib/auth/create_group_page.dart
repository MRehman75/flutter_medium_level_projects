import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        title: Text(
          'Create Group',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D0EB5), Color(0xFF4059F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create a Group',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: GoogleFonts.openSans(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        error,
                        style: GoogleFonts.openSans(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4059F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 32,
                          ),
                        ),
                        child: Text(
                          'Create Group',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
