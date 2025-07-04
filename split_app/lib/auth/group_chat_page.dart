import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  const GroupChatPage({super.key, required this.groupId});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _messageController = TextEditingController();
  bool sending = false;

  Future<void> sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;
    setState(() => sending = true);
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final username = userDoc['username'] ?? user.email ?? user.uid;
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('chats')
        .add({
          'senderId': user.uid,
          'senderName': username,
          'text': _messageController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
    _messageController.clear();
    setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Chat',
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
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('chats')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet.',
                            style: GoogleFonts.openSans(),
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final isMe =
                              data['senderId'] ==
                              FirebaseAuth.instance.currentUser?.uid;
                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? const Color(0xFF4059F1)
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['senderName'] ?? '',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isMe
                                              ? Colors.white
                                              : const Color(0xFF4059F1),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['text'] ?? '',
                                    style: GoogleFonts.openSans(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['timestamp'] != null &&
                                            data['timestamp'] is Timestamp
                                        ? DateFormat('hh:mm a').format(
                                          (data['timestamp'] as Timestamp)
                                              .toDate(),
                                        )
                                        : '',
                                    style: GoogleFonts.openSans(
                                      color:
                                          isMe
                                              ? Colors.white70
                                              : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.openSans(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        sending
                            ? const CircularProgressIndicator()
                            : IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Color(0xFF4059F1),
                              ),
                              onPressed: sendMessage,
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
