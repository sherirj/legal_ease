import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'clientPages/ActiveCasesPage.dart';
import 'clientPages/ChatbotPage.dart';
import 'clientPages/LegalDocumentsPage.dart';
import 'clientPages/ChatWithLawyerPage.dart';
import 'clientPages/BookLawyerPage.dart';
import 'clientPages/ProfilePage.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  int _selectedIndex = 0;
  String userName = 'User';
  String userEmail = '';
  String userPhotoUrl = '';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Initialize pages
    _pages = const [
      ActiveCasesPage(),
      ChatbotPage(),
      LegalDocumentsPage(),
      ChatWithLawyerPage(),
      BookLawyerPage(),
      ProfilePage(),
    ];

    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userEmail = currentUser.email ?? '';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? 'User';
          userPhotoUrl = doc.data()?['photoUrl'] ?? '';
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
                    'Welcome, $userName!',
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
              backgroundColor: Colors.brown,
              backgroundImage:
                  userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
              child: userPhotoUrl.isEmpty
                  ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white))
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
                userName,
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                userEmail,
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.brown,
                backgroundImage:
                    userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                child: userPhotoUrl.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            ),
            _buildDrawerItem(Icons.folder_open_outlined, 'Cases', 0),
            _buildDrawerItem(Icons.chat_bubble_outline, 'Chatbot', 1),
            _buildDrawerItem(Icons.description_outlined, 'Documents', 2),
            _buildDrawerItem(Icons.person_outline, 'Chat Lawyer', 3),
            _buildDrawerItem(Icons.schedule, 'Book Lawyer', 4),
            _buildDrawerItem(Icons.settings_outlined, 'Profile', 5),
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
        child:
            SlideTransition(position: _slideUp, child: _pages[_selectedIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, -1),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.folder_open_outlined), label: 'Cases'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chatbot'),
            BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined), label: 'Documents'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Chat Lawyer'),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: 'Book Lawyer'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined), label: 'Profile'),
          ],
        ),
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
