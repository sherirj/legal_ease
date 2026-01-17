import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestPendingScreen extends StatefulWidget {
  const RequestPendingScreen({super.key});

  @override
  State<RequestPendingScreen> createState() => _RequestPendingScreenState();
}

class _RequestPendingScreenState extends State<RequestPendingScreen> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = _firebaseAuth.currentUser?.uid ?? '';
    _checkRequestStatus();

    print('Pending Screen initialized for user: $_userId');
  }

  // 🔹 Check request status in real-time
  Future<void> _checkRequestStatus() async {
    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('firm_signup_requests')
          .doc(_userId)
          .get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final status = doc.data()?['status'] ?? 'pending';

      // If approved, navigate to dashboard
      if (status == 'approved') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/firm-dashboard');
        }
      }
      // If rejected, show rejection screen
      else if (status == 'rejected') {
        if (mounted) {
          final rejectionReason =
              doc.data()?['rejectionReason'] ?? 'Unknown reason';
          _showRejectionDialog(rejectionReason);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error checking status: $e');
      setState(() => _isLoading = false);
    }
  }

  // 🔹 Listen to real-time changes
  Stream<DocumentSnapshot> _getRequestStream() {
    return _firestore
        .collection('firm_signup_requests')
        .doc(_userId)
        .snapshots();
  }

  void _showRejectionDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e1e),
        title: const Text(
          '❌ Request Rejected',
          style: TextStyle(color: Colors.red, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Your law firm registration request was rejected.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900]?.withOpacity(0.3),
                border: Border.all(color: Colors.red[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason:',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please fix the issues and reapply.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to login
            },
            child: const Text(
              'Go Back',
              style: TextStyle(color: Color(0xFFd4af37)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFd4af37),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _getRequestStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFd4af37),
                    ),
                  );
                }

                final doc = snapshot.data!;
                final status = doc['status'] ?? 'pending';
                final firmName = doc['firmName'] ?? 'Your Firm';
                final createdAt = doc['createdAt'];

                // Check if approved
                if (status == 'approved') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacementNamed(context, '/firm-dashboard');
                  });
                }

                // Check if rejected
                if (status == 'rejected') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showRejectionDialog(doc['rejectionReason'] ?? 'Unknown');
                  });
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),

                        // 🔹 PENDING ICON
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFd4af37).withOpacity(0.3),
                                const Color(0xFFd4af37).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.hourglass_bottom,
                              size: 60,
                              color: Color(0xFFd4af37),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 🔹 TITLE
                        const Text(
                          'Registration Pending',
                          style: TextStyle(
                            color: Color(0xFFd4af37),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 SUBTITLE
                        Text(
                          'Your law firm "$firmName" registration is under review.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 🔹 STATUS CARD
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border.all(
                              color: const Color(0xFFd4af37).withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Status indicator
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.yellow[700],
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.yellow[700]!
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Status: Pending Review',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Timeline
                              _buildTimelineItem(
                                title: 'Application Submitted',
                                subtitle: _formatDate(createdAt),
                                completed: true,
                              ),
                              const SizedBox(height: 12),
                              _buildTimelineItem(
                                title: 'Admin Review',
                                subtitle: 'In Progress...',
                                completed: false,
                              ),
                              const SizedBox(height: 12),
                              _buildTimelineItem(
                                title: 'Approval',
                                subtitle: 'Pending',
                                completed: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 🔹 INFO BOX
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFd4af37).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFFd4af37).withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📋 What happens next?',
                                style: TextStyle(
                                  color: Color(0xFFd4af37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoPoint(
                                'Admin will verify your firm details',
                              ),
                              _buildInfoPoint(
                                'Validate NTN and Bar Council numbers',
                              ),
                              _buildInfoPoint(
                                'You will receive an email notification',
                              ),
                              _buildInfoPoint(
                                'Access dashboard once approved',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 🔹 BUTTONS
                        ElevatedButton.icon(
                          onPressed: _checkRequestStatus,
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text(
                            'Check Status',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd4af37),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () async {
                            await _firebaseAuth.signOut();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          icon: const Icon(Icons.logout,
                              color: Color(0xFFd4af37)),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFd4af37),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(
                              color: Color(0xFFd4af37),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool completed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? const Color(0xFFd4af37) : Colors.grey[700],
              ),
              child: Center(
                child: completed
                    ? const Icon(Icons.check, size: 14, color: Colors.black)
                    : const SizedBox(),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✓ ',
            style: TextStyle(color: Color(0xFFd4af37)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'N/A';
    }
  }
}
