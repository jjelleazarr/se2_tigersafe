import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/mobile/incident_reporting/image_input.dart';
import 'package:se2_tigersafe/widgets/mobile/incident_reporting/location_input.dart';

class IncidentReportingScreen extends StatefulWidget {
  const IncidentReportingScreen({super.key});

  @override
  State<IncidentReportingScreen> createState() =>
      _IncidentReportingScreenState();
}

class _IncidentReportingScreenState extends State<IncidentReportingScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIncidentType;
  List<File> _selectedMedia = [];
  bool _isLoading = false;

  static const yellow = Color(0xFFFEC00F);

  final List<String> _incidentTypes = [
    'Fire',
    'Medical Emergency',
    'Suspicious Activity',
    'Theft',
    'Accident',
    'Other'
  ];

  Future<void> _saveIncident() async {
    final title = _titleController.text;
    final location = _locationController.text;
    final description = _descriptionController.text;

    if (title.isEmpty ||
        location.isEmpty ||
        description.isEmpty ||
        _selectedIncidentType == null ||
        _selectedMedia.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> mediaUrls = [];

      for (final file in _selectedMedia) {
        final fileName = file.path.split('/').last;
        final ref =
            FirebaseStorage.instance.ref().child('incident_media/$fileName');
        await ref.putFile(file);
        mediaUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instance.collection('incidents').add({
        'title': title,
        'location': location,
        'incidentType': _selectedIncidentType,
        'description': description,
        'mediaUrls': mediaUrls,
        'timestamp': Timestamp.now(),
      });

      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving incident: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setScreen(String identifier) {
    if (identifier != 'filters') Navigator.of(context).pop();
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
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.assignment, color: yellow),
                    SizedBox(width: 5),
                    Text(
                      "Incident ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: yellow,
                      ),
                    ),
                    Text(
                      "Reporting",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.assignment, color: yellow),
                  ],
                ),
                const SizedBox(height: 15),

                // Media input
                ImageInput(onPickMedia: (media) {
                  setState(() => _selectedMedia = media);
                }),
                const SizedBox(height: 15),

                // Location input (readonly)
                TextField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: yellow),
                    labelText: 'Location:',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Location picker map
                LocationInput(onSelectPlace: (selectedLocation) {
                  _locationController.text = selectedLocation;
                }),
                const SizedBox(height: 15),

                // Dropdown for incident type
                DropdownButtonFormField<String>(
                  value: _selectedIncidentType,
                  decoration: const InputDecoration(
                    labelText: 'Incident Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _incidentTypes
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedIncidentType = value),
                ),
                const SizedBox(height: 15),

                // Description input
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description of the Incident:',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveIncident,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'SUBMIT',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
