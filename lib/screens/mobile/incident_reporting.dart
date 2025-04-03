import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/report_incident_controller.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/image_input.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/widgets/mobile/incident_reporting/location_input.dart';

class IncidentReportingScreen extends StatefulWidget {
  const IncidentReportingScreen({super.key});

  @override
  State<IncidentReportingScreen> createState() => _IncidentReportingScreenState();
}

class _IncidentReportingScreenState extends State<IncidentReportingScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emergencyReportController = EmergencyReportController();
  String? _selectedIncidentType;
  List<File> _selectedMedia = [];
  bool _isLoading = false;

  final List<String> _incidentTypes = [
    'Fire',
    'Medical Emergency',
    'Suspicious Activity',
    'Theft',
    'Accident',
    'Other'
  ];

  Future<void> _confirmAndSaveIncident() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Report'),
        content: const Text(
          'Please ensure that the information you are submitting is accurate and truthful. Submitting false reports may result in disciplinary actions. Do you confirm that the details provided are correct?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _saveIncident();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveIncident() async {
    final enteredTitle = _titleController.text;
    final enteredLocation = _locationController.text;
    final enteredDescription = _descriptionController.text;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not authenticated.");
      return; // Stop the upload
    }
    print("User ID: ${user.uid}");

    print("Title: ${_titleController.text}");
    print("Location: ${_locationController.text}");
    print("Description: ${_descriptionController.text}");
    print("Incident Type: $_selectedIncidentType");
    print("Media Count: ${_selectedMedia.length}");

    if (_titleController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedIncidentType == null ||
        _selectedMedia.isEmpty) {
      print("Error: Input fields are empty.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> mediaUrls = [];

      for (File file in _selectedMedia) {
        final fileName = file.path.split('/').last;
        final ref = FirebaseStorage.instance.ref().child('incident_media/$fileName');
        print("Uploading file: ${file.path}");
        await ref.putFile(file);
        print("File uploaded, getting download URL");
        String downloadUrl = await ref.getDownloadURL();
        mediaUrls.add(downloadUrl);
        print("Download URL: $downloadUrl");
      }

      print("Saving incident to Firestore");
      await FirebaseFirestore.instance.collection('reports').add({
        'title': enteredTitle,
        'location': enteredLocation,
        'incident_type': _selectedIncidentType,
        'description': enteredDescription,
        'media_urls': mediaUrls,
        'timestamp': Timestamp.now(),
        'created_by': user.uid,
        'status': 'Pending',
      });
      print("Incident saved successfully");

      Navigator.of(context).pop();
      print("success 😍😍😍");
    } on FirebaseException catch (e) {
      print("Firebase Error saving incident: ${e.code} - ${e.message}");
    } catch (error) {
      print("General Error saving incident: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setScreen(String identifier) {
    if (identifier == 'filters') {
      // Handle filter selection
    } else {
      Navigator.of(context).pop(); // Close the drawer
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      drawer: DashboardDrawerLeft(onSelectScreen: _setScreen),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Incident Reporting Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.assignment, color: Colors.amber),
                SizedBox(width: 5),
                Text(
                  "Incident ",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Text(
                  "Reporting",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Icon(Icons.assignment, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 15),

            // Title Input
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.title, color: Colors.amber),
                labelText: 'Title:',
                border: OutlineInputBorder(),
              ),
              controller: _titleController,
            ),
            const SizedBox(height: 10),

            // Media Upload Section
            ImageInput(
              onPickMedia: (media) {
                setState(() {
                  _selectedMedia = media;
                });
              },
            ),
            const SizedBox(height: 15),

            // Location Input
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: Colors.amber),
                labelText: 'Location:',
                border: OutlineInputBorder(),
              ),
              controller: _locationController,
              readOnly: true,
            ),
            LocationInput(
              onSelectPlace: (selectedLocation) {
                _locationController.text = selectedLocation;
              },
            ),
            const SizedBox(height: 10),

            // Incident Type Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Incident Type',
                border: OutlineInputBorder(),
              ),
              value: _selectedIncidentType,
              items: _incidentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIncidentType = value;
                });
              },
            ),
            const SizedBox(height: 10),

            // Description Input
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description of the Incident:',
                border: OutlineInputBorder(),
              ),
              controller: _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Submit Button
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _confirmAndSaveIncident,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
