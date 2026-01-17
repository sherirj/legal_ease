import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/authservices.dart';

class SignupLawyerScreen extends StatefulWidget {
  const SignupLawyerScreen({super.key});

  @override
  State<SignupLawyerScreen> createState() => _SignupLawyerScreenState();
}

class _SignupLawyerScreenState extends State<SignupLawyerScreen> {
  final _auth = AuthService();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _specialization = TextEditingController();
  final _experience = TextEditingController();
  final _phone = TextEditingController();
  final _barId = TextEditingController();
  final _location = TextEditingController();
  final _hourlyRate = TextEditingController();

  String? _gender;
  String? _selectedLocation;
  DateTime? _dob;
  bool _loading = false;

  // Pakistani cities list
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

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFFd4af37),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFd4af37),
              surface: Color(0xFF1e1e1e),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select a location')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final userId = userCredential.user!.uid;

      // Parse hourly rate
      double hourlyRate = 0.0;
      try {
        hourlyRate = double.parse(_hourlyRate.text.trim());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Invalid hourly rate')),
        );
        setState(() => _loading = false);
        return;
      }

      // Save lawyer data to Firestore
      await _firestore.collection('lawyers').doc(userId).set({
        'uid': userId,
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'gender': _gender,
        'dateOfBirth':
            _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : '',
        'specialization': _specialization.text.trim(),
        'experience': int.parse(_experience.text.trim()),
        'barId': _barId.text.trim(),
        'location': _selectedLocation,
        'hourlyRate': hourlyRate,
        'role': 'lawyer',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Lawyer account created successfully!'),
            backgroundColor: Color(0xFFd4af37),
          ),
        );
        Navigator.pushReplacementNamed(context, '/attorney-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Error creating account';
      if (e.code == 'weak-password') {
        errorMsg = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'Email already in use';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email address';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ $errorMsg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _specialization.dispose();
    _experience.dispose();
    _phone.dispose();
    _barId.dispose();
    _location.dispose();
    _hourlyRate.dispose();
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Lawyer Signup',
                  style: TextStyle(
                    color: Color(0xFFd4af37),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Section Header: Basic Information
                _buildSectionHeader('Basic Information'),

                // 🔹 Name
                _buildTextFormField(
                  controller: _name,
                  labelText: 'Full Name',
                  icon: Icons.person,
                  validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Email
                _buildTextFormField(
                  controller: _email,
                  labelText: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 Password
                _buildTextFormField(
                  controller: _password,
                  labelText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Phone
                _buildTextFormField(
                  controller: _phone,
                  labelText: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Gender
                _buildGenderDropdown(),
                const SizedBox(height: 16),

                // 🔹 DOB
                _buildDOBPicker(),
                const SizedBox(height: 24),

                // 🔹 Section Header: Professional Information
                _buildSectionHeader('Professional Information'),

                // 🔹 Specialization
                _buildTextFormField(
                  controller: _specialization,
                  labelText: 'Specialization',
                  icon: Icons.school,
                  hint: 'e.g., Criminal Law, Corporate Law',
                  validator: (v) =>
                      v!.isEmpty ? 'Enter your specialization' : null,
                ),
                const SizedBox(height: 16),

                // 🔹 Experience
                _buildTextFormField(
                  controller: _experience,
                  labelText: 'Experience (years)',
                  icon: Icons.work,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter years of experience';
                    try {
                      int.parse(v);
                      return null;
                    } catch (e) {
                      return 'Enter valid number';
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 Bar ID
                _buildTextFormField(
                  controller: _barId,
                  labelText: 'Bar Council ID / License No.',
                  icon: Icons.badge,
                  validator: (v) => v!.isEmpty ? 'Enter Bar ID' : null,
                ),
                const SizedBox(height: 24),

                // 🔹 Section Header: Service Details
                _buildSectionHeader('Service Details'),

                // 🔹 Location Dropdown
                _buildLocationDropdown(),
                const SizedBox(height: 16),

                // 🔹 Hourly Rate
                _buildTextFormField(
                  controller: _hourlyRate,
                  labelText: 'Rate (₨)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  hint: 'e.g., 5000',
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter hourly rate';
                    try {
                      double.parse(v);
                      return null;
                    } catch (e) {
                      return 'Enter valid amount';
                    }
                  },
                ),
                const SizedBox(height: 32),

                // 🔹 Signup Button
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
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
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // 🔹 Login Link
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFd4af37),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
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
          borderSide: const BorderSide(
            color: Color(0xFFd4af37),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
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
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.wc, color: Color(0xFFd4af37)),
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
      ),
      validator: (v) => v == null ? 'Select gender' : null,
    );
  }

  Widget _buildDOBPicker() {
    return InkWell(
      onTap: _pickDOB,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(Icons.cake, color: Color(0xFFd4af37)),
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
        child: Text(
          _dob != null
              ? DateFormat('yyyy-MM-dd').format(_dob!)
              : 'Select Date of Birth',
          style: TextStyle(
            color: _dob != null ? Colors.white : Colors.white70,
          ),
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
