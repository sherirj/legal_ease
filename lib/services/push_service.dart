import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushService {
  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> initAndSaveToken() async {
    final permission = await _messaging.requestPermission();
    // you can check permission.status if needed

    final token = await _messaging.getToken();
    final uid = _auth.currentUser?.uid;
    if (uid != null && token != null) {
      await _firestore.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((message) {
      // handle foreground messages if desired
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // handle when user taps notification
    });
  }
}
