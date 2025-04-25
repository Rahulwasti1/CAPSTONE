import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save admin login status with error handling
  Future<void> saveAdminLoginStatus(
      {required bool isLoggedIn, required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
      await prefs.setString('userRole', 'admin');
      await prefs.setString('userId', userId);

      // Print confirmation for debugging
      developer.log(
          'Admin login status saved: isLoggedIn=$isLoggedIn, userId=$userId');
    } catch (e) {
      developer.log('Error saving admin login status: $e');
      // Continue without saving preferences
    }
  }

  // Clear login status on logout with error handling
  Future<void> clearLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRole');
      await prefs.remove('userId');
    } catch (e) {
      developer.log('Error clearing login status: $e');
      // Continue without removing preferences
    }
  }

  // Logout admin
  Future<void> logoutAdmin() async {
    try {
      // Clear local storage first
      await clearLoginStatus();

      // Then sign out from Firebase Auth
      await _auth.signOut();

      developer.log('Admin logged out successfully');
    } catch (e) {
      developer.log('Error during admin logout: $e');
      // Try to sign out from Firebase anyway if there was an error with SharedPreferences
      try {
        await _auth.signOut();
      } catch (authError) {
        developer.log('Error signing out from Firebase: $authError');
      }
    }
  }

  Future<String> signUpAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error Occured";

    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        // to store user data in firestore

        await _firestore.collection("adminData").doc(credential.user!.uid).set({
          "user": credential.user!.uid,
          "name": name,
          "email": email,
          "role": "admin", // Set role as admin
        });

        // Save login status
        await saveAdminLoginStatus(
            isLoggedIn: true, userId: credential.user!.uid);

        res = "success";
      } else {
        res = "Please fill all the fields required";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // for login

  Future<String> loginAdmin({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occured";

    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        // Check if user exists in admin collection
        DocumentSnapshot adminDoc = await _firestore
            .collection("adminData")
            .doc(credential.user!.uid)
            .get();

        if (!adminDoc.exists) {
          return "Not an admin account";
        }

        // Save login status
        await saveAdminLoginStatus(
            isLoggedIn: true, userId: credential.user!.uid);

        // Double-check that the login status was saved properly
        final prefs = await SharedPreferences.getInstance();
        final savedLoginStatus = prefs.getBool('isLoggedIn') ?? false;
        final savedRole = prefs.getString('userRole') ?? '';
        developer.log(
            'After admin login, SharedPreferences contains: isLoggedIn=$savedLoginStatus, role=$savedRole');

        res = "success";
      } else {
        res = "Please fill all the fields required";
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Firebase Authentication Error";
    } catch (err) {
      return err.toString();
    }
    return res;
  }
}
