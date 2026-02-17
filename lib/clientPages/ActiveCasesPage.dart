import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'case_details.dart';

class ActiveCasesPage extends StatefulWidget {
  const ActiveCasesPage({super.key});

  @override
  State<ActiveCasesPage> createState() => _ActiveCasesPageState();
}

class _ActiveCasesPageState extends State<ActiveCasesPage> {
  User? _currentUser;
  bool _loadingUser = true;
  final Set<String> _promptedCases = {};
  String _selectedFilter = 'All'; // All, Pending, Accepted, Rejected

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
      });
    });
  }

  // --- Rating helpers ---------------------------------------------------

  Future<bool> _ratingExists(String caseId, String clientId) async {
    final snap = await FirebaseFirestore.instance
        .collection('ratings')
        .where('caseId', isEqualTo: caseId)
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _showRatingDialog({
    required BuildContext context,
    required String caseId,
    required String lawyerId,
    required String lawyerName,
    required String clientId,
    required String clientName,
  }) async {
    int selectedStars = 5;
    final TextEditingController feedbackCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: Row(
            children: const [
              Icon(Icons.rate_review, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text('Rate your lawyer', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              StatefulBuilder(builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => selectedStars = idx),
                      icon: Icon(
                        idx <= selectedStars ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFD700),
                      ),
                    );
                  }),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Leave feedback (optional)',
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
              onPressed: () => Navigator.of(ctx).pop(false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (submitted != true) return;

    final ratingsRef = FirebaseFirestore.instance.collection('ratings').doc();
    final lawyerRef =
        FirebaseFirestore.instance.collection('lawyers').doc(lawyerId);

    final ratingData = {
      'caseId': caseId,
      'clientId': clientId,
      'clientName': clientName,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'rating': selectedStars,
      'feedback': feedbackCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // Write rating
      await ratingsRef.set(ratingData);

      // recompute aggregates
      final rSnap = await FirebaseFirestore.instance
          .collection('ratings')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      int sum = 0;
      for (var d in rSnap.docs) {
        final r = d.data()['rating'];
        sum += (r is int) ? r : int.tryParse(r.toString()) ?? 0;
      }
      final count = rSnap.docs.length;
      final avg = count > 0 ? (sum / count) : 0.0;

      await lawyerRef.set({
        'avgRating': avg,
        'reviewCount': count,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your rating!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $e')),
      );
    }
  }

  Future<void> _maybeShowRatingIfNeeded(BuildContext context,
      Map<String, dynamic> caseData, String caseId) async {
    final status = caseData['status'] as String? ?? 'Pending';
    // Only show rating for Won or Lost cases
    if (!(status == 'Won' || status == 'Lost')) return;

    final clientId = caseData['clientId'] as String?;
    final lawyerId = caseData['lawyerId'] as String?;
    final lawyerName = caseData['lawyerName'] as String? ?? 'Lawyer';
    final clientName = caseData['clientName'] as String? ?? '';

    if (clientId == null || lawyerId == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != clientId) return;

    if (_promptedCases.contains(caseId)) return;

    final exists = await _ratingExists(caseId, clientId);
    if (!exists) {
      _promptedCases.add(caseId);
      await _showRatingDialog(
        context: context,
        caseId: caseId,
        lawyerId: lawyerId,
        lawyerName: lawyerName,
        clientId: clientId,
        clientName: clientName,
      );
    }
  }

  // --- end rating helpers ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            '⚠️ Not logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    Query<Map<String, dynamic>> casesQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('clientId', isEqualTo: _currentUser!.uid);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'My Cases',
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final filters = [
                        'All',
                        'Pending',
                        'Accepted',
                        'Rejected'
                      ];
                      final filter = filters[index];
                      final isSelected = _selectedFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
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
              ],
            ),
          ),
          // Cases List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: casesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '⚠️ Error loading cases: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No cases found.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                var cases = snapshot.data!.docs;

                // Client-side filtering by status
                if (_selectedFilter != 'All') {
                  cases = cases
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['status']
                              .toString()
                              .toLowerCase() ==
                          _selectedFilter.toLowerCase())
                      .toList();
                }

                if (cases.isEmpty) {
                  return const Center(
                    child: Text(
                      'No cases found for this status.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                // Sort by createdAt descending (newest first)
                cases.sort((a, b) {
                  final dateA = (a.data() as Map<String, dynamic>)['createdAt']
                      as Timestamp?;
                  final dateB = (b.data() as Map<String, dynamic>)['createdAt']
                      as Timestamp?;
                  return (dateB?.toDate() ?? DateTime(1970))
                      .compareTo(dateA?.toDate() ?? DateTime(1970));
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cases.length,
                  itemBuilder: (context, index) {
                    final caseDoc = cases[index];
                    final caseData = caseDoc.data() as Map<String, dynamic>;
                    final caseId = caseDoc.id;

                    // Rating prompt removed - will show only when client clicks case details

                    // Format dates
                    String submittedDate = 'N/A';
                    final rawSubmitDate = caseData['createdAt'];
                    if (rawSubmitDate is Timestamp) {
                      submittedDate = DateFormat('MMM d, yyyy')
                          .format(rawSubmitDate.toDate());
                    }

                    String respondedDate = '';
                    final rawRespondDate = caseData['respondedAt'];
                    if (rawRespondDate is Timestamp) {
                      respondedDate = DateFormat('MMM d, yyyy - h:mm a')
                          .format(rawRespondDate.toDate());
                    }

                    // Status styling
                    Color statusColor;
                    IconData statusIcon;
                    String statusText;

                    switch ((caseData['status'] ?? 'pending')
                        .toString()
                        .toLowerCase()) {
                      case 'accepted':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        statusText = 'ACCEPTED';
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        statusText = 'REJECTED';
                        break;
                      default:
                        statusColor = Colors.orange;
                        statusIcon = Icons.hourglass_empty;
                        statusText = 'PENDING';
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientCaseDetailsPage(
                              caseId: caseId,
                              caseData: caseData,
                            ),
                          ),
                        ).then((_) {
                          // Show rating prompt after returning from case details
                          _maybeShowRatingIfNeeded(context, caseData, caseId);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1A1A), Color(0xFF262626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFFFD700), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Status
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.gavel,
                                      color: Color(0xFFFFD700), size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          caseData['event'] ??
                                              caseData['description'] ??
                                              'Case',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lawyer: ${caseData['lawyerName'] ?? 'Not Assigned'}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Dates
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Submitted',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          submittedDate,
                                          style: const TextStyle(
                                            color: Color(0xFFD4AF37),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (respondedDate.isNotEmpty)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Responded',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            respondedDate,
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              // Rejection Reason
                              if ((caseData['status'] ?? '')
                                          .toString()
                                          .toLowerCase() ==
                                      'rejected' &&
                                  (caseData['rejectionReason'] ?? '')
                                      .isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Rejection Reason:',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            caseData['rejectionReason'] ??
                                                'No reason provided',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
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
}
