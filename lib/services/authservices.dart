import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ SIGN UP (Universal for all roles)
  Future<String> signUp({
    required String name,
    required String email,
    required String password,
    required String role, // 'client', 'lawyer', 'lawfirm'
    String? gender,
    String? dob,
    String? age,
    String? specialization,
    String? experience,
    String? phone,
    String? barId,
    String? firmName,
    String? location,
  }) async {
    try {
      debugPrint("🔹 Starting signup for $email as $role");

      // 1️⃣ Create Firebase Authentication User
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("User UID is null after signup");
      debugPrint("✅ Firebase user created (UID: $uid)");

      // 2️⃣ Add common user entry in "users"
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Base user document added");

      // 3️⃣ Add role-specific Firestore document
      switch (role) {
        case 'client':
          await _firestore.collection('clients').doc(uid).set({
            'uid': uid,
            'name': name,
            'email': email,
            'gender': gender ?? '',
            'dob': dob ?? '',
            'age': age ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint("✅ Client document added");
          break;

        case 'lawyer':
          await _firestore.collection('lawyers').doc(uid).set({
            'uid': uid,
            'name': name,
            'email': email,
            'specialization': specialization ?? 'General Law',
            'experience': experience ?? '',
            'phone': phone ?? '',
            'barId': barId ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint("✅ Lawyer document added");
          break;

        case 'lawfirm':
          await _firestore.collection('lawfirms').doc(uid).set({
            'uid': uid,
            'firmName': firmName ?? name,
            'email': email,
            'location': location ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint("✅ Lawfirm document added");
          break;

        default:
          throw Exception("Invalid user role: $role");
      }

      debugPrint("🎉 Signup completed successfully for $email");
      return "success";
    } on FirebaseAuthException catch (e) {
      // 👇 Handle specific FirebaseAuth errors more clearly
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Email is already registered.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'weak-password':
          errorMessage = "Password should be at least 6 characters.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your internet connection.";
          break;
        default:
          errorMessage = e.message ?? "Unknown authentication error.";
      }
      debugPrint("❌ FirebaseAuthException [${e.code}]: $errorMessage");
      return errorMessage;
    } on FirebaseException catch (e) {
      debugPrint("❌ Firestore error: ${e.message}");
      return e.message ?? "Firestore operation failed.";
    } catch (e) {
      debugPrint("❌ Unexpected signup error: $e");
      return e.toString();
    }
  }

  /// ✅ LOGIN
  Future<String> signIn(String email, String password) async {
    try {
      debugPrint("🔹 Attempting login for $email");
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint("✅ Login successful for $email");
      return "success";
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your internet connection.";
          break;
        default:
          errorMessage = e.message ?? "Unknown login error.";
      }
      debugPrint("❌ Login failed [${e.code}]: $errorMessage");
      return errorMessage;
    } catch (e) {
      debugPrint("❌ Unexpected login error: $e");
      return e.toString();
    }
  }

  /// ✅ LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint("👋 User signed out.");
  }

  /// ✅ CURRENT USER
  User? get currentUser => _auth.currentUser;

  /// ✅ FETCH ROLE
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      final role = data?['role'];
      debugPrint("🔹 Fetched user role: $role");
      return role;
    } catch (e) {
      debugPrint("❌ Failed to fetch role: $e");
      return null;
    }
  }

  /// ✅ Add/update lawyer details (optional)
  Future<void> addLawyerDetails({
    required String name,
    required String email,
    required String specialization,
    String? experience,
    String? phone,
    String? barId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('lawyers').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'specialization': specialization,
      'experience': experience ?? '',
      'phone': phone ?? '',
      'barId': barId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint("✅ Lawyer details updated for ${user.uid}");
  }

  /// ✅ Add/update client details (optional)
  Future<void> addClientDetails({
    required String name,
    required String email,
    required String gender,
    required String dob,
    required String age,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('clients').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'gender': gender,
      'dob': dob,
      'age': age,
      'role': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint("✅ Client details updated for ${user.uid}");
  }
}
