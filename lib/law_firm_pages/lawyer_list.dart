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
        backgroundColor: Colors.black,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'My Lawyers',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddLawyerPage(),
                ),
              );
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
                style: TextStyle(color: Colors.white70, fontSize: 16),
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
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 0.5,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFD4AF37),
                    child: Text(
                      (data['name'] ?? 'L')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${data['email'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Specialization: ${data['specialization'] ?? 'General'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    color: Colors.grey[800],
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          // Add edit functionality here
                        },
                      ),
                      PopupMenuItem(
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        onTap: () {
                          // Add delete functionality here
                        },
                      ),
                    ],
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
