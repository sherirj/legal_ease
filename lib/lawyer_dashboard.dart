import 'package:flutter/material.dart';

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

  static const List<Widget> _pages = <Widget>[
    _AssignedCasesPage(),
    _LegalCalendarPage(),
    _RecentMessagesPage(),
    _ProfilePage(),
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      backgroundColor: Colors.brown.shade900,
      selectedItemColor: Colors.brown.shade300,
      unselectedItemColor: Colors.white70,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          label: 'Cases',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attorney Dashboard'),
        backgroundColor: Colors.brown.shade700,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

class _AssignedCasesPage extends StatelessWidget {
  const _AssignedCasesPage();

  @override
  Widget build(BuildContext context) {
    final cases = List.generate(
      5,
      (index) => {
        'title': 'Case #${2000 + index}',
        'client': 'Client ${index + 1}',
        'status': 'In Progress',
      },
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Assigned Cases',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...cases.map((c) => Card(
              color: Colors.brown.shade800,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.assignment_outlined,
                    color: Colors.brown.shade300),
                title: Text(
                  c['title']!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Client: ${c['client']}',
                  style: TextStyle(color: Colors.brown.shade200),
                ),
                trailing: Text(
                  c['status']!,
                  style: TextStyle(
                    color: Colors.brown.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/case-management');
                },
              ),
            )),
      ],
    );
  }
}

class _LegalCalendarPage extends StatelessWidget {
  const _LegalCalendarPage();

  @override
  Widget build(BuildContext context) {
    // Placeholder calendar with events/alerts
    final events = [
      {'date': '2024-07-05', 'event': 'Hearing: Case #2001'},
      {'date': '2024-07-10', 'event': 'Court Deadline: Report Submission'},
      {'date': '2024-07-15', 'event': 'Client Meeting'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Legal Calendar',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...events.map((e) => Card(
              color: Colors.brown.shade800,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.event_note_outlined,
                    color: Colors.brown.shade300),
                title: Text(
                  e['event']!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  e['date']!,
                  style: TextStyle(color: Colors.brown.shade200),
                ),
              ),
            )),
      ],
    );
  }
}

class _RecentMessagesPage extends StatelessWidget {
  const _RecentMessagesPage();

  @override
  Widget build(BuildContext context) {
    final messages = List.generate(
      5,
      (index) => {
        'client': 'Client ${index + 1}',
        'message': 'Please update me about the case progress.',
        'time': '${index + 1}h ago',
      },
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recent Messages',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...messages.map((m) => Card(
              color: Colors.brown.shade800,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade700,
                  child: Text(
                    m['client']![0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  m['client']!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  m['message']!,
                  style: TextStyle(color: Colors.brown.shade200),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  m['time']!,
                  style: TextStyle(color: Colors.brown.shade400, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/notifications-center');
                },
              ),
            )),
      ],
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _nameController = TextEditingController(text: "Muhammad Shahriyar");
  final _emailController = TextEditingController(text: "Shahriyar@google.com");
  final _passwordController = TextEditingController();

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.brown.shade700,
            child: const Icon(Icons.person, size: 48, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text("Save Changes"),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text(
            "Logout",
            style: TextStyle(color: Colors.white),
          ),
        )
      ],
    );
  }
}
