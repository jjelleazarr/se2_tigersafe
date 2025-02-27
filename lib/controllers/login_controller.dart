import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/users_controller.dart';
import 'package:se2_tigersafe/models/users_collection.dart';

class LoginController{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserController _userController = UserController();

  Future<UserCredential?> loginWithGoogle(BuildContext? context) async{
    try {
      print("Google Sign-In Started...");

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("Google User: ${googleUser?.email}");

      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      
      final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      print("✅ Firebase User ID: ${user?.uid}");
      
      if (user != null) {
        if (user.email!.endsWith("@ust.edu.ph")) {
          final userDoc = await _userController.getUser(user.uid);

          if (userDoc != null) {
            print("User exists, navigating to homepage");
            Navigator.pushNamed(context!, '/dashboard.dart');
            return userCredential;
          } else {
            print("User does not exist, navigating to profile setup");
            Navigator.pushNamed(context!, '/edit_profile.dart', arguments: user.uid);
            return userCredential;
          }
        } else {
          print("Only UST emails are allowed");
          if (context != null){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Only UST emails are allowed")));
          }
          _googleSignIn.signOut();
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Error during Google Sign In: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during sign in : $e")),);
      }
      return null;
    }
  }

  Future<UserCredential?> loginWithUsernamePassword(String username, String password, BuildContext? context) async {
    int failedAttempts = 0;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: username, password: password);
        return userCredential;
    }
    on FirebaseAuthException catch (e) {
      String errorMessage = "";
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          failedAttempts++;
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          failedAttempts++;
          break;
        default:
          errorMessage = 'An error occured: ${e.message}';
          break;
      }
      if(context != null){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)),);
      }
      print("Error during username/password login: $e");
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        final userDoc = await _userController.getUser(username);
        if (userDoc!.email.isNotEmpty) {
          await accountLocking(userDoc.userId, failedAttempts);
        }
      }
      return null;
    }
  }

  Future<void> profileSetup(String userId, Map<String, dynamic> userDetails, context) async {
    try {
      _userController.updateUser(userId, userDetails);
      print("Profile setup completed");
      Navigator.pushNamed(context, '/dashboard.dart');
    } catch (e) {
      print("Error during profile setup: $e");
    }
  }

  Future<void> accountLocking(String userId, int failedAttempts) async {
    if(failedAttempts > 3) {
      try {
        await _firestore.collection('users').doc(userId).update({'accountStatus': 'locked'}); // Account locked
        print("Account locked.");
        final userDoc = await _userController.getUser(userId);
        await FirebaseAuth.instance.sendPasswordResetEmail(email: userDoc!.email); // Password reset email sent
        print("Password reset email sent.");
      } catch (e) {
        print("Error locking account: $e");
      }
    }
  }
}
