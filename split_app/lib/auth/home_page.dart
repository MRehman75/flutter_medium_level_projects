import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

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
        title: Text(
          'Home',
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.of(context).pushNamed('/profile');
              } else if (value == 'groups') {
                Navigator.of(context).pushNamed('/home');
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          color: Color(0xFF4059F1),
                        ),
                        const SizedBox(width: 8),
                        Text('Profile', style: GoogleFonts.openSans()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'groups',
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: Color(0xFF6D0EB5)),
                        const SizedBox(width: 8),
                        Text('Groups', style: GoogleFonts.openSans()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Logout', style: GoogleFonts.openSans()),
                      ],
                    ),
                  ),
                ],
          ),
        ],
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
                final groupIds = List<String>.from(data['groups'] ?? []);
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: GoogleFonts.openSans(
                          fontSize: 20,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        user.email ?? "Unknown",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4059F1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 3,
                              ),
                              icon: const Icon(
                                Icons.account_circle,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Profile',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                  ).pushNamed('/profile'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D0EB5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 3,
                              ),
                              icon: const Icon(
                                Icons.group_add,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Create Group',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                  ).pushNamed('/create_group'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Your Groups',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child:
                            groupIds.isEmpty
                                ? Center(
                                  child: Text(
                                    'No groups yet.',
                                    style: GoogleFonts.openSans(fontSize: 16),
                                  ),
                                )
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
                                      return Center(
                                        child: Text(
                                          'No groups found.',
                                          style: GoogleFonts.openSans(
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    return ListView.builder(
                                      itemCount: groupDocs.length,
                                      itemBuilder: (context, index) {
                                        final groupData =
                                            groupDocs[index].data()
                                                as Map<String, dynamic>;
                                        final groupId = groupDocs[index].id;
                                        final groupName =
                                            groupData['name'] ??
                                            'Unnamed Group';
                                        return Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 4,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 0,
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(
                                                0xFF6D0EB5,
                                              ),
                                              child: Icon(
                                                Icons.group,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                              groupName,
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Tap to view details',
                                              style: GoogleFonts.openSans(),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.dashboard,
                                                    color: Color(0xFF4059F1),
                                                  ),
                                                  tooltip: 'Dashboard',
                                                  onPressed: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pushNamed(
                                                      '/group_dashboard',
                                                      arguments: groupId,
                                                    );
                                                  },
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.grey[400],
                                                ),
                                              ],
                                            ),
                                            onTap:
                                                () => Navigator.of(
                                                  context,
                                                ).pushNamed(
                                                  '/group',
                                                  arguments: groupId,
                                                ),
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
          ),
        ],
      ),
    );
  }
}
