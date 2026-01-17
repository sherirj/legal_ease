import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legal_ease/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();

  String? imageUrl;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // 🔥 READ - Load Client Data from Firestore
  // ----------------------------------------------------------
  Future<void> _loadClientProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameCtrl.text = data['name'] ?? '';
          emailCtrl.text = data['email'] ?? user.email ?? '';
          phoneCtrl.text = data['phone'] ?? '';
          addressCtrl.text = data['address'] ?? '';
          cityCtrl.text = data['city'] ?? '';
          imageUrl = data['imageUrl'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      _showErrorSnackBar('Failed to load profile: $e');
    }
  }

  // ----------------------------------------------------------
  // 🔥 UPDATE - Upload Profile Image
  // ----------------------------------------------------------
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      // Show loading
      setState(() => saving = true);

      File file = File(picked.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child("profile_images/${user.uid}.jpg");

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      setState(() {
        imageUrl = url;
        saving = false;
      });

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(user.uid)
          .update({'imageUrl': url});

      _showSuccessSnackBar('Profile image updated!');
    } catch (e) {
      setState(() => saving = false);
      _showErrorSnackBar('Failed to upload image: $e');
    }
  }

  // ----------------------------------------------------------
  // 🔥 CREATE/UPDATE - Save Profile
  // ----------------------------------------------------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final ref =
          FirebaseFirestore.instance.collection('clients').doc(user.uid);

      await ref.set({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      setState(() => saving = false);

      _showSuccessSnackBar("Profile updated successfully!");
    } catch (e) {
      setState(() => saving = false);
      _showErrorSnackBar('Failed to save profile: $e');
    }
  }

  // ----------------------------------------------------------
  // 🔥 LOGOUT - Sign Out with Confirmation
  // ----------------------------------------------------------
  Future<void> _logout() async {
    final confirm = await _showConfirmDialog(
      'Logout',
      'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: false,
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to logout: $e');
    }
  }

  // ----------------------------------------------------------
  // 🔥 DELETE - Delete Account
  // ----------------------------------------------------------
  Future<void> _deleteAccount() async {
    final confirm = await _showConfirmDialog(
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone. All your data including bookings, cases, and messages will be permanently deleted.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return;

    // Double confirmation for delete
    final doubleConfirm = await _showConfirmDialog(
      'Final Confirmation',
      'This is your last chance. Are you absolutely sure you want to delete your account?',
      confirmText: 'Yes, Delete Forever',
      isDestructive: true,
    );

    if (doubleConfirm != true) return;

    setState(() => saving = true);

    try {
      // Delete profile image from storage if exists
      if (imageUrl != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child("profile_images/${user.uid}.jpg");
          await storageRef.delete();
        } catch (e) {
          print('Failed to delete profile image: $e');
        }
      }

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(user.uid)
          .delete();

      // Delete related data (bookings, cases, etc.)
      // Note: You might want to add more collections here
      final batch = FirebaseFirestore.instance.batch();

      // Delete bookings
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('clientId', isEqualTo: user.uid)
          .get();
      for (var doc in bookings.docs) {
        batch.delete(doc.reference);
      }

      // Delete cases
      final cases = await FirebaseFirestore.instance
          .collection('cases')
          .where('clientId', isEqualTo: user.uid)
          .get();
      for (var doc in cases.docs) {
        batch.delete(doc.reference);
      }

      // Delete ratings
      final ratings = await FirebaseFirestore.instance
          .collection('ratings')
          .where('clientId', isEqualTo: user.uid)
          .get();
      for (var doc in ratings.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete authentication account
      await user.delete();

      // Navigate to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => saving = false);
      _showErrorSnackBar('Failed to delete account: $e');
    }
  }

  // ----------------------------------------------------------
  // 🎨 UI Helper Methods
  // ----------------------------------------------------------
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
            color: Color(0xFFD4AF37),
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
                color: isDestructive ? Colors.red : const Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD4AF37),
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

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    IconData? icon,
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
        prefixIcon:
            icon != null ? Icon(icon, color: const Color(0xFFD4AF37)) : null,
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
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor ?? Colors.black),
        label: Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFFD4AF37),
          disabledBackgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color borderColor = const Color(0xFFD4AF37),
    Color textColor = const Color(0xFFD4AF37),
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Profile Image with Edit Button
              InkWell(
                onTap: saving ? null : _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFD4AF37),
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl!) : null,
                      child: imageUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.black)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF37),
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
                    if (saving)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Profile Settings",
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Full Name
              _buildInputField(
                "Full Name",
                nameCtrl,
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Address
              _buildInputField(
                "Email Address",
                emailCtrl,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              _buildInputField(
                "Phone Number",
                phoneCtrl,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Address
              _buildInputField(
                "Address",
                addressCtrl,
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // City
              _buildInputField(
                "City",
                cityCtrl,
                icon: Icons.location_city,
              ),
              const SizedBox(height: 30),

              // Save Changes Button
              _buildPrimaryButton(
                label: saving ? "Saving..." : "Save Changes",
                icon: Icons.save,
                onPressed: saving ? null : _saveProfile,
              ),
              const SizedBox(height: 16),

              // Logout Button
              _buildOutlinedButton(
                label: "Logout",
                icon: Icons.logout,
                onPressed: _logout,
              ),
              const SizedBox(height: 16),

              // Delete Account Button
              _buildOutlinedButton(
                label: "Delete Account",
                icon: Icons.delete_forever,
                onPressed: _deleteAccount,
                borderColor: Colors.red,
                textColor: Colors.red,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
