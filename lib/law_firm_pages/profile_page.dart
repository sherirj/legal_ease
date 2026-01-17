import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class LegalAssistantProfilePage extends StatefulWidget {
  const LegalAssistantProfilePage({super.key});

  @override
  State<LegalAssistantProfilePage> createState() =>
      _LegalAssistantProfilePageState();
}

class _LegalAssistantProfilePageState extends State<LegalAssistantProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _firmNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _specializationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firmNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _specializationController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // READ - Load profile data
  // READ - Load profile data
  // READ - Load profile data
  Future<void> _loadProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      // Try to load from 'law_firms' first, then fall back to 'lawfirms'
      var doc = await _firestore.collection('law_firms').doc(uid).get();

      if (!doc.exists) {
        doc = await _firestore.collection('lawfirms').doc(uid).get();
      }

      if (doc.exists) {
        final data = doc.data()!;
        print('📖 Loaded data from Firestore: $data');

        setState(() {
          // Basic firm info
          _firmNameController.text = data['firmName'] ?? '';

          // Get email from admin object if it exists
          if (data['admin'] != null && data['admin'] is Map) {
            _emailController.text = data['admin']['email'] ?? '';
            _phoneController.text = data['admin']['phone'] ?? '';
          } else {
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
          }

          // Get contact info from contact object if it exists
          if (data['contact'] != null && data['contact'] is Map) {
            _addressController.text = data['contact']['address'] ?? '';
          } else {
            _addressController.text = data['address'] ?? '';
          }

          // City/Location
          _cityController.text = data['location'] ?? data['city'] ?? '';

          // Professional info
          _specializationController.text = data['specialization'] ??
              (data['practiceAreas'] is List
                  ? (data['practiceAreas'] as List).join(', ')
                  : '');
          _descriptionController.text = data['description'] ?? '';
          _experienceController.text = data['experience']?.toString() ?? '';
          _licenseController.text =
              data['licenseNumber'] ?? data['barCouncilNumber'] ?? '';
          _websiteController.text = data['website'] ?? '';

          _profileImageUrl = data['profileImage'];
          _isLoading = false;

          print('✅ Profile loaded successfully');
        });
      } else {
        print('❌ No document found in either collection');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load profile: $e');
    }
  }

  // UPDATE - Upload Profile Image
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      setState(() => _isSaving = true);

      File file = File(picked.path);

      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child("law_firm_profile_images/$uid.jpg");

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      setState(() {
        _profileImageUrl = url;
        _isSaving = false;
      });

      // Update both collections for compatibility
      await _firestore.collection('law_firms').doc(uid).update({
        'profileImage': url,
      }).catchError((_) {
        // If law_firms doesn't exist, try lawfirms
        return _firestore.collection('lawfirms').doc(uid).update({
          'profileImage': url,
        });
      });

      _showSuccessSnackBar('Profile image updated!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to upload image: $e');
    }
  }

  // CREATE/UPDATE - Save profile data
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      final profileData = {
        'firmName': _firmNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'licenseNumber': _licenseController.text.trim(),
        'website': _websiteController.text.trim(),
        'profileImage': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to both collections for compatibility
      await _firestore
          .collection('law_firms')
          .doc(uid)
          .set(
            profileData,
            SetOptions(merge: true),
          )
          .catchError((_) {
        // If law_firms fails, try lawfirms
        return _firestore.collection('lawfirms').doc(uid).set(
              profileData,
              SetOptions(merge: true),
            );
      });

      setState(() => _isSaving = false);

      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save profile: $e');
    }
  }

  // DELETE - Delete account
  Future<void> _deleteAccount() async {
    final confirm = await _showConfirmDialog(
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone. All your data including bookings, cases, and messages will be permanently deleted.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return;

    // Double confirmation
    final doubleConfirm = await _showConfirmDialog(
      'Final Confirmation',
      'This is your last chance. Are you absolutely sure you want to delete your account?',
      confirmText: 'Yes, Delete Forever',
      isDestructive: true,
    );

    if (doubleConfirm != true) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      // Delete profile image from storage if exists
      if (_profileImageUrl != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child("law_firm_profile_images/$uid.jpg");
          await storageRef.delete();
        } catch (e) {
          print('Failed to delete profile image: $e');
        }
      }

      // Delete from both collections
      await _firestore
          .collection('law_firms')
          .doc(uid)
          .delete()
          .catchError((_) {
        return _firestore.collection('lawfirms').doc(uid).delete();
      });

      // Delete related data (bookings, cases, etc.)
      final batch = _firestore.batch();

      // Delete bookings
      final bookings = await _firestore
          .collection('bookings')
          .where('firmId', isEqualTo: uid)
          .get();
      for (var doc in bookings.docs) {
        batch.delete(doc.reference);
      }

      // Delete cases
      final cases = await _firestore
          .collection('cases')
          .where('firmId', isEqualTo: uid)
          .get();
      for (var doc in cases.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete authentication account
      await _auth.currentUser?.delete();

      // Navigate to login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to delete account: $e');
    }
  }
  // LOGOUT - Sign out with confirmation

  Future<void> _logout() async {
    final confirm = await _showConfirmDialog(
      'Logout',
      'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: false,
    );

    if (confirm != true) return;

    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to logout: $e');
    }
  }

  // UI Helper Methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFd4af37),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    required String confirmText,
    required bool isDestructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFd4af37),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDestructive ? Colors.red : const Color(0xFFd4af37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFFd4af37)),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
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
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFd4af37)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar with image picker
              Center(
                child: InkWell(
                  onTap: _isSaving ? null : _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFd4af37),
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(
                                Icons.business,
                                size: 60,
                                color: Colors.black,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFd4af37),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_isSaving)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFd4af37),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Firm Name
              _buildTextField(
                controller: _firmNameController,
                label: 'Firm Name',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter firm name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // City
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 16),

              // Specialization
              _buildTextField(
                controller: _specializationController,
                label: 'Specialization',
                icon: Icons.gavel,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter specialization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Experience
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                icon: Icons.work,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // License Number
              _buildTextField(
                controller: _licenseController,
                label: 'License Number',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),

              // Website
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd4af37),
                    disabledBackgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFd4af37), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFd4af37),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delete Account Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
