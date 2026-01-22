import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:legal_ease/lawyerPages/case_details.dart';

class AssignedCasesPage extends StatefulWidget {
  const AssignedCasesPage({super.key});

  @override
  State<AssignedCasesPage> createState() => _AssignedCasesPageState();
}

class _AssignedCasesPageState extends State<AssignedCasesPage> {
  String _selectedStatus = 'All';
  String _sortBy = 'newest'; // newest, oldest, date
  final List<String> _statuses = ['All', 'Pending', 'Won', 'Lost'];

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            '⚠️ Not logged in',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final String lawyerId = currentUser.uid;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('lawyerId', isEqualTo: lawyerId);

    // Apply status filter
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    // Apply sorting
    if (_sortBy == 'newest') {
      query = query.orderBy('createdAt', descending: true);
    } else if (_sortBy == 'oldest') {
      query = query.orderBy('createdAt', descending: false);
    } else if (_sortBy == 'date') {
      query = query.orderBy('date', descending: false);
    }

    final Stream<QuerySnapshot> bookingsStream = query.snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E1E1E),
        centerTitle: true,
        title: const Text(
          'Assigned Cases',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter and Sort Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter
                Text(
                  'Filter by Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length,
                    itemBuilder: (context, index) {
                      final status = _statuses[index];
                      final isSelected = _selectedStatus == status;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          backgroundColor: Colors.grey[800],
                          selectedColor: const Color(0xFFD4AF37),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : Colors.grey[700]!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Sort Options
                Text(
                  'Sort by',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSortButton(
                        'Newest First',
                        'newest',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSortButton(
                        'Oldest First',
                        'oldest',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSortButton(
                        'By Date',
                        'date',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cases List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFD4AF37)),
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
                      'No assigned cases yet.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                final bookings = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final doc = bookings[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Format dates
                    String formattedDate = 'N/A';
                    final rawDate = data['date'];
                    if (rawDate is Timestamp) {
                      formattedDate =
                          DateFormat('MMM d, yyyy').format(rawDate.toDate());
                    } else if (rawDate is String) {
                      try {
                        final date = DateTime.parse(rawDate);
                        formattedDate = DateFormat('MMM d, yyyy').format(date);
                      } catch (e) {
                        formattedDate = rawDate;
                      }
                    }

                    // Status color
                    Color statusColor;
                    switch (data['status']) {
                      case 'Won':
                        statusColor = Colors.green;
                        break;
                      case 'Lost':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.orange;
                    }

                    return Card(
                      color: Colors.grey[900],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined,
                            color: Color(0xFFD4AF37)),
                        title: Text(
                          data['description'] ?? 'No Description',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Client: ${data['clientName'] ?? 'Unknown'}',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: $formattedDate',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['status'] ?? 'Pending',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaseDetailsPage(
                                caseData: data,
                                docId: doc.id,
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _sortBy = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFD4AF37)
            : Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}