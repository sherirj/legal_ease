import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:legal_ease/lawyerPages/case_details.dart';

class FirmBookingsPage extends StatefulWidget {
  const FirmBookingsPage({super.key});

  @override
  State<FirmBookingsPage> createState() => _FirmBookingsPageState();
}

class _FirmBookingsPageState extends State<FirmBookingsPage> {
  String _selectedStatus = 'All';
  String _sortBy = 'newest'; // newest, oldest, date
  final List<String> _statuses = ['All', 'Pending', 'Accepted', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

    final firmId = user.uid;

    // Only filter by firmId - all other filtering/sorting done client-side
    final stream = FirebaseFirestore.instance
        .collection('bookings')
        .where('firmId', isEqualTo: firmId)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E1E1E),
        centerTitle: true,
        title: const Text(
          'Firm Bookings',
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

          // Bookings List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
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
                      'No bookings yet',
                      style: TextStyle(color: Colors.white70),
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
                      'No bookings found for this status.',
                      style: TextStyle(color: Colors.white70),
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
                    final status = data['status'] ?? 'Pending';

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

                    Color statusColor;
                    switch (status) {
                      case 'Accepted':
                        statusColor = Colors.green;
                        break;
                      case 'Rejected':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.orange;
                    }

                    return Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.assignment_outlined,
                          color: Color(0xFFD4AF37),
                        ),
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
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showBookingActions(context, doc.id, data),
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

  // ================= POPUP =================

  void _showBookingActions(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final bool canRespond = status == 'Pending';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['description'] ?? 'Case Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              /// View Details
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseDetailsPage(
                          caseData: data,
                          docId: docId,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              if (canRespond) ...[
                /// Accept
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept Case'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _acceptCase(context, docId);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                /// Reject
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject Case'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showRejectDialog(context, docId);
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Case already $status',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= ACCEPT =================

  Future<void> _acceptCase(BuildContext context, String docId) async {
    final lawyerId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({
        'status': 'Accepted',
        'lawyerId': lawyerId,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Case accepted & assigned'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= REJECT =================

  Future<void> _showRejectDialog(BuildContext context, String docId) async {
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: const Text(
            'Reject Case',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Reason for rejection',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
                Navigator.pop(ctx);
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(docId)
                    .update({
                  'status': 'Rejected',
                  'rejectionReason': reasonCtrl.text.trim(),
                  'respondedAt': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✗ Case rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
