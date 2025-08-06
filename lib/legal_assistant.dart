import 'package:flutter/material.dart';

class LegalAssistantDashboard extends StatefulWidget {
  const LegalAssistantDashboard({Key? key}) : super(key: key);

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

  static const List<Widget> _pages = <Widget>[
    _TaskListPage(),
    _FileUploadsPage(),
    _AlertsPage(),
    _ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(
      begin: Offset(0, 0.1),
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
          icon: Icon(Icons.checklist_rtl_outlined),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_upload_outlined),
          label: 'File Uploads',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
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
        title: const Text('Legal Assistant Dashboard'),
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

class _TaskListPage extends StatefulWidget {
  const _TaskListPage();

  @override
  State<_TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<_TaskListPage> {
  final List<_Task> _tasks = [
    _Task(title: 'Prepare case documents for hearing'),
    _Task(title: 'Upload scanned contracts'),
    _Task(title: 'Schedule client meetings'),
    _Task(title: 'Review latest legal notices'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Task List',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ..._tasks.map(
          (task) => Card(
            color: Colors.brown.shade800,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: CheckboxListTile(
              title: Text(
                task.title,
                style: const TextStyle(color: Colors.white),
              ),
              value: task.completed,
              activeColor: Colors.brown.shade300,
              onChanged: (bool? newValue) {
                setState(() {
                  task.completed = newValue ?? false;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FileUploadsPage extends StatelessWidget {
  const _FileUploadsPage();

  @override
  Widget build(BuildContext context) {
    final files = [
      'Contract_2024.pdf',
      'Client_Agreement.docx',
      'Case_Notes_05July.pdf',
      'Evidence_Photos.zip',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'File Uploads',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...files.map(
          (file) => Card(
            color: Colors.brown.shade800,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.insert_drive_file_outlined,
                  color: Colors.brown.shade300),
              title: Text(
                file,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                icon: Icon(Icons.upload_file_outlined,
                    color: Colors.brown.shade300),
                tooltip: 'Upload file',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Upload pressed for $file')),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.file_upload),
          label: const Text('Upload New File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown.shade700,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload New File pressed')),
            );
          },
        ),
      ],
    );
  }
}

class _AlertsPage extends StatelessWidget {
  const _AlertsPage();

  @override
  Widget build(BuildContext context) {
    final alerts = [
      'Hearing reminder: Case #2023 on 07/12/2024',
      'New message from Attorney for Case #2009',
      'Document review deadline in 3 days',
      'System maintenance scheduled for 07/20/2024',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Alerts',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...alerts.map(
          (alert) => Card(
            color: Colors.brown.shade800,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.notification_important_outlined,
                  color: Colors.brown.shade300),
              title: Text(
                alert,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alert tapped: $alert')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Task {
  final String title;
  bool completed;
  _Task({required this.title, this.completed = false});
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();

  @override
  State<_ProfilePage> createState() => _LegalAssistantProfilePageState();
}

class _LegalAssistantProfilePageState extends State<_ProfilePage> {
  final _nameController = TextEditingController(text: "Law Firm");
  final _emailController = TextEditingController(text: "LawFirm@google.com");
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
            child:
                const Icon(Icons.person_outline, size: 48, color: Colors.white),
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
            backgroundColor: Colors.brown.shade800,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text("Save Changes"),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.brown.shade800),
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            "Logout",
            style: TextStyle(color: Colors.white),
          ),
        )
      ],
    );
  }
}
