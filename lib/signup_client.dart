import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/authservices.dart';

class SignupClientScreen extends StatefulWidget {
  const SignupClientScreen({super.key});

  @override
  State<SignupClientScreen> createState() => _SignupClientScreenState();
}

class _SignupClientScreenState extends State<SignupClientScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();

  String? _gender;
  DateTime? _dob;
  bool _loading = false;

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
        _age.text = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await _auth.signUp(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text.trim(),
      role: 'client',
      gender: _gender,
      dob: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : '',
      age: _age.text.trim(),
    );

    setState(() => _loading = false);

    if (res == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Client account created successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/client-dashboard');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ $res")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Client Signup',
                  style: TextStyle(
                    color: Color(0xFFd4af37),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Name
                TextFormField(
                  controller: _name,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Email
                TextFormField(
                  controller: _email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) => v!.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Password
                TextFormField(
                  controller: _password,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Gender Dropdown
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  value: _gender,
                  style: const TextStyle(color: Colors.white),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _gender = value),
                  decoration: const InputDecoration(labelText: "Gender"),
                  validator: (v) => v == null ? 'Select gender' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Date of Birth
                InkWell(
                  onTap: _pickDOB,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date of Birth",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _dob != null
                          ? DateFormat('yyyy-MM-dd').format(_dob!)
                          : 'Select Date of Birth',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Age (auto-calculated)
                TextFormField(
                  controller: _age,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Age"),
                  readOnly: true,
                ),
                const SizedBox(height: 24),

                // 🔹 Signup Button
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd4af37),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("Sign Up",
                          style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
