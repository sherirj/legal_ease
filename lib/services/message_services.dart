import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference chatsRef() => _firestore.collection('chats');

  /// Create or ensure chat doc exists (optional)
  Future<void> ensureChat(String chatId, Map<String, dynamic> meta) async {
    final chatDoc = chatsRef().doc(chatId);
    final snap = await chatDoc.get();
    if (!snap.exists) {
      await chatDoc.set({
        'createdAt': FieldValue.serverTimestamp(),
        ...meta,
      });
    }
  }

  /// Send message with delivered/seen metadata placeholder
  Future<DocumentReference> sendMessage({
    required String chatId,
    required String text,
    required String role,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    final msg = {
      'text': text,
      'role': role,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser?.uid,
      'deliveredAt': null, // will be set by receiver client or function
      'seenAt': null,
    };

    final ref = await chatsRef().doc(chatId).collection('messages').add(msg);

    // update chat last message metadata
    await chatsRef().doc(chatId).set({
      'lastMessage': text ?? (attachmentName ?? 'Attachment'),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageBy': _auth.currentUser?.uid,
    }, SetOptions(merge: true));

    return ref;
  }

  /// Stream messages with pagination support (limit)
  Stream<QuerySnapshot> messagesStream(String chatId, {int limit = 25}) {
    return chatsRef()
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Load older messages (cursor)
  Future<List<QueryDocumentSnapshot>> loadMoreMessages({
    required String chatId,
    required DocumentSnapshot lastDoc,
    int limit = 25,
  }) async {
    final snap = await chatsRef()
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
    return snap.docs;
  }

  /// Mark message delivered (called by client that receives message or cloud function)
  Future<void> markDelivered(String chatId, String messageId) async {
    await chatsRef()
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'deliveredAt': FieldValue.serverTimestamp()});
  }

  /// Mark message seen (when user opens chat)
  Future<void> markSeen(String chatId, String messageId) async {
    await chatsRef()
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'seenAt': FieldValue.serverTimestamp()});
  }

  /// Typing indicator: set typing status for current user
  Future<void> setTyping(String chatId, bool isTyping) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await chatsRef().doc(chatId).collection('meta').doc('typing').set({
      uid: {
        'isTyping': isTyping,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }

  /// Presence: update user's online status in users collection
  Future<void> setPresence(bool online) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'online': online,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Register delivered/seen in bulk when opening chat
  Future<void> markAllDeliveredOrSeen({
    required String chatId,
    bool markSeen = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final query = await chatsRef()
        .doc(chatId)
        .collection('messages')
        .where('userId', isNotEqualTo: uid)
        .where(markSeen ? 'seenAt' : 'deliveredAt', isNull: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        markSeen ? 'seenAt' : 'deliveredAt': FieldValue.serverTimestamp()
      });
    }
    await batch.commit();
  }
}
