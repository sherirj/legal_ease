import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddLawyerPage extends StatefulWidget {
  const AddLawyerPage({super.key});

  @override
  State<AddLawyerPage> createState() => _AddLawyerPageState();
}

class _AddLawyerPageState extends State<AddLawyerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _yearsExperienceController = TextEditingController();

  String? _selectedSpecialization;
  bool _loading = false;

  final List<String> specializations = [
    'Corporate Law',
    'Criminal Law',
    'Family Law',
    'Intellectual Property',
    'Real Estate',
    'Tax Law',
    'Labor Law',
    'Civil Litigation',
    'Contract Law',
    'Immigration Law',
    'Other',
  ];

  void _addLawyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a specialization')),
      );
      return;
    }

    setState(() => _loading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final lawyerData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialization': _selectedSpecialization,
      'licenseNumber': _licenseNumberController.text.trim(),
      'yearsExperience': int.tryParse(_yearsExperienceController.text) ?? 0,
      'lawFirmId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('lawyers').add(lawyerData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Lawyer added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1A17),
      appBar: AppBar(
        title: const Text('Add Lawyer',
            style: TextStyle(color: Color(0xFFD4AF37))),
        backgroundColor: const Color(0xFF3E2723),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Lawyer Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Lawyer Name',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                validator: (v) => v!.isEmpty ? 'Enter lawyer name' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 16),

              // Specialization Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                dropdownColor: const Color(0xFF3E2723),
                items: specializations.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecialization = newValue;
                  });
                },
                validator: (v) => v == null ? 'Select specialization' : null,
              ),
              const SizedBox(height: 16),

              // License Number
              TextFormField(
                controller: _licenseNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                validator: (v) => v!.isEmpty ? 'Enter license number' : null,
              ),
              const SizedBox(height: 16),

              // Years of Experience
              TextFormField(
                controller: _yearsExperienceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Enter years of experience' : null,
              ),
              const SizedBox(height: 24),

              // Add Button
              ElevatedButton(
                onPressed: _loading ? null : _addLawyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Add Lawyer',
                        style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _yearsExperienceController.dispose();
    super.dispose();
  }
}
