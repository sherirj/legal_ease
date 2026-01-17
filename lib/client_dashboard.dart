import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  static const List<Widget> _pagesBase = <Widget>[
    _ActiveCasesPage(),
    ChatbotShortcutPage(),
    _LegalDocumentsPage(),
    _ChatWithLawyerPage(),
    _BookLawyerPage(),
    _ProfilePage(),
  ];

  late List<Widget> _pages;

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

    _pages = List.from(_pagesBase);
    _pages.add(const _ChatWithLawyerPage());
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
          icon: Icon(Icons.folder_open_outlined),
          label: 'Cases',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chatbot',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Documents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Chat Lawyer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'Book Lawyer',
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
        title: const Text('Client Dashboard'),
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

/// Existing pages

class _ActiveCasesPage extends StatelessWidget {
  const _ActiveCasesPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Active Cases',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          5,
          (index) => Card(
            color: Colors.brown.shade800,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.gavel, color: Colors.brown.shade300),
              title: Text(
                'Case #${1000 + index}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Status: Processing',
                style: TextStyle(color: Colors.brown.shade200),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Colors.brown.shade300, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed('/case-management');
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ChatbotShortcutPage extends StatelessWidget {
  const ChatbotShortcutPage({super.key});

  void _openChatbot(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => const ChatbotModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.brown.shade800,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openChatbot(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 72,
                  color: Colors.brown.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Open Legal Chatbot',
                  style: TextStyle(
                    color: Colors.brown.shade300,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get quick legal advice and support through our AI chatbot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.brown.shade200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatbotModal extends StatefulWidget {
  const ChatbotModal({super.key});

  @override
  State<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends State<ChatbotModal> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": question});
      _controller.clear();
      _loading = true;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('legalChatbot');
      final response = await callable.call({'question': question});

      // Expecting JSON { "answer": "..." }
      final data = response.data;
      final answer = data is Map && data['answer'] != null
          ? data['answer'].toString()
          : data.toString();

      setState(() {
        _messages.add({"role": "assistant", "text": answer});
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": "⚠️ Firebase Error: ${e.message ?? e.code}"
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": "⚠️ Unexpected error: ${e.toString()}"
        });
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              'LegalEase Chatbot',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.brown.shade800
                          : Colors.brown.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about the Constitution...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocumentsPage extends StatelessWidget {
  const _LegalDocumentsPage();

  @override
  Widget build(BuildContext context) {
    final documents = [
      'Power of Attorney',
      'Lease Agreement',
      'Court Summons',
      'NDA Contract',
      'Legal Notice',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Legal Documents',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...documents.map(
          (doc) => Card(
            color: Colors.brown.shade800,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.description, color: Colors.brown.shade300),
              title: Text(
                doc,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Colors.brown.shade300, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening document: \$doc')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatWithLawyerPage extends StatefulWidget {
  const _ChatWithLawyerPage();

  @override
  State<_ChatWithLawyerPage> createState() => _ChatWithLawyerPageState();
}

class _ChatWithLawyerPageState extends State<_ChatWithLawyerPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      // Simulate lawyer reply after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _messages.add(
            _ChatMessage(
                text:
                    'Lawyer: Thanks for your message, I will review and get back to you shortly.',
                isUser: false),
          );
        });
        _scrollToBottom();
      });
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.brown.shade700 : Colors.brown.shade800,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessage(_messages[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.brown.shade900,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.brown.shade800,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: Icon(Icons.send, color: Colors.brown.shade300),
                tooltip: 'Send',
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _BookLawyerPage extends StatefulWidget {
  const _BookLawyerPage();

  @override
  State<_BookLawyerPage> createState() => _BookLawyerPageState();
}

class _BookLawyerPageState extends State<_BookLawyerPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Booking Confirmed'),
          content: Text(
            'Category: Domestic Violence\n'
            'Name: ${_nameController.text}\n'
            'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}\n'
            'Details: ${_descController.text}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
    }
  }

  Widget _animatedField({required int delay, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, offset, _) => Transform.translate(
        offset: offset,
        child: Opacity(
          opacity: _animController.value,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _animatedField(
              delay: 0,
              child: TextFormField(
                enabled: false,
                initialValue: 'Domestic Violence',
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _animatedField(
              delay: 100,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter your name' : null,
              ),
            ),
            const SizedBox(height: 20),
            _animatedField(
              delay: 200,
              child: TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Case Description'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter case details' : null,
              ),
            ),
            const SizedBox(height: 20),
            _animatedField(
              delay: 300,
              child: ListTile(
                title: const Text('Appointment Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? _selectedDate!.toLocal().toString().split(' ')[0]
                      : 'No date selected',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _animatedField(
              delay: 400,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade800,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _nameController = TextEditingController(text: "Azhan Afzal");
  final _emailController = TextEditingController(text: "Azhan@google.com");
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
            backgroundColor: Colors.brown.shade800,
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
