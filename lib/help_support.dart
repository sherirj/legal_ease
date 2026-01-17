import 'package:flutter/material.dart';

class HelpSupport extends StatefulWidget {
  const HelpSupport({super.key});

  @override
  State<HelpSupport> createState() => _HelpSupportState();
}

class _HelpSupportState extends State<HelpSupport>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  final List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'How do I reset my password?',
      answer:
      'To reset your password, go to the Profile Settings page and select "Change Password". Follow the instructions there.',
    ),
    _FaqItem(
      question: 'How to upload legal documents?',
      answer:
      'Navigate to the Document Center screen and use the upload button to add new documents. Supported file types are PDF and DOC.',
    ),
    _FaqItem(
      question: 'How to contact support?',
      answer:
      'You can contact support by emailing support@legalapp.com or using the chat feature in the Legal Chatbot screen.',
    ),
    _FaqItem(
      question: 'How to manage my subscription?',
      answer:
      'Go to the Subscription screen from your dashboard to view pricing plans and manage your billing information.',
    ),
    _FaqItem(
      question: 'Can I change the application language?',
      answer:
      'Yes, you can toggle between Urdu and English in the Language Settings screen accessible from your profile.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFaqCard(_FaqItem item) {
    return ExpansionTile(
      textColor: Colors.brown.shade300,
      iconColor: Colors.brown.shade300,
      collapsedTextColor: Colors.white,
      collapsedIconColor: Colors.white70,
      title: Text(item.question,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.brown.shade800,
      collapsedBackgroundColor: Colors.brown.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      collapsedShape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            item.answer,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.brown.shade700,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._faqItems.map(_buildFaqCard),
            const SizedBox(height: 32),
            Card(
              color: Colors.brown.shade800,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.contact_support_outlined,
                    color: Colors.brown.shade300, size: 36),
                title: const Text(
                  'Contact Support',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
                subtitle: const Text(
                  'Email: support@legalapp.com\nPhone: +92 303 92873729',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    // For demo: just show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support clicked')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Contact'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.brown.shade800,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading:
                Icon(Icons.warning_amber_outlined, color: Colors.brown.shade300, size: 36),
                title: const Text(
                  'Escalate to Legal Team',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
                subtitle: const Text(
                  'In urgent situations, escalate your query directly to the legal team.',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    // For demo: just show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Escalate clicked')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Escalate'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}
