import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widgets/dashboard_appbar.dart';
import '../widgets/dashboard_drawer_left.dart';
import '../widgets/dashboard_drawer_right.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  String? _error;
  bool _uploadingImage = false;
  bool _saving = false;

  // Profile fields
  String? idNumber;
  String? surname;
  String? firstName;
  String? middleName;
  String? phoneNumber;
  String? address;
  String? role;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not logged in.';
          _loading = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        setState(() {
          _error = 'User data not found.';
          _loading = false;
        });
        return;
      }
      setState(() {
        idNumber = data['id_number']?.toString() ?? '';
        surname = data['surname'] ?? '';
        firstName = data['first_name'] ?? '';
        middleName = data['middle_name'] ?? '';
        phoneNumber = data['phone_number'] ?? '';
        address = data['address'] ?? '';
        role = (data['roles'] is List && data['roles'].isNotEmpty) ? data['roles'][0] : '';
        profileImageUrl = data['profile_image_url'] ?? null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data: $e';
        _loading = false;
      });
    }
  }

  Future<Uint8List?> pickProfileImage() async {
    if (kIsWeb) {
      // Web-specific logic (moved to a separate file to avoid import errors)
      return await pickImageWeb();
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        return await picked.readAsBytes();
      }
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() { _uploadingImage = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String? downloadUrl;
      final imageBytes = await pickProfileImage();
      if (imageBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
        final uploadTask = await ref.putData(imageBytes);
        downloadUrl = await uploadTask.ref.getDownloadURL();
      }
      if (downloadUrl != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profile_image_url': downloadUrl,
        });
        setState(() {
          profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() { _uploadingImage = false; });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'id_number': idNumber,
        'surname': surname,
        'first_name': firstName,
        'middle_name': middleName,
        'phone_number': phoneNumber,
        'address': address,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: const DashboardAppBar(),
        endDrawer: DashboardDrawerRight(onSelectScreen: (_) {}),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    return Scaffold(
      appBar: const DashboardAppBar(),
      endDrawer: DashboardDrawerRight(onSelectScreen: (_) {}),
      body: kIsWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
              ? NetworkImage(profileImageUrl!)
              : null,
          child: (profileImageUrl == null || profileImageUrl!.isEmpty)
              ? const Icon(Icons.person, size: 60)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _uploadingImage ? null : _pickAndUploadImage,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: _uploadingImage
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.edit, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Two-tone header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Edit ',
                            style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                          ),
                          TextSpan(
                            text: 'Profile',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Profile image with black border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: _buildProfileImage(context),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _styledTextField('ID Number', initialValue: idNumber, onChanged: (v) => idNumber = v),
                        _styledTextField('Surname', initialValue: surname, onChanged: (v) => surname = v),
                        _styledTextField('First Name', initialValue: firstName, onChanged: (v) => firstName = v),
                        _styledTextField('Middle Name', initialValue: middleName, onChanged: (v) => middleName = v),
                        _styledTextField('Phone Number', initialValue: phoneNumber, onChanged: (v) => phoneNumber = v),
                        _styledTextField('Address', initialValue: address, onChanged: (v) => address = v),
                        _styledTextField('Role', readOnly: true, initialValue: role ?? ''),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Color(0xFFFEC00F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                            onPressed: _saving ? null : _saveProfile,
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 8))],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 320,
                  maxWidth: 700,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Two-tone header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Edit ',
                              style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 32),
                            ),
                            TextSpan(
                              text: 'Profile',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: _buildProfileImage(context),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _styledTextField('ID Number', initialValue: idNumber, onChanged: (v) => idNumber = v),
                                _styledTextField('Surname', initialValue: surname, onChanged: (v) => surname = v),
                                _styledTextField('First Name', initialValue: firstName, onChanged: (v) => firstName = v),
                                _styledTextField('Middle Name', initialValue: middleName, onChanged: (v) => middleName = v),
                                _styledTextField('Phone Number', initialValue: phoneNumber, onChanged: (v) => phoneNumber = v),
                                _styledTextField('Address', initialValue: address, onChanged: (v) => address = v),
                                _styledTextField('Role', readOnly: true, initialValue: role ?? ''),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Color(0xFFFEC00F),
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      side: const BorderSide(color: Colors.black, width: 2),
                                    ),
                                    onPressed: _saving ? null : _saveProfile,
                                    child: _saving
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Save Changes'),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Styled input field for both web and mobile
  Widget _styledTextField(String label, {bool readOnly = false, String? initialValue, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> pickImageWeb() async {
    throw UnimplementedError('pickImageWeb is only available on web.');
  }
} 