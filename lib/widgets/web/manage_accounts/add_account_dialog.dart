// add_account_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAccountDialog extends StatefulWidget {
  final VoidCallback onSubmitted;
  AddAccountDialog({required this.onSubmitted});

  @override
  _AddAccountDialogState createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specializationController = TextEditingController();

  String _selectedRole = 'stakeholder';
  String _status = 'Active';
  String? _emailStatus;
  bool _checkingEmail = false;

  final List<String> roleOptions = [
    'stakeholder',
    'command_center_operator',
    'emergency_response_team',
  ];
  final List<String> statusOptions = ["Active", "Pending", "Rejected", "Banned"];

  Future<void> _checkEmailExists(String email) async {
    setState(() {
      _emailStatus = null;
      _checkingEmail = true;
    });

    final isValidFormat = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
    if (!isValidFormat) {
      setState(() {
        _emailStatus = 'invalid';
        _checkingEmail = false;
      });
      return;
    }

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      _emailStatus = result.docs.isEmpty ? 'valid' : 'exists';
      _checkingEmail = false;
    });
  }

  Future<void> _createAccount() async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userDoc = {
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'roles': [_selectedRole],
        'account_status': _status,
        'created_at': Timestamp.now(),
      };
      if (_selectedRole == 'emergency_response_team') {
        userDoc['specialization'] = _specializationController.text.trim();
      }
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userDoc);

      widget.onSubmitted();
      _clearControllers();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating account: \$e')));
    }
  }

  void _clearControllers() {
    _emailController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _surnameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    _passwordController.clear();
    _specializationController.clear();
    setState(() {
      _selectedRole = 'stakeholder';
      _status = 'Active';
      _emailStatus = null;
    });
  }

  @override
  void dispose() {
    _clearControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  suffixIcon: _checkingEmail
                      ? Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (_emailStatus == 'valid')
                          ? Icon(Icons.check, color: Colors.green)
                          : (_emailStatus == 'exists')
                              ? Icon(Icons.error, color: Colors.red)
                              : (_emailStatus == 'invalid')
                                  ? Icon(Icons.warning, color: Colors.orange)
                                  : null,
                ),
                onChanged: (val) {
                  if (val.trim().isNotEmpty) _checkEmailExists(val.trim());
                },
              ),
              if (_emailStatus == 'invalid')
                Text("Invalid email format.", style: TextStyle(color: Colors.orange)),
              if (_emailStatus == 'exists')
                Text("This email is already taken.", style: TextStyle(color: Colors.red)),
              SizedBox(height: 12),
              TextFormField(controller: _firstNameController, decoration: InputDecoration(labelText: 'First Name')),
              TextFormField(controller: _middleNameController, decoration: InputDecoration(labelText: 'Middle Name')),
              TextFormField(controller: _surnameController, decoration: InputDecoration(labelText: 'Surname')),
              TextFormField(controller: _phoneNumberController, decoration: InputDecoration(labelText: 'Phone Number')),
              TextFormField(controller: _addressController, decoration: InputDecoration(labelText: 'Address')),
              TextFormField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: 'Role'),
                items: roleOptions.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              if (_selectedRole == 'emergency_response_team')
                TextFormField(
                  controller: _specializationController,
                  decoration: InputDecoration(labelText: 'Specialization'),
                ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: 'Account Status'),
                items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clearControllers();
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_emailStatus == 'valid') ? _createAccount : null,
          child: Text('Create'),
        ),
      ],
    );
  }
}
