import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

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
      appBar: AppBar(
        title: Text(
          'Invite User',
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
      body: Stack(
        children: [
          Positioned.fill(
            child: WaveWidget(
              config: CustomConfig(
                gradients: [
                  [const Color(0xFF6D0EB5), const Color(0xFF4059F1)],
                  [const Color(0xFF4059F1), const Color(0xFF6D0EB5)],
                ],
                durations: [35000, 19440],
                heightPercentages: [0.20, 0.23],
                blur: const MaskFilter.blur(BlurStyle.solid, 10),
                gradientBegin: Alignment.topLeft,
                gradientEnd: Alignment.bottomRight,
              ),
              waveAmplitude: 0,
              size: const Size(double.infinity, double.infinity),
            ),
          ),
          Positioned.fill(
            child: Padding(
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
                          'Invite a User',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _inviteController,
                          decoration: InputDecoration(
                            labelText: 'Username or Email',
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
                              onPressed: inviteUser,
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
                                'Send Invite',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
