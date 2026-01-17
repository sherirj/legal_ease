import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ease/login_screen.dart';

class LawyerProfilePage extends StatefulWidget {
  const LawyerProfilePage({super.key});

  @override
  State<LawyerProfilePage> createState() => _LawyerProfilePageState();
}

class _LawyerProfilePageState extends State<LawyerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController priceController;
  late TextEditingController locationController;
  late TextEditingController phoneController;
  late TextEditingController specializationController;

  bool _saving = false;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    priceController = TextEditingController();
    locationController = TextEditingController();
    phoneController = TextEditingController();
    specializationController = TextEditingController();
    _loadLawyerProfile();
  }

  // 🔹 Load lawyer profile from Firestore
  Future<void> _loadLawyerProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _navigateToLogin();
        return;
      }

      _userId = user.uid;

      final doc = await _firestore.collection('lawyers').doc(_userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          priceController.text = data['hourlyRate']?.toString() ?? '';
          locationController.text = data['location'] ?? '';
          phoneController.text = data['phone'] ?? '';
          specializationController.text = data['specialization'] ?? '';
          _isLoading = false;
        });
      } else {
        // Create new profile document
        setState(() {
          emailController.text = user.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('⚠️ Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  // 🔹 Save/Update profile to Firestore
  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      _showSnackBar('⚠️ Please fill in all required fields');
      return;
    }

    setState(() => _saving = true);

    try {
      double? hourlyRate;
      try {
        hourlyRate = double.parse(priceController.text);
      } catch (e) {
        _showSnackBar('⚠️ Invalid price format');
        setState(() => _saving = false);
        return;
      }

      await _firestore.collection('lawyers').doc(_userId).set({
        'uid': _userId,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'hourlyRate': hourlyRate,
        'location': locationController.text.trim(),
        'specialization': specializationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar('✅ Profile updated successfully!');
    } catch (e) {
      _showSnackBar('⚠️ Failed to save: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  // 🔹 Delete profile
  Future<void> _deleteProfile() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e1e1e),
        title: const Text('Delete Profile',
            style: TextStyle(color: Color(0xFFd4af37))),
        content: const Text('Are you sure? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('lawyers').doc(_userId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  _navigateToLogin();
                }
              } catch (e) {
                _showSnackBar('⚠️ Error deleting profile: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🔹 Logout
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      _navigateToLogin();
    } catch (e) {
      _showSnackBar('⚠️ Logout failed: $e');
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1e1e1e),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    priceController.dispose();
    locationController.dispose();
    phoneController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFd4af37),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Profile Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFd4af37),
                      child: const Icon(Icons.person,
                          color: Colors.black, size: 60),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Lawyer Profile",
                      style: TextStyle(
                        color: Color(0xFFd4af37),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Basic Info Section
                    _buildSectionHeader("Basic Information"),
                    _buildTextField(nameController, "Full Name", Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(emailController, "Email", Icons.email,
                        readOnly: true),
                    const SizedBox(height: 12),
                    _buildTextField(
                        phoneController, "Phone Number", Icons.phone),

                    const SizedBox(height: 30),

                    // Professional Info Section
                    _buildSectionHeader("Professional Details"),
                    _buildTextField(specializationController, "Specialization",
                        Icons.school,
                        hint: "e.g., Criminal Law, Corporate Law"),
                    const SizedBox(height: 12),
                    _buildTextField(
                        priceController, "Rate (₨)", Icons.attach_money,
                        hint: "e.g., 5000"),
                    const SizedBox(height: 12),
                    _buildTextField(
                        locationController, "Location", Icons.location_on,
                        hint: "e.g., Lahore, Punjab"),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.black),
                      label: Text(
                        _saving ? "Saving..." : "Save Changes",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd4af37),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logout Button
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.black),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd4af37),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Delete Profile Button
                    ElevatedButton.icon(
                      onPressed: _deleteProfile,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        "Delete Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    String? hint,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: labelText.contains("Rate")
          ? TextInputType.number
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFd4af37)),
        labelStyle: const TextStyle(color: Color(0xFFd4af37)),
        hintStyle: TextStyle(color: Colors.grey[600]),
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
    );
  }
}
