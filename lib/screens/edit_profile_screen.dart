import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:io';
// For web image picking
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:image_picker/image_picker.dart';

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

  Future<void> _pickAndUploadImage() async {
    setState(() { _uploadingImage = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String? downloadUrl;
      if (kIsWeb) {
        // Web: use html FileUploadInputElement
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();
        await uploadInput.onChange.first;
        final file = uploadInput.files?.first;
        if (file != null) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoad.first;
          final data = reader.result as Uint8List;
          final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
          final uploadTask = await ref.putData(data, SettableMetadata(contentType: file.type));
          downloadUrl = await uploadTask.ref.getDownloadURL();
        }
      } else {
        // Mobile: use image_picker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
          final uploadTask = await ref.putFile(file);
          downloadUrl = await uploadTask.ref.getDownloadURL();
        }
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Image.asset('assets/UST_LOGO_NO_TEXT.png', height: 40),
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset('assets/UST_LOGO_NO_TEXT.png', height: 40),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProfileImage(context),
            const SizedBox(height: 24),
            _buildTextField('ID Number', initialValue: idNumber, onChanged: (v) => idNumber = v),
            _buildTextField('Surname', initialValue: surname, onChanged: (v) => surname = v),
            _buildTextField('First Name', initialValue: firstName, onChanged: (v) => firstName = v),
            _buildTextField('Middle Name', initialValue: middleName, onChanged: (v) => middleName = v),
            _buildTextField('Phone Number', initialValue: phoneNumber, onChanged: (v) => phoneNumber = v),
            _buildTextField('Address', initialValue: address, onChanged: (v) => address = v),
            _buildTextField('Role', readOnly: true, initialValue: role ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              const Divider(thickness: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildProfileImage(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField('ID Number', initialValue: idNumber, onChanged: (v) => idNumber = v)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Phone Number', initialValue: phoneNumber, onChanged: (v) => phoneNumber = v)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Surname', initialValue: surname, onChanged: (v) => surname = v)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Address', initialValue: address, onChanged: (v) => address = v)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('First Name', initialValue: firstName, onChanged: (v) => firstName = v)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Role', readOnly: true, initialValue: role ?? '')),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Middle Name', initialValue: middleName, onChanged: (v) => middleName = v)),
                            const SizedBox(width: 24),
                            Expanded(child: Container()),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _saving ? null : _saveProfile,
                              child: _saving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {bool readOnly = false, String? initialValue, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }
} 