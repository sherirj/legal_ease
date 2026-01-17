import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> submitRating(
    String caseId, String lawyerId, double rating, String feedback) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  // 1️⃣ Update case document
  await db.collection('cases').doc(caseId).update({
    'ratingGiven': true,
    'rating': rating,
    'feedback': feedback,
  });

  // 2️⃣ Update lawyer statistics
  DocumentReference lawyerRef = db.collection('lawyers').doc(lawyerId);

  await db.runTransaction((transaction) async {
    DocumentSnapshot snap = await transaction.get(lawyerRef);

    double ratingSum = snap['ratingSum'] ?? 0;
    int totalRatings = snap['totalRatings'] ?? 0;

    ratingSum += rating;
    totalRatings += 1;

    transaction.update(lawyerRef, {
      'ratingSum': ratingSum,
      'totalRatings': totalRatings,
      'avgRating': ratingSum / totalRatings
    });
  });
}
