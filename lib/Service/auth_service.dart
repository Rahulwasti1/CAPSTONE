import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error Occured";
    if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
      try {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        // to store user data in firestore

        await _firestore.collection("userData").doc(credential.user!.uid).set({
          "user": credential.user!.uid,
          "name": name,
          "email": email,
          "password": password
        });
      } catch (err) {
        return err.toString();
      }
    }
    return res;
  }
}
