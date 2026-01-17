import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawFirmInformationPage extends StatefulWidget {
  final String firmId;

  const LawFirmInformationPage({super.key, required this.firmId});

  @override
  State<LawFirmInformationPage> createState() => _LawFirmInformationPageState();
}

class _LawFirmInformationPageState extends State<LawFirmInformationPage>
    with SingleTickerProviderStateMixin {
  
  Map<String, dynamic>? lawFirmData;
  bool loading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _loadFirmData();

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  Future<void> _loadFirmData() async {
    final doc = await FirebaseFirestore.instance
        .collection('lawfirms')
        .doc(widget.firmId)
        .get();

    if (doc.exists) {
      setState(() {
        lawFirmData = doc.data();
        loading = false;
      });
      _animController.forward();
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    if (lawFirmData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: const Center(
          child: Text(
            "Law firm not found.",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          lawFirmData!['firmName'] ?? "Law Firm",
          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildDetailsCard(),
              const SizedBox(height: 30),
              _buildViewLawyersButton(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF262626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFFFD700),
            child: Icon(Icons.apartment, size: 40, color: Colors.black),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              lawFirmData!['firmName'] ?? "Law Firm",
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow("📍 Location", lawFirmData!['location'] ?? "Not provided"),
          const SizedBox(height: 12),
          _detailRow("📧 Email", lawFirmData!['email'] ?? "No email"),
          const SizedBox(height: 12),
          _detailRow("🕒 Created At",
              (lawFirmData!['createdAt'] != null)
                  ? lawFirmData!['createdAt'].toDate().toString()
                  : "Unknown"),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildViewLawyersButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FirmLawyersPage(firmId: widget.firmId),
          ),
        );
      },
      child: const Text(
        "View Lawyers in this Firm",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class FirmLawyersPage extends StatelessWidget {
  final String firmId;

  const FirmLawyersPage({super.key, required this.firmId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        title: const Text(
          "Firm Lawyers",
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('lawyers')
            .where('firmId', isEqualTo: firmId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No lawyers found in this firm.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(0xFFFFD700)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFFFFD700)),
                  title: Text(
                    data['name'] ?? "Lawyer",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    data['specialization'] ?? "Specialization",
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
