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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idNumberController = TextEditingController(); // New controller for ID Number
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _AccountCreationController = AccountCreationController();
  String? _selectedRole; // Variable to store selected role
  final List<String> _roles = ["stakeholder", "emergency_response_team"];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _idNumberController.dispose();
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
      _emailController.text,
      _passwordController.text,
      _idNumberController.text,
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
          final accountStatus = userDoc['account_status'];
          
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
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              )// ,
              // validator: (value) {
              //  if (value == null || value.isEmpty) {
              //     return 'Please enter your email';
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
          // ID Number Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'ID Number (Optional)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return null;
              },
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
                    'Phone Number',
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
                labelText: 'Address (Optional)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
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
                DropdownMenuItem(value: "stakeholder", child: Text("Stakeholder")),
                DropdownMenuItem(value: "emergency_response_team", child: Text("Emergency Response Team")),
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
