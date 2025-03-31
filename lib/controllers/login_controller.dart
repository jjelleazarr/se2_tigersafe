import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/users_controller.dart';

class LoginController{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserController _userController = UserController();

  Future<UserCredential?> loginWithGoogle(BuildContext? context) async {
    try {
      print("Google Sign-In Started...");

      // Ensure Google Sign-In is initialized
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google sign-in was cancelled");
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Google sign-in was cancelled")),
          );
        }
        return null;
      }

      print("✅ Google User: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Missing tokens - Access: ${googleAuth.accessToken}, ID: ${googleAuth.idToken}");
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to obtain required tokens")),
          );
        }
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        print("Firebase user is null");
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to authenticate with Firebase")),
          );
        }
        return null;
      }

      print("Firebase User ID: ${user.uid}");
      print("Firebase User Email: ${user.email ?? 'No email'}");
      print("Firebase User Display Name: ${user.displayName ?? 'No display name'}");

      if (user.email?.endsWith("@ust.edu.ph") ?? false) {
        final userDoc = await _userController.getUser(user.uid);

        if (context != null) {
          if (userDoc != null) {
            Navigator.pushNamed(context, '/dashboard');
          } else {
            Navigator.pushNamed(context, '/profile_setup', arguments: user.uid);
          }
        }
        return userCredential;
      } else {
        // Handle non-UST email case
        if (context != null) {
          Navigator.pushNamed(context, '/verification_request', arguments: user.uid);
        }
        return userCredential;
      }
    } catch (e) {
      print("Detailed Google Sign-In Error: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-in error: ${e.toString()}")),
        );
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

