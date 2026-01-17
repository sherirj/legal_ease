import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'law_firm_pages/task_list.dart';
import 'law_firm_pages/file_upload.dart';
import 'law_firm_pages/alerts.dart';
import 'law_firm_pages/messages.dart';
import 'law_firm_pages/lawyer_list.dart';
import 'law_firm_pages/bookings.dart';
import 'law_firm_pages/profile_page.dart';

class LegalAssistantDashboard extends StatefulWidget {
  const LegalAssistantDashboard({super.key});

  @override
  State<LegalAssistantDashboard> createState() =>
      _LegalAssistantDashboardState();
}

class _LegalAssistantDashboardState extends State<LegalAssistantDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  int _selectedIndex = 0;

  String assistantName = 'Assistant';
  String assistantEmail = '';
  String assistantPhotoUrl = '';

  final List<Widget> _pages = const [
    TaskListPage(),
    FileUploadsPage(),
    AlertsPage(),
    FirmRecentMessagesPage(),
    LawyersListPage(),
    FirmBookingsPage(), // NEW PAGE
    LegalAssistantProfilePage(), // PROFILE LAST
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    fetchAssistantData();
  }

  Future<void> fetchAssistantData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      assistantEmail = currentUser.email ?? '';
      final doc = await FirebaseFirestore.instance
          .collection('assistants')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        setState(() {
          assistantName = doc.data()?['name'] ?? 'Assistant';
          assistantPhotoUrl = doc.data()?['photoUrl'] ?? '';
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _controller.reset();
      _controller.forward();
    });
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
            Image.asset('assets/logo.jpeg', height: 36, width: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome, $assistantName!',
                style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: assistantPhotoUrl.isNotEmpty
                  ? NetworkImage(assistantPhotoUrl)
                  : null,
              child: assistantPhotoUrl.isEmpty
                  ? Text(
                      assistantName.isNotEmpty
                          ? assistantName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3E2723)),
              accountName: Text(
                assistantName,
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                assistantEmail,
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.brown,
                backgroundImage: assistantPhotoUrl.isNotEmpty
                    ? NetworkImage(assistantPhotoUrl)
                    : null,
                child: assistantPhotoUrl.isEmpty
                    ? Text(
                        assistantName.isNotEmpty
                            ? assistantName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            ),

            _buildDrawerItem(Icons.checklist_rtl_outlined, 'Tasks', 0),
            _buildDrawerItem(Icons.cloud_upload_outlined, 'File Uploads', 1),
            _buildDrawerItem(Icons.notifications_outlined, 'Alerts', 2),
            _buildDrawerItem(Icons.chat_bubble_outlined, 'Messages', 3),
            _buildDrawerItem(Icons.people_alt_outlined, 'Lawyers', 4),
            _buildDrawerItem(Icons.event_note_outlined, 'Bookings', 5), // NEW
            _buildDrawerItem(Icons.settings, 'Profile', 6), // LAST

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
              icon: Icon(Icons.checklist_rtl_outlined), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined), label: 'Uploads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outlined), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined), label: 'Lawyers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Bookings'), // NEW
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Profile'), // LAST
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
