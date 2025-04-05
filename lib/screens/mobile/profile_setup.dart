import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:se2_tigersafe/widgets/custom_button.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
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

  String? _role;
  String? _specialization;
  PlatformFile? _proofOfIdentity;
  PlatformFile? _profileImage;

  bool _isSubmitting = false;

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) return;
    if (_role == 'emergency_response_team' && (_specialization == null || _proofOfIdentity == null)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    String? profileImageUrl;
    if (_profileImage != null) {
      final profileRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}_${_profileImage!.name}');
      await profileRef.putFile(File(_profileImage!.path!));
      profileImageUrl = await profileRef.getDownloadURL();
    }

    final isUST = user.email?.endsWith('@ust.edu.ph') ?? false;

    if (_role == 'stakeholder' && isUST) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'first_name': _firstNameController.text,
        'middle_name': _middleNameController.text,
        'surname': _surnameController.text,
        'id_number': _idNumberController.text,
        'email': user.email,
        'address': _addressController.text,
        'phone_number': _phoneNumberController.text,
        'roles': 'stakeholder',
        'profile_image_url': profileImageUrl,
        'account_status': 'Active',
        'created_at': Timestamp.now(),
      });
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
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
        specialization: _specialization ?? '',
        proofOfIdentity: '',
        description: _descriptionController.text,
        accountStatus: 'Pending',
        submittedBy: user.uid,
        submittedAt: Timestamp.now(),
        adminId: null,
        reviewedAt: null,
      );

      await _verificationController.submitRequest(model, _proofOfIdentity!, profileImageUrl: profileImageUrl);

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
    return Scaffold(
      appBar: AppBar(title: Text('Complete Profile Setup')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _firstNameController, decoration: InputDecoration(labelText: 'First Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _middleNameController, decoration: InputDecoration(labelText: 'Middle Name')),
              TextFormField(controller: _surnameController, decoration: InputDecoration(labelText: 'Surname'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _idNumberController, decoration: InputDecoration(labelText: 'ID Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _addressController, decoration: InputDecoration(labelText: 'Address'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _phoneNumberController, decoration: InputDecoration(labelText: 'Phone Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
              Row(
                children: [
                  Expanded(child: Text(_profileImage != null ? _profileImage!.name : 'No profile image selected')),
                  TextButton(onPressed: _pickProfileImage, child: Text('Upload Profile Image')),
                ],
              ),
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
                SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}
