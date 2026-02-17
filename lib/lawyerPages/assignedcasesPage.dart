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

    // Only filter by lawyerId, all sorting and filtering will be done client-side
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('lawyerId', isEqualTo: lawyerId);

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
                      'No assigned cases yet.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                var bookings = snapshot.data!.docs;

                // Client-side filtering by status
                if (_selectedStatus != 'All') {
                  bookings = bookings
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['status']
                              .toString() ==
                          _selectedStatus)
                      .toList();
                }

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'No cases found for this status.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                // Client-side sorting
                if (_sortBy == 'newest') {
                  bookings.sort((a, b) {
                    final dateA = (a.data()
                        as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final dateB = (b.data()
                        as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    return (dateB?.toDate() ?? DateTime(1970))
                        .compareTo(dateA?.toDate() ?? DateTime(1970));
                  });
                } else if (_sortBy == 'oldest') {
                  bookings.sort((a, b) {
                    final dateA = (a.data()
                        as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final dateB = (b.data()
                        as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    return (dateA?.toDate() ?? DateTime(1970))
                        .compareTo(dateB?.toDate() ?? DateTime(1970));
                  });
                } else if (_sortBy == 'date') {
                  bookings.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    DateTime dateA = DateTime(1970);
                    DateTime dateB = DateTime(1970);

                    final rawDateA = aData['date'];
                    if (rawDateA is Timestamp) {
                      dateA = rawDateA.toDate();
                    } else if (rawDateA is String) {
                      try {
                        dateA = DateTime.parse(rawDateA);
                      } catch (e) {
                        dateA = DateTime(1970);
                      }
                    }

                    final rawDateB = bData['date'];
                    if (rawDateB is Timestamp) {
                      dateB = rawDateB.toDate();
                    } else if (rawDateB is String) {
                      try {
                        dateB = DateTime.parse(rawDateB);
                      } catch (e) {
                        dateB = DateTime(1970);
                      }
                    }

                    return dateA.compareTo(dateB);
                  });
                }

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
                      case 'Accepted':
                        statusColor = Colors.blue;
                        break;
                      case 'Rejected':
                        statusColor = Colors.redAccent;
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          _showCaseActions(context, doc.id, data);
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
        backgroundColor:
            isSelected ? const Color(0xFFD4AF37) : Colors.grey[800],
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

  void _showCaseActions(
      BuildContext context, String docId, Map<String, dynamic> caseData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Case Title
              Text(
                caseData['description'] ?? 'Case Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // View Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseDetailsPage(
                          caseData: caseData,
                          docId: docId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text(
                    'View Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Accept Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _acceptCase(context, docId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Accept Case',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reject Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showRejectDialog(context, docId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text(
                    'Reject Case',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptCase(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({
        'status': 'accept',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Case accepted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept case: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(BuildContext context, String docId) async {
    final TextEditingController reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text(
                'Reject Case',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide a reason for rejection:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();

                try {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(docId)
                      .update({
                    'status': 'rejected',
                    'respondedAt': FieldValue.serverTimestamp(),
                    'rejectionReason': reasonCtrl.text.trim(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✗ Case rejected'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject case: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
