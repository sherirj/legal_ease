import 'package:cloud_firestore/cloud_firestore.dart';

class CaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Close a case and automatically add success record if successful
  Future<void> closeCase({
    required String caseId,
    required String lawyerId,
    required String clientName,
    required String verdict, // "won" or "lost"
    String notes = '',
  }) async {
    final caseRef = _db.collection('cases').doc(caseId);

    // 1️⃣ Update the case status to 'closed' and save verdict
    await caseRef.update({
      'status': 'closed',
      'verdict': verdict,
      'closedAt': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Only add success record if verdict is 'won'
    if (verdict.toLowerCase() == 'won') {
      final successRef =
          _db.collection('users').doc(lawyerId).collection('success_records');

      await successRef.add({
        'caseId': caseId,
        'title': (await caseRef.get()).data()?['title'] ?? '',
        'clientName': clientName,
        'verdict': verdict,
        'date': FieldValue.serverTimestamp(),
        'notes': notes,
      });
    }
  }

  /// Fetch lawyer's success records (optional for dashboard)
  Stream<QuerySnapshot> getSuccessRecords(String lawyerId) {
    return _db
        .collection('users')
        .doc(lawyerId)
        .collection('success_records')
        .orderBy('date', descending: true)
        .snapshots();
  }
}
