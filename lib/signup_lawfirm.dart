import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupLawFirmScreen extends StatefulWidget {
  const SignupLawFirmScreen({super.key});

  @override
  State<SignupLawFirmScreen> createState() => _SignupLawFirmScreenState();
}

class _SignupLawFirmScreenState extends State<SignupLawFirmScreen> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Firm Details
  final _firmName = TextEditingController();
  final _ntnNumber = TextEditingController();
  final _barCouncilNumber = TextEditingController();

  // Admin Details
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();
  final _adminPhone = TextEditingController();

  // Contact Information
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactAddress = TextEditingController();

  // Practice Areas
  List<String> _selectedPracticeAreas = [];
  final List<String> _practiceAreaOptions = [
    'Criminal Law',
    'Family Law',
    'Property Law',
  ];

  // Location
  String? _selectedLocation;
  final List<String> _pakistaniCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Multan',
    'Hyderabad',
    'Peshawar',
    'Quetta',
    'Faisalabad',
    'Gujranwala',
    'Sialkot',
    'Sargodha',
    'Bahawalpur',
    'Gilgit',
    'Muzaffarabad',
    'Other',
  ];

  bool _loading = false;
  final RegExp _ntnRegex = RegExp(r'^\d{7}-\d{1}$');

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPracticeAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Select at least one practice area')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a location')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Step 1: Create Firebase user
      print('📝 Step 1: Creating Firebase user...');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _adminEmail.text.trim(),
        password: _adminPassword.text.trim(),
      );

      final userId = userCredential.user!.uid;
      print('✅ Firebase user created: $userId');

      // Step 2: Save to users collection (for login/role checking)
      print('📝 Step 2: Saving to users collection...');
      try {
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': _adminEmail.text.trim(),
          'role': 'law_firm',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Users collection saved successfully');
      } catch (e) {
        print('❌ Error saving to users collection: $e');
        throw Exception('Failed to save user data: $e');
      }

      // Step 3: Save law firm details to law_firms collection
      print('📝 Step 3: Saving to law_firms collection...');
      try {
        await _firestore.collection('law_firms').doc(userId).set({
          'uid': userId,
          'firmName': _firmName.text.trim(),
          'ntnNumber': _ntnNumber.text.trim(),
          'barCouncilNumber': _barCouncilNumber.text.trim(),
          'admin': {
            'name': _adminName.text.trim(),
            'email': _adminEmail.text.trim(),
            'phone': _adminPhone.text.trim(),
          },
          'contact': {
            'email': _contactEmail.text.trim(),
            'phone': _contactPhone.text.trim(),
            'address': _contactAddress.text.trim(),
          },
          'practiceAreas': _selectedPracticeAreas,
          'location': _selectedLocation,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Law firms collection saved successfully');
      } catch (e) {
        print('❌ Error saving to law_firms collection: $e');
        throw Exception('Failed to save firm data: $e');
      }

      print('✅ All data saved successfully!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Law Firm account created successfully!'),
            backgroundColor: Color(0xFFd4af37),
          ),
        );
        Navigator.pushReplacementNamed(context, '/law-firm-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Error creating account';
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');

      if (e.code == 'weak-password') {
        errorMsg = 'Password too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'Email already registered';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email address';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ $errorMsg')),
        );
      }
    } catch (e) {
      print('❌ Signup Error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firmName.dispose();
    _ntnNumber.dispose();
    _barCouncilNumber.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    _adminPhone.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _contactAddress.dispose();
    super.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Law Firm Registration',
                  style: TextStyle(
                    color: Color(0xFFd4af37),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your law firm account',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 32),

                // Firm Details
                _buildSectionHeader('Firm Details'),
                _buildTextField(
                  controller: _firmName,
                  label: 'Law Firm Name',
                  icon: Icons.business,
                  validator: (v) => v!.isEmpty ? 'Enter firm name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ntnNumber,
                  label: 'NTN Number (Format: 1234567-8)',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter NTN number';
                    if (!_ntnRegex.hasMatch(v)) {
                      return 'Invalid NTN format (Use 1234567-8)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _barCouncilNumber,
                  label: 'Bar Council Registration Number',
                  icon: Icons.badge,
                  validator: (v) =>
                      v!.isEmpty ? 'Enter Bar Council number' : null,
                ),
                const SizedBox(height: 32),

                // Admin Details
                _buildSectionHeader('Admin Details'),
                _buildTextField(
                  controller: _adminName,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (v) => v!.isEmpty ? 'Enter admin name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _adminEmail,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _adminPassword,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _adminPhone,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 32),

                // Contact Info
                _buildSectionHeader('Contact Information'),
                _buildTextField(
                  controller: _contactEmail,
                  label: 'Office Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactPhone,
                  label: 'Office Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactAddress,
                  label: 'Office Address',
                  icon: Icons.location_on,
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Enter office address' : null,
                ),
                const SizedBox(height: 32),

                // Location
                _buildSectionHeader('Location'),
                _buildLocationDropdown(),
                const SizedBox(height: 32),

                // Practice Areas
                _buildSectionHeader('Practice Areas'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _practiceAreaOptions.map((area) {
                    final isSelected = _selectedPracticeAreas.contains(area);
                    return FilterChip(
                      label: Text(area),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          isSelected
                              ? _selectedPracticeAreas.remove(area)
                              : _selectedPracticeAreas.add(area);
                        });
                      },
                      backgroundColor: Colors.grey[900],
                      selectedColor: const Color(0xFFd4af37),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _loading ? null : _submitSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd4af37),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFFd4af37),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFd4af37),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFd4af37)),
        labelStyle: const TextStyle(color: Color(0xFFd4af37)),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFd4af37), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.grey[900],
      value: _selectedLocation,
      style: const TextStyle(color: Colors.white),
      items: _pakistaniCities
          .map((city) => DropdownMenuItem(
                value: city,
                child: Text(city),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedLocation = value),
      decoration: InputDecoration(
        labelText: 'Location',
        prefixIcon: const Icon(Icons.location_on, color: Color(0xFFd4af37)),
        labelStyle: const TextStyle(color: Color(0xFFd4af37)),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFd4af37),
            width: 2,
          ),
        ),
      ),
      validator: (v) => v == null ? 'Select location' : null,
    );
  }
}
