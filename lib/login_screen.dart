import 'package:flutter/material.dart';
import 'client_dashboard.dart';
import 'lawyer_dashboard.dart';
import 'legal_assistant.dart';
import 'signup_user.dart';
import 'signup_lawyer.dart';
import 'signup_lawfirm.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  final Map<String, Map<String, String>> _users = {
    'client': {'username': 'Azhan1', 'password': 'pass123'},
  'lawyer': {'username': 'Sheri1', 'password': 'pass123'},
    'lawfirm': {'username': 'lawfirm1', 'password': 'pass123'},
  };

  Future<void> _login(String selectedRole) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    final user = _users[selectedRole];
    if (user != null &&
        user['username'] == username &&
        user['password'] == password) {
      if (selectedRole == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientDashboard()),
        );
      } else if (selectedRole == 'lawyer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AttorneyDashboard()),
        );
      } else if (selectedRole == 'lawfirm') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LegalAssistantDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials or role")),
      );
    }
  }

  Widget _buildRoleButton(String label, String role) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _login(role),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text('Login as $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LegalEase Login")),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: Colors.black, // optional dark background
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                _buildRoleButton("Client", "client"),
                const SizedBox(height: 10),
                _buildRoleButton("Lawyer", "lawyer"),
                const SizedBox(height: 10),
                _buildRoleButton("Law Firm", "lawfirm"),
                const SizedBox(height: 30),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupClientScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupLawyerScreen()),
                    );
                  },
                  child: const Text("Sign up as a Lawyer"),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupLawFirmScreen()),
                    );
                  },
                  child: const Text("Sign up as a Law Firm"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
