import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/account_create_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AccountCreateScreen extends StatefulWidget {
  const AccountCreateScreen({super.key});

  @override
  State<AccountCreateScreen> createState() {
    return _AccountCreateScreenState();
  }
}

class _AccountCreateScreenState extends State<AccountCreateScreen> {
  final _identificationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _AccountCreationController = AccountCreationController();
  String? _selectedRole; // Variable to store selected role
  final List<String> _roles = ["Stakeholder", "ERT Member", "Command Center Personnel"];

  @override
  void dispose() {
    _identificationController.dispose();
    _passwordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a role before proceeding.')),
      );
      return;
    }

    UserCredential? userCredential = await _AccountCreationController.createAccount(
      _identificationController.text,
      _passwordController.text,
      _lastNameController.text,
      _firstNameController.text,
      _middleNameController.text,
      _phoneNumberController.text,
      _addressController.text,
      _selectedRole!,
      context
      // _profilePicture, // Pass the selected image file
    );

      if (userCredential != null) {
        print("Account created successfully, navigate to the next screen");

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

        if (userDoc.exists) {
          final accountStatus = userDoc['accountStatus'];
          
          if (accountStatus == "Active") {
            Navigator.pushNamed(context, '/dashboard');  // Active users go to Dashboard
          } else {
            Navigator.pushNamed(context, '/verification_pending');  // Pending users go to Verification Screen
          }
        }
      }   
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        //put this in another class since so many will use it
        title: SizedBox(
          height: kToolbarHeight,
          child: Center(child: Image.asset('assets/UST_LOGO_NO_TEXT_300.png')),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text('***Area for Profile Picture that needs implementation***'),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _identificationController,
              decoration: const InputDecoration(
                labelText: 'Identification (UST Email or ID)',
                border: OutlineInputBorder(),
              )// ,
              // validator: (value) {
              //  if (value == null || value.isEmpty) {
              //     return 'Please enter your UST ID or email';
              //   }
              //   return null;
              // },
            ),
          ),

          const SizedBox(height: 20),
          // Password Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true, // Hides password input
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              )// ,
              // validator: (value) {
              //   if (value == null || value.isEmpty) {
              //     return 'Please enter your password';
              //   }
              //   if (value.length < 6) {
              //    return 'Password must be at least 6 characters';
              //   }
              //   return null;
              // },
            ),
          ),

          const SizedBox(height: 20),
          // Last Name Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Last Name';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),
          // First Name Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your First Name';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),
          // Middle Name Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Middle Name';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),
          // Phone Number Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText:
                    'Phone Number', // Add a phone number text input field if there's something like that??
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Phone Number';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),
          // Address Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Address';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 20),
          // Role Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: "Stakeholder", child: Text("Stakeholder")),
                DropdownMenuItem(value: "Emergency Response Team", child: Text("Emergency Response Team")),
                DropdownMenuItem(value: "Command Center Personnel", child: Text("Command Center Personnel")),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
          ),

          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: _createAccount, //Navigate to account verification page
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text("Submit"),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
