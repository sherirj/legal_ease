import 'package:flutter/material.dart';
import '../../ChatbotModal.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  void _openChatbot(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      context: context,
      builder: (_) => const ChatbotModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF262626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color(0xFFFFD700), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _openChatbot(context),
            splashColor: const Color(0xFFFFD700).withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline,
                      size: 72, color: Color(0xFFFFD700)),
                  SizedBox(height: 20),
                  Text(
                    'Open Legal Chatbot',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ask legal questions and get instant AI help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
