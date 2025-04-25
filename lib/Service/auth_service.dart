import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      developer.log('Error checking if user is logged in: $e');
      return false;
    }
  }

  // Get current user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userRole');
    } catch (e) {
      developer.log('Error getting user role: $e');
      return null;
    }
  }

  // Save login status with error handling
  Future<void> saveLoginStatus(
      {required bool isLoggedIn,
      required String role,
      required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
      await prefs.setString('userRole', role);
      await prefs.setString('userId', userId);

      // Print confirmation for debugging
      developer.log(
          'Login status saved: isLoggedIn=$isLoggedIn, role=$role, userId=$userId');
    } catch (e) {
      developer.log('Error saving login status: $e');
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

  // Logout user
  Future<void> logoutUser() async {
    try {
      // Clear local storage first
      await clearLoginStatus();

      // Then sign out from Firebase Auth
      await _auth.signOut();

      developer.log('User logged out successfully');
    } catch (e) {
      developer.log('Error during logout: $e');
      // Try to sign out from Firebase anyway if there was an error with SharedPreferences
      try {
        await _auth.signOut();
      } catch (authError) {
        developer.log('Error signing out from Firebase: $authError');
      }
    }
  }

  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error Occured";

    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        // Extract username from email if name is generic
        String username = name;
        if (name.toLowerCase() == 'user' || name.isEmpty) {
          username = email.split('@')[0];
        }

        // Update Firebase Auth display name
        await credential.user!.updateDisplayName(username);

        // to store user data in firestore (in both collections for compatibility)
        final userData = {
          "uid": credential.user!.uid,
          "username": username,
          "name": username,
          "email": email,
          "role": "buyer", // Default role is buyer
          "createdAt": FieldValue.serverTimestamp(),
        };

        // Save to userData collection (old)
        await _firestore
            .collection("userData")
            .doc(credential.user!.uid)
            .set(userData);

        // Also save to users collection (new)
        await _firestore
            .collection("users")
            .doc(credential.user!.uid)
            .set(userData);

        // Save login status
        await saveLoginStatus(
            isLoggedIn: true, role: "buyer", userId: credential.user!.uid);

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
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";

    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        User user = credential.user!;

        // Get user role from Firestore
        String role = "buyer"; // Default role
        String username = "";

        try {
          // Check both collections
          DocumentSnapshot userDoc =
              await _firestore.collection("userData").doc(user.uid).get();

          // If not found in userData, try users collection
          if (!userDoc.exists) {
            userDoc = await _firestore.collection("users").doc(user.uid).get();
          }

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            role = userData["role"] ?? "buyer";
            username = userData["username"] ?? userData["name"] ?? "";

            // If username is empty, set it from email
            if (username.isEmpty || username.toLowerCase() == "user") {
              username = email.split('@')[0];

              // Update the username in Firestore
              await _firestore.collection("users").doc(user.uid).set({
                "username": username,
                "name": username,
                "updatedAt": FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              // Also update in userData collection for compatibility
              await _firestore.collection("userData").doc(user.uid).set({
                "username": username,
                "name": username,
                "updatedAt": FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          }

          // Save login status
          await saveLoginStatus(isLoggedIn: true, role: role, userId: user.uid);

          res = "success";
        } catch (e) {
          developer.log('Error getting/updating user data: $e');
          // Still allow login if Firestore operations fail
          await saveLoginStatus(
              isLoggedIn: true, role: "buyer", userId: user.uid);
          res = "success";
        }
      } else {
        res = "Please enter all the fields";
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          res = "No user found with this email";
        } else if (e.code == 'wrong-password') {
          res = "Wrong password";
        } else {
          res = e.message ?? "An error occurred";
        }
      } else {
        res = e.toString();
      }
    }
    return res;
  }
}
