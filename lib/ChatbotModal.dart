import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatbotModal extends StatefulWidget {
  const ChatbotModal({super.key});

  @override
  State<ChatbotModal> createState() => _ChatbotModalState();
}

class _ChatbotModalState extends State<ChatbotModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  static const String baseUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/history'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['history'] as List;
        setState(() {
          _messages.clear();
          for (var entry in history) {
            _messages.add({"role": "user", "text": entry['question']});
            _messages.add({"role": "assistant", "text": entry['answer']});
          }
        });
      }
    } catch (e) {
      debugPrint("⚠️ Could not load history: $e");
    }
  }

  Future<void> _clearHistory() async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/history/clear'));
      if (response.statusCode == 200) {
        setState(() {
          _messages.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat history cleared'),
              backgroundColor: Colors.amber,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ Could not clear history: $e");
    }
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": question});
      _controller.clear();
      _loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? "No response from AI";

        setState(() {
          _messages.add({"role": "assistant", "text": answer});
        });
      } else {
        setState(() {
          _messages.add({
            "role": "assistant",
            "text": "⚠️ Server error ${response.statusCode}"
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages
            .add({"role": "assistant", "text": "⚠️ Error: ${e.toString()}"});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildMessage(Map<String, String> msg) {
    bool isUser = msg["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFB700)])
              : const LinearGradient(
                  colors: [Color(0xFF222222), Color(0xFF111111)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Text(
          msg["text"]!,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LegalEase Chatbot'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text('Clear History?',
                      style: TextStyle(color: Colors.amber)),
                  content: const Text('This will delete all chat history.',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.amber),
                        SizedBox(height: 16),
                        Text('Ask me about legal matters',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 18)),
                        SizedBox(height: 8),
                        Text('I can answer in English or Roman Urdu',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                color: Color(0xFFFFD700),
                backgroundColor: Colors.grey,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "Ask about legal matters...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFFD700),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _loading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
