import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaseDetailsPage extends StatefulWidget {
  final Map<String, dynamic> caseData;
  final String docId;

  const CaseDetailsPage(
      {super.key, required this.caseData, required this.docId});

  @override
  State<CaseDetailsPage> createState() => _CaseDetailsPageState();
}

class _CaseDetailsPageState extends State<CaseDetailsPage> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.caseData['status'] ?? 'Pending';
  }

  Future<void> _updateCaseStatus(String status) async {
    setState(() {
      _status = status; // immediate UI update
    });

    final bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(widget.docId);
    final lawyerId = widget.caseData['lawyerId'] as String?;

    try {
      // 1️⃣ Update booking status
      await bookingRef.update({'status': status});

      // 2️⃣ Update lawyer stats directly in Firestore
      if (lawyerId != null && lawyerId.isNotEmpty) {
        final lawyerRef =
            FirebaseFirestore.instance.collection('lawyers').doc(lawyerId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(lawyerRef);
          if (!snapshot.exists) return;

          final data = snapshot.data()!;
          int totalCases = (data['totalCases'] ?? 0) + 1;
          int wonCases = data['wonCases'] ?? 0;
          int lostCases = data['lostCases'] ?? 0;

          if (status == 'Won') {
            wonCases += 1;
          } else if (status == 'Lost') {
            lostCases += 1;
          }

          transaction.update(lawyerRef, {
            'totalCases': totalCases,
            'wonCases': wonCases,
            'lostCases': lostCases,
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Case status updated successfully!')),
      );
    } catch (e) {
      // revert UI if error
      setState(() {
        _status = widget.caseData['status'] ?? 'Pending';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Case Details',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              widget.caseData['description'] ?? 'No Description',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Client: ${widget.caseData['clientName'] ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Specialization: ${widget.caseData['specialization'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${widget.caseData['date'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _status == 'Won'
                        ? Colors.green
                        : _status == 'Lost'
                            ? Colors.red
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _status == 'Won' ? null : () => _updateCaseStatus('Won'),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark Won'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _status == 'Lost'
                      ? null
                      : () => _updateCaseStatus('Lost'),
                  icon: const Icon(Icons.close),
                  label: const Text('Mark Lost'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
