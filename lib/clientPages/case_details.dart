import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientCaseDetailsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> caseData;

  const ClientCaseDetailsPage({
    super.key,
    required this.caseId,
    required this.caseData,
  });

  @override
  State<ClientCaseDetailsPage> createState() => _ClientCaseDetailsPageState();
}

class _ClientCaseDetailsPageState extends State<ClientCaseDetailsPage> {
  bool _alreadyChecked = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.caseData['status'] ?? 'Pending';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRatingPopup();
    });
  }

  // Update case status (Won/Lost)
  Future<void> _updateCaseStatus(String newStatus) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final caseRef =
        FirebaseFirestore.instance.collection('cases').doc(widget.caseId);

    try {
      await caseRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = newStatus;
      });

      // Show rating popup after case is completed
      if (newStatus == 'Won' || newStatus == 'Lost') {
        _checkForRatingPopup();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  // Show rating dialog if case is completed
  Future<void> _checkForRatingPopup() async {
    if (_alreadyChecked) return;
    _alreadyChecked = true;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_status != 'Won' && _status != 'Lost') return;

    final lawyerId = widget.caseData['lawyerId'];
    if (lawyerId == null) return;

    // Check if rating already exists
    final snap = await FirebaseFirestore.instance
        .collection('ratings')
        .where('caseId', isEqualTo: widget.caseId)
        .where('clientId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return;

    // Show rating dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int selectedStars = 5;
        final TextEditingController feedbackCtrl = TextEditingController();

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
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.of(ctx).pop();

                final ratingData = {
                 'caseId': widget.caseId,
                 'clientId': currentUser.uid,
                 'clientName': widget.caseData['clientName'] ?? '',
                 'lawyerId': lawyerId,
                 'lawyerName': widget.caseData['lawyerName'] ?? '',
                 'rating': selectedStars,
                 'feedback': feedbackCtrl.text.trim(),
                 'createdAt': Timestamp.now(),  // ⬅️ Changed this
               };

                try {
                  // Add rating (this now matches Firestore rules)
                  await FirebaseFirestore.instance
                      .collection('ratings')
                      .add(ratingData);

                  // Update lawyer avgRating safely
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

                  // Lawyers cannot be updated directly by clients; avgRating update requires admin/server function
                  // So we skip avgRating update here to comply with security rules
                  // Optionally, you can create a cloud function to update avgRating securely

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thanks for your rating!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit rating: $e')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.caseData;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Case Details",
            style: TextStyle(color: Color(0xFFD4AF37))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              data['title'] ?? "No Title",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Description: ${data['description'] ?? ''}",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Lawyer: ${data['lawyerName'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Status: ",
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
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Show Won/Lost buttons only if client owns this case and status is pending
            if (_status == 'Pending' &&
                data['clientId'] == FirebaseAuth.instance.currentUser?.uid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _updateCaseStatus('Won'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Mark Won"),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateCaseStatus('Lost'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Mark Lost"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
