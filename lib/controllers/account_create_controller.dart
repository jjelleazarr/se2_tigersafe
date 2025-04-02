// For File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart'; // For Firebase Storage
// import 'package:image_picker/image_picker.dart'; // For image picker

class AccountCreationController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // final ImagePicker _picker = ImagePicker();

  Future<UserCredential?> createAccount(
      String identification,
      String password,
      String lastName,
      String firstName,
      String middleName,
      String phoneNumber,
      String address,
      String role,
      BuildContext? context
      // File? profilePicture, // Nullable File for profile picture
      ) async {
    try {
      // Create user with email and password
      UserCredential userCredential;
      userCredential = await _auth.createUserWithEmailAndPassword(
      email: identification,
      password: password,
      );
      User? user = userCredential.user;

       if (user != null) {
        // Determine if user is immediately active or pending verification
          String accountStatus;
          if (role == "Stakeholder" && identification.endsWith("@ust.edu.ph")) {
            accountStatus = "Active"; // Stakeholders are activated immediately
          } else {
            accountStatus = "Pending"; // ERT & Command Center Personnel need verification
          }
        
        // String? profilePictureUrl;

        // Upload profile picture if provided
        // if (profilePicture != null) {
        //  profilePictureUrl = await _uploadProfilePicture(user.uid, profilePicture);
        // }

        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'identification': identification,
          'last_name': lastName,
          'first_name': firstName,
          'middle_name': middleName,
          'phone_number': phoneNumber,
          'address': address,
          // 'profilePictureUrl': profilePictureUrl, // Store URL
          'email': user.email, //store the email
          'roles': role, // This should be determined by user selection in UI
          'account_status': role == "Stakeholder" && user.email!.endsWith("@ust.edu.ph")
              ? "Active"
              : "Pending", // If UST email & Stakeholder, activate immediately; else, pending verification
          'created_at': Timestamp.now()
        });
        // After user is saved, fetch their data
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final accountStatus = userDoc['account_status'];

          if (accountStatus == "Active") {
            if (context != null) {
              Navigator.pushNamed(context, '/dashboard'); // Active users go to Dashboard
            }
          } else {
            if (context != null) {
              Navigator.pushNamed(context, '/verification_pending'); // Pending users go to Verification Screen
            }
          }
        }

        if (accountStatus == "Pending") {
          // If pending, send to verification requests
          await FirebaseFirestore.instance.collection('verification_requests').doc(user.uid).set({
            'email': user.email,
            'role': role,
            'submittedAt': Timestamp.now(),
            'status': 'Pending'
          });

          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification request submitted. Please wait for approval.")),
            );
          }
        }


        return userCredential; // Successful account creation
      } else {
        return null; // User creation failed
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      // Handle specific FirebaseAuth errors (e.g., weak password, email already in use)
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during account creation: ${e.message}')),);
      }
      return null;
    } catch (f) {
      print('Error during account creation: $f');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during account creation: $f')),);
      }
      return null; // General error
    }
  }

//  Future<String?> _uploadProfilePicture(String userId, File profilePicture) async {
//    try {
//      final Reference storageRef = _storage.ref().child('profile_pictures/$userId.jpg'); // Store as jpg
//      final UploadTask uploadTask = storageRef.putFile(profilePicture);
//      final TaskSnapshot snapshot = await uploadTask;
//      final String downloadUrl = await snapshot.ref.getDownloadURL();
//      return downloadUrl;
//    } catch (e) {
//      print('Error uploading profile picture: $e');
//      return null;
//    }
//  }

  // Future<File?> pickImage() async {
  //  final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // Or ImageSource.camera
  //  if (image != null) {
  //    return File(image.path);
  // }
  //  return null;
  // }
}