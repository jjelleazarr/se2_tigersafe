import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:se2_tigersafe/widgets/custom_button.dart';
import 'package:se2_tigersafe/widgets/footer.dart';

class ProfileSetupScreen extends StatefulWidget {
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _verificationController = VerificationRequestsController();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _role;
  String? _specialization;
  PlatformFile? _proofOfIdentity;
  PlatformFile? _profileImage;

  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isUSTEmail = user.email!.endsWith('@ust.edu.ph');
    setState(() => _isSubmitting = true);

    // Bind password to Google account via FirebaseAuth
    try {
      final email = user.email!;
      final password = _passwordController.text;

      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
    } catch (e) {
      print('Error linking email/password to Google account: $e');
    }

    if (_role == 'stakeholder' && isUSTEmail) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'surname': _surnameController.text,
        'id_number': _idNumberController.text,
        'email': user.email,
        'address': _addressController.text,
        'phone_number': _phoneNumberController.text,
        'roles': ['stakeholder'],
        'account_status': 'Active',
        'created_at': Timestamp.now(),
      });
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (_role == 'emergency_response_team') {
        if (_specialization == null || _proofOfIdentity == null || _descriptionController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please complete all ERT requirements.')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final model = VerificationRequestModel(
        requestId: '',
        firstName: _firstNameController.text,
        middleName: _middleNameController.text,
        surname: _surnameController.text,
        idNumber: _idNumberController.text,
        email: user.email ?? '',
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
        roles: [_role!],
        specialization: _role == 'emergency_response_team' ? _specialization! : '',
        proofOfIdentity: '',
        description: _role == 'emergency_response_team' ? _descriptionController.text : '',
        accountStatus: 'Pending',
        submittedBy: user.uid,
        submittedAt: Timestamp.now(),
        adminId: null,
        reviewedAt: null,
        profileImageUrl: null,
      );

      await _verificationController.submitRequest(
        model,
        _role == 'emergency_response_team'
            ? _proofOfIdentity!
            : PlatformFile(name: '', path: '', size: 0),
        profileImage: _profileImage,
      );

      Navigator.pushReplacementNamed(context, '/account_verification');
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> _pickProofOfIdentity() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null && result.files.single != null) {
      setState(() => _proofOfIdentity = result.files.single);
    }
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single != null) {
      setState(() => _profileImage = result.files.single);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUSTEmail = FirebaseAuth.instance.currentUser?.email?.endsWith('@ust.edu.ph') ?? false;

    return Scaffold(
      appBar: AppBar(title: Text('Complete Profile Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_profileImage != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(File(_profileImage!.path!)),
                )
              else
                CircleAvatar(radius: 50, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: 50)),
              TextButton(onPressed: _pickProfileImage, child: Text('Choose Profile Picture')),

              TextFormField(
                initialValue: FirebaseAuth.instance.currentUser?.email,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Email Used'),
              ),
              if (!isUSTEmail)
                Text('Non-UST Email detected. Manual verification required.', style: TextStyle(color: Colors.red)),

              TextFormField(controller: _passwordController, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'Create Password', suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showPassword = !_showPassword))), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _confirmPasswordController, obscureText: !_showConfirmPassword, decoration: InputDecoration(labelText: 'Confirm Password', suffixIcon: IconButton(icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword))), validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),

              TextFormField(controller: _firstNameController, decoration: InputDecoration(labelText: 'First Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _middleNameController, decoration: InputDecoration(labelText: 'Middle Name')),
              TextFormField(controller: _surnameController, decoration: InputDecoration(labelText: 'Surname'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _idNumberController, decoration: InputDecoration(labelText: 'ID Number'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _addressController, decoration: InputDecoration(labelText: 'Address'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _phoneNumberController, decoration: InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Required' : null),

              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(labelText: 'Select Role'),
                items: [
                  DropdownMenuItem(value: 'stakeholder', child: Text('Stakeholder')),
                  DropdownMenuItem(value: 'emergency_response_team', child: Text('Emergency Response Team')),
                ],
                onChanged: (val) => setState(() => _role = val),
                validator: (v) => v == null ? 'Required' : null,
              ),

              if (_role == 'emergency_response_team') ...[
                DropdownButtonFormField<String>(
                  value: _specialization,
                  decoration: InputDecoration(labelText: 'Specialization'),
                  items: [
                    DropdownMenuItem(value: 'medical', child: Text('Medical')),
                    DropdownMenuItem(value: 'security', child: Text('Security')),
                    DropdownMenuItem(value: 'others', child: Text('Others')),
                  ],
                  onChanged: (val) => setState(() => _specialization = val),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Why do you need access?'), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(_proofOfIdentity != null ? _proofOfIdentity!.name : 'No file selected')),
                    TextButton(onPressed: _pickProofOfIdentity, child: Text('Upload ID')),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: _isSubmitting ? 'Submitting...' : 'Submit',
                onPressed: _isSubmitting ? null : _submitProfile,
              ),
              const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
