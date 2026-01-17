import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ease/law_firm_pages/add_lawyer.dart';

class LawyersListPage extends StatelessWidget {
  const LawyersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.brown,
        body: Center(
          child: Text(
            '⚠️ Not logged in',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final String lawFirmId = currentUser.uid;

    final Stream<QuerySnapshot> lawyersStream = FirebaseFirestore.instance
        .collection('lawyers')
        .where('lawFirmId', isEqualTo: lawFirmId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1A17),
      appBar: AppBar(
        title: const Text(
          'My Lawyers',
          style: TextStyle(color: Color(0xFFD4AF37)),
        ),
        backgroundColor: const Color(0xFF3E2723),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddLawyerPage()));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: lawyersStream,
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No lawyers added yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final lawyers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lawyers.length,
            itemBuilder: (context, index) {
              final doc = lawyers[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: const Color(0xFF4E342E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Email: ${data['email'] ?? 'N/A'}\nRole: Lawyer',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
