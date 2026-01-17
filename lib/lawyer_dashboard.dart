import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'lawyerPages/assignedcasesPage.dart';
import 'lawyerPages/lawyer_booking.dart';
import 'lawyerPages/recentMessagespage.dart';
import 'lawyerPages/legalCallendarPage.dart';
import 'lawyerPages/LawyerProfile.dart';
import 'services/case_services.dart';

class AttorneyDashboard extends StatefulWidget {
  const AttorneyDashboard({super.key});

  @override
  State<AttorneyDashboard> createState() => _AttorneyDashboardState();
}

class _AttorneyDashboardState extends State<AttorneyDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  int _selectedIndex = 0;

  final CaseService _caseService = CaseService();

  String lawyerName = 'Lawyer';
  String lawyerEmail = '';
  String lawyerPhotoUrl = '';

  static const List<Widget> _pages = <Widget>[
    AssignedCasesPage(),
    LegalCalendarPage(),
    RecentMessagesPage(),
    LawyerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    fetchLawyerData();
  }

  Future<void> fetchLawyerData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      lawyerEmail = currentUser.email ?? '';
      final doc = await FirebaseFirestore.instance
          .collection('lawyers')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        setState(() {
          lawyerName = doc.data()?['name'] ?? 'Lawyer';
          lawyerPhotoUrl = doc.data()?['photoUrl'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _controller.reset();
      _controller.forward();
    });
  }

  Future<void> closeCase({
    required String caseId,
    required String lawyerId,
    required String clientName,
    String verdict = 'won',
    String notes = 'Case successfully closed',
  }) async {
    try {
      await _caseService.closeCase(
        caseId: caseId,
        lawyerId: lawyerId,
        clientName: clientName,
        verdict: verdict,
        notes: notes,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Case closed and success recorded')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to close case: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 6,
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            // Logo
            Image.asset('assets/logo.jpeg', height: 36, width: 36),
            const SizedBox(width: 12),
            // Welcome message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $lawyerName!',
                    style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Profile avatar
            CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: lawyerPhotoUrl.isNotEmpty
                  ? NetworkImage(lawyerPhotoUrl)
                  : null,
              child: lawyerPhotoUrl.isEmpty
                  ? Text(
                      lawyerName.isNotEmpty ? lawyerName[0].toUpperCase() : 'L',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
        centerTitle: false,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3E2723)),
              accountName: Text(
                lawyerName,
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                lawyerEmail,
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.brown,
                backgroundImage: lawyerPhotoUrl.isNotEmpty
                    ? NetworkImage(lawyerPhotoUrl)
                    : null,
                child: lawyerPhotoUrl.isEmpty
                    ? Text(
                        lawyerName.isNotEmpty
                            ? lawyerName[0].toUpperCase()
                            : 'L',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            ),
            _buildDrawerItem(Icons.work_outline, 'Cases', 0),
            _buildDrawerItem(Icons.calendar_today_outlined, 'Calendar', 1),
            _buildDrawerItem(Icons.message_outlined, 'Messages', 2),
            _buildDrawerItem(Icons.person_outline, 'Profile', 3),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline), label: 'Cases'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      selected: _selectedIndex == index,
      selectedTileColor: const Color(0xFF3E2723),
      onTap: () {
        Navigator.pop(context);
        _onItemTapped(index);
      },
    );
  }
}
