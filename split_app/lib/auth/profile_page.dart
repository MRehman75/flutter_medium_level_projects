import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

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

  Future<void> acceptInvite(
    String inviteId,
    String groupId,
    String groupName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Add user to group members
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([user.uid]),
    });
    // Add group to user's groups
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });
    // Remove invite
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pendingInvites')
        .doc(inviteId)
        .delete();
  }

  Future<void> rejectInvite(String inviteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pendingInvites')
        .doc(inviteId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('No user logged in.'));
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
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
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            child: FutureBuilder<DocumentSnapshot>(
              future: userDoc.get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final username = data['username'] ?? '';
                final email = data['email'] ?? '';
                final groups = List<String>.from(data['groups'] ?? []);
                final cash = (data['cash'] ?? 0.0) as num;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF6D0EB5),
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.montserrat(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                username,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF4059F1),
                                ),
                                tooltip: 'Edit Profile',
                                onPressed: () async {
                                  final usernameController =
                                      TextEditingController(text: username);
                                  final emailController = TextEditingController(
                                    text: email,
                                  );
                                  String dialogError = '';
                                  bool saving = false;
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: Text(
                                              'Edit Profile',
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller:
                                                      usernameController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Username',
                                                    labelStyle:
                                                        GoogleFonts.openSans(),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: emailController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Email',
                                                    labelStyle:
                                                        GoogleFonts.openSans(),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                if (dialogError.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ),
                                                    child: Text(
                                                      dialogError,
                                                      style:
                                                          GoogleFonts.openSans(
                                                            color: Colors.red,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.openSans(),
                                                ),
                                              ),
                                              saving
                                                  ? const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 16.0,
                                                        ),
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  )
                                                  : ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF4059F1,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      setState(() {
                                                        dialogError = '';
                                                        saving = true;
                                                      });
                                                      try {
                                                        // Update Firestore
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(user.uid)
                                                            .update({
                                                              'username':
                                                                  usernameController
                                                                      .text
                                                                      .trim(),
                                                              'email':
                                                                  emailController
                                                                      .text
                                                                      .trim(),
                                                            });
                                                        // Update FirebaseAuth email if changed
                                                        if (email !=
                                                            emailController.text
                                                                .trim()) {
                                                          await user
                                                              .updateEmail(
                                                                emailController
                                                                    .text
                                                                    .trim(),
                                                              );
                                                        }
                                                        setState(() {
                                                          saving = false;
                                                        });
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(
                                                          () {},
                                                        ); // Refresh UI
                                                      } on FirebaseAuthException catch (
                                                        e
                                                      ) {
                                                        setState(() {
                                                          dialogError =
                                                              e.message ??
                                                              'Failed to update profile.';
                                                          saving = false;
                                                        });
                                                      } catch (e) {
                                                        setState(() {
                                                          dialogError =
                                                              'Failed to update profile.';
                                                          saving = false;
                                                        });
                                                      }
                                                    },
                                                    child: Text(
                                                      'Save',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            email,
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash Balance',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rs. ${cash.toStringAsFixed(2)}',
                                  style: GoogleFonts.openSans(fontSize: 18),
                                ),
                                const SizedBox(height: 12),
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
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4059F1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 20,
                                        ),
                                      ),
                                      onPressed:
                                          loading
                                              ? null
                                              : () {
                                                final amount = double.tryParse(
                                                  _cashController.text.trim(),
                                                );
                                                if (amount != null &&
                                                    amount > 0) {
                                                  addCash(user.uid, amount);
                                                }
                                              },
                                      child:
                                          loading
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
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
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Groups',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...groups.isEmpty
                                    ? [
                                      Text(
                                        'No groups yet.',
                                        style: GoogleFonts.openSans(),
                                      ),
                                    ]
                                    : [
                                      FutureBuilder<QuerySnapshot>(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('groups')
                                                .where(
                                                  FieldPath.documentId,
                                                  whereIn: groups,
                                                )
                                                .get(),
                                        builder: (context, groupSnap) {
                                          if (!groupSnap.hasData) {
                                            return const CircularProgressIndicator();
                                          }
                                          final groupDocs =
                                              groupSnap.data!.docs;
                                          if (groupDocs.isEmpty) {
                                            return Text(
                                              'No groups found.',
                                              style: GoogleFonts.openSans(),
                                            );
                                          }
                                          return Column(
                                            children:
                                                groupDocs.map((doc) {
                                                  final groupData =
                                                      doc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final groupName =
                                                      groupData['name'] ??
                                                      doc.id;
                                                  return ListTile(
                                                    leading: const Icon(
                                                      Icons.group,
                                                      color: Color(0xFF6D0EB5),
                                                    ),
                                                    title: Text(
                                                      groupName,
                                                      style:
                                                          GoogleFonts.openSans(),
                                                    ),
                                                    onTap: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pushNamed(
                                                        '/group',
                                                        arguments: doc.id,
                                                      );
                                                    },
                                                  );
                                                }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Group Invites',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<QuerySnapshot>(
                                  stream:
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('pendingInvites')
                                          .orderBy(
                                            'timestamp',
                                            descending: true,
                                          )
                                          .snapshots(),
                                  builder: (context, snap) {
                                    if (!snap.hasData)
                                      return const CircularProgressIndicator();
                                    final docs = snap.data!.docs;
                                    if (docs.isEmpty)
                                      return Text(
                                        'No pending invites.',
                                        style: GoogleFonts.openSans(),
                                      );
                                    return Column(
                                      children:
                                          docs.map((doc) {
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final groupName =
                                                data['groupName'] ?? '';
                                            final groupId =
                                                data['groupId'] ?? '';
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: ListTile(
                                                leading: const Icon(
                                                  Icons.group,
                                                  color: Color(0xFF6D0EB5),
                                                ),
                                                title: Text(
                                                  'Group: $groupName',
                                                  style:
                                                      GoogleFonts.montserrat(),
                                                ),
                                                subtitle: Text(
                                                  'Invited to join',
                                                  style: GoogleFonts.openSans(),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.check,
                                                        color: Colors.green,
                                                      ),
                                                      onPressed:
                                                          () => acceptInvite(
                                                            doc.id,
                                                            groupId,
                                                            groupName,
                                                          ),
                                                      tooltip: 'Accept',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed:
                                                          () => rejectInvite(
                                                            doc.id,
                                                          ),
                                                      tooltip: 'Reject',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D0EB5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 32,
                              ),
                              elevation: 3,
                            ),
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
