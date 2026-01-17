import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ease/clientPages/ChatWithLawyerPage.dart';

class RecentMessagesPage extends StatelessWidget {
  const RecentMessagesPage({super.key});

  Future<Map<String, String>> _getOtherUserInfo(String otherUid) async {
    try {
      // Try to get lawyer info first
      final lawyerDoc = await FirebaseFirestore.instance
          .collection('lawyers')
          .doc(otherUid)
          .get();

      if (lawyerDoc.exists) {
        final data = lawyerDoc.data();
        return {
          'name': data?['name'] ?? 'Lawyer',
          'type': 'Lawyer',
          'specialization': data?['specialization'] ?? '',
        };
      }

      // Try to get client info
      final clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(otherUid)
          .get();

      if (clientDoc.exists) {
        final data = clientDoc.data();
        return {
          'name': data?['name'] ?? 'Client',
          'type': 'Client',
          'specialization': '',
        };
      }

      return {
        'name': 'User',
        'type': 'User',
        'specialization': '',
      };
    } catch (e) {
      return {
        'name': 'User',
        'type': 'User',
        'specialization': '',
      };
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.person_off, color: Colors.white38, size: 64),
              SizedBox(height: 16),
              Text(
                'Not signed in',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Please log in to view your messages',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: const [
                  Icon(Icons.chat_bubble, color: Color(0xFFd4af37), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Recent Messages',
                    style: TextStyle(
                      color: Color(0xFFd4af37),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUid)
                  .orderBy('lastMessageAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFd4af37),
                    ),
                  );
                }

                final chats = snapshot.data?.docs ?? [];

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white24, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation with a lawyer',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final chatData = chat.data() as Map<String, dynamic>;
                    final participantsRaw = chatData['participants'];

                    // Ensure participants is List<String>
                    final participants = <String>[];
                    if (participantsRaw is List) {
                      for (var p in participantsRaw) {
                        if (p is String) participants.add(p);
                      }
                    }

                    // Get the other participant
                    final otherUid = participants.firstWhere(
                      (uid) => uid != currentUid,
                      orElse: () => '',
                    );

                    if (otherUid.isEmpty) return const SizedBox();

                    final lastMessage = chatData['lastMessage'] ?? '';
                    final timestamp = chatData['lastMessageAt'] != null
                        ? (chatData['lastMessageAt'] as Timestamp).toDate()
                        : DateTime.now();
                    final formattedTime = _formatTimestamp(timestamp);

                    // Use stored names from chat metadata if available
                    final storedLawyerName = chatData['lawyerName'];
                    final storedClientName = chatData['clientName'];

                    return FutureBuilder<Map<String, String>>(
                      future: _getOtherUserInfo(otherUid),
                      builder: (context, userSnapshot) {
                        final userName = userSnapshot.data?['name'] ?? 'User';
                        final userType = userSnapshot.data?['type'] ?? 'User';
                        final specialization =
                            userSnapshot.data?['specialization'] ?? '';

                        // Use stored name if available, otherwise use fetched name
                        String displayName = userName;
                        if (storedLawyerName != null && userType == 'Lawyer') {
                          displayName = storedLawyerName;
                        } else if (storedClientName != null &&
                            userType == 'Client') {
                          displayName = storedClientName;
                        }

                        final bool hasUnread =
                            chatData['unreadCount'] != null &&
                                (chatData['unreadCount'] as num) > 0;

                        return Card(
                          color: hasUnread
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[900],
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: hasUnread ? 4 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: hasUnread
                                ? const BorderSide(
                                    color: Color(0xFFd4af37), width: 1)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFd4af37),
                                  radius: 28,
                                  child: Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (specialization.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFd4af37)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      specialization,
                                      style: const TextStyle(
                                        color: Color(0xFFd4af37),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                lastMessage.isEmpty
                                    ? 'No messages yet'
                                    : lastMessage,
                                style: TextStyle(
                                  color: hasUnread
                                      ? Colors.white70
                                      : Colors.white54,
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: hasUnread
                                        ? const Color(0xFFd4af37)
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFd4af37),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${chatData['unreadCount']}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              String chatId = chat.id;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IndividualChatPage(
                                    chatId: chatId,
                                    lawyerUid: otherUid,
                                    lawyerName: displayName,
                                    chatType: userType,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
