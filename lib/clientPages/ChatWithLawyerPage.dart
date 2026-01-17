import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatWithLawyerPage extends StatefulWidget {
  const ChatWithLawyerPage({super.key});

  @override
  State<ChatWithLawyerPage> createState() => _ChatWithLawyerPageState();
}

class _ChatWithLawyerPageState extends State<ChatWithLawyerPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Chat with Lawyers & Firms',
          style:
              TextStyle(color: Color(0xFFd4af37), fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFd4af37),
          indicatorWeight: 3,
          labelColor: const Color(0xFFd4af37),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Lawyers'),
            Tab(text: 'Law Firms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatList(isLawFirm: false),
          _buildChatList(isLawFirm: true),
        ],
      ),
    );
  }

  Widget _buildChatList({required bool isLawFirm}) {
    final bookingsStream = _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: currentUid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFd4af37),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isLawFirm);
        }

        // Filter bookings based on whether they're law firms or individual lawyers
        final allBookings = snapshot.data!.docs;
        final filteredBookings = allBookings.where((doc) {
          final booking = doc.data() as Map<String, dynamic>;
          final firmName = booking['firmName'];
          final hasLawFirm = firmName != null && firmName.toString().isNotEmpty;
          return isLawFirm ? hasLawFirm : !hasLawFirm;
        }).toList();

        if (filteredBookings.isEmpty) {
          return _buildEmptyState(isLawFirm);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            final booking =
                filteredBookings[index].data() as Map<String, dynamic>;

            // Get IDs
            final lawyerId = booking['lawyerId'];
            final firmId = booking['firmId']; // For law firms

            // Get names
            final lawyerName = booking['lawyerName'] ?? 'Professional';
            final firmName = booking['firmName'];

            final specialization = booking['specialization'] ?? '';
            final status = booking['status'] ?? 'Pending';

            // Determine the display name, type, and chatPartnerId
            String displayName;
            String displayType;
            String chatPartnerId; // The UID to chat with

            if (isLawFirm) {
              displayName = firmName ?? 'Law Firm';
              displayType = 'Law Firm';
              // IMPORTANT: Use firmId for law firm chats
              chatPartnerId = firmId ?? lawyerId;
            } else {
              displayName = lawyerName;
              displayType = 'Lawyer';
              chatPartnerId = lawyerId;
            }

            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFFd4af37).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFd4af37),
                  radius: 28,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayType,
                      style: const TextStyle(
                        color: Color(0xFFd4af37),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLawFirm && lawyerName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contact: $lawyerName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (specialization.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        specialization,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status == 'Confirmed'
                                ? Colors.green[300]
                                : Colors.orange[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: status == 'Confirmed'
                                ? Colors.green[300]
                                : Colors.orange[300],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFd4af37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Color(0xFFd4af37),
                    size: 24,
                  ),
                ),
                onTap: () async {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFd4af37),
                      ),
                    ),
                  );

                  try {
                    print('=== CHAT CREATION DEBUG ===');
                    print('Current User (Client): $currentUid');
                    print('Chat Partner ID: $chatPartnerId');
                    print('Display Name: $displayName');
                    print('Display Type: $displayType');
                    print('Is Law Firm: $isLawFirm');

                    // Check if chat exists
                    final chatQuery = await _firestore
                        .collection('chats')
                        .where('participants', arrayContains: currentUid)
                        .get();

                    String chatId = '';
                    for (var doc in chatQuery.docs) {
                      final participants =
                          (doc.data()['participants'] as List<dynamic>);
                      if (participants.contains(chatPartnerId)) {
                        chatId = doc.id;
                        print('Found existing chat: $chatId');
                        break;
                      }
                    }

                    if (chatId.isEmpty) {
                      print('Creating new chat...');
                      // Create new chat
                      final chatDoc = await _firestore.collection('chats').add({
                        'participants': [currentUid, chatPartnerId],
                        'lastMessage': '',
                        'lastMessageAt': FieldValue.serverTimestamp(),
                        'lawyerName': lawyerName,
                        'firmName': firmName ?? '',
                        'displayName': displayName,
                        'chatType': displayType,
                        'clientName': booking['clientName'] ?? 'Client',
                        'unreadCount': 0,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      chatId = chatDoc.id;
                      print('Created new chat: $chatId');
                      print(
                          'Chat participants: [client: $currentUid, partner: $chatPartnerId]');
                    }

                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    // Open chat page
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IndividualChatPage(
                            chatId: chatId,
                            lawyerUid: chatPartnerId, // Use chatPartnerId
                            lawyerName: displayName,
                            chatType: displayType,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    print('ERROR creating/opening chat: $e');
                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to open chat: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isLawFirm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLawFirm ? Icons.business : Icons.person,
            color: Colors.white38,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            isLawFirm ? 'No booked law firms yet' : 'No booked lawyers yet',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isLawFirm
                ? 'Book a law firm to start chatting'
                : 'Book a lawyer to start chatting',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Individual chat page for messages
class IndividualChatPage extends StatefulWidget {
  final String chatId;
  final String lawyerUid;
  final String lawyerName;
  final String chatType;

  const IndividualChatPage({
    super.key,
    required this.chatId,
    required this.lawyerUid,
    required this.lawyerName,
    required this.chatType,
  });

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String currentUid;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;

    print('=== CHAT PAGE OPENED ===');
    print('Chat ID: ${widget.chatId}');
    print('Current User: $currentUid');
    print('Partner UID: ${widget.lawyerUid}');
    print('Partner Name: ${widget.lawyerName}');
    print('Chat Type: ${widget.chatType}');

    // Auto-scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      print('=== SENDING MESSAGE ===');
      print('Text: $text');
      print('Sender: $currentUid');
      print('Chat ID: ${widget.chatId}');

      final message = {
        'text': text,
        'userId': currentUid,
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': await _getCurrentUserName(),
      };

      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(message);

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      print('Message sent successfully!');
      _scrollToBottom();
    } catch (e) {
      print('ERROR sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getCurrentUserName() async {
    try {
      final userDoc =
          await _firestore.collection('clients').doc(currentUid).get();
      return userDoc.data()?['name'] ?? 'Client';
    } catch (e) {
      return 'Client';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isFirstInGroup) {
    final isUser = msg['userId'] == currentUid;
    final timestamp = msg['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: isFirstInGroup ? 12 : 4,
          bottom: 4,
          left: 12,
          right: 12,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isFirstInGroup && !isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  widget.lawyerName,
                  style: const TextStyle(
                    color: Color(0xFFd4af37),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFd4af37) : Colors.grey[850],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg['text'] ?? '',
                style: TextStyle(
                  color: isUser ? Colors.black : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFd4af37)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFd4af37),
              radius: 18,
              child: Text(
                widget.lawyerName.isNotEmpty
                    ? widget.lawyerName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lawyerName,
                    style: const TextStyle(
                      color: Color(0xFFd4af37),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.chatType,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('MESSAGES STREAM ERROR: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Color(0xFFd4af37),
                  ));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_outlined,
                            color: Colors.white24, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                print('Messages loaded: ${docs.length}');

                // Auto-scroll when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final isFirstInGroup = index == 0 ||
                        (docs[index - 1].data()
                                as Map<String, dynamic>)['userId'] !=
                            msg['userId'];
                    return _buildMessageBubble(msg, isFirstInGroup);
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFd4af37),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
