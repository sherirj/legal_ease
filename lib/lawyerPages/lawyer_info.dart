import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerInformationPage extends StatelessWidget {
  final String lawyerId;
  const LawyerInformationPage({super.key, required this.lawyerId});

  @override
  Widget build(BuildContext context) {
    final DocumentReference lawyerRef =
        FirebaseFirestore.instance.collection('lawyers').doc(lawyerId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Lawyer Information',
          style: TextStyle(color: Color(0xFFD4AF37)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: lawyerRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Lawyer not found',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final String name = data['name'] ?? 'Unnamed';
          final String specialization = data['specialization'] ?? 'N/A';
          final String experience = data['experience'] ?? 'N/A';
          final int totalCases = data['totalCases'] ?? 0;
          final int wonCases = data['wonCases'] ?? 0;
          final int lostCases = data['lostCases'] ?? 0;

          Widget buildBadge(String label, int count, Color color) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: $name',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                Text('Specialization: $specialization',
                    style: const TextStyle(color: Colors.white70)),
                Text('Experience: $experience years',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildBadge('Total Cases', totalCases, Colors.white),
                    buildBadge('Cases Won', wonCases, Colors.greenAccent),
                    buildBadge('Cases Lost', lostCases, Colors.redAccent),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
