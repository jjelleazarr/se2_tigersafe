import 'dart:io';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/mobile/incident_reporting/image_input.dart';
import 'package:se2_tigersafe/widgets/mobile/incident_reporting/location_input.dart';
import 'package:se2_tigersafe/screens/mobile/confirm_incident_report.dart';

class IncidentReportingScreen extends StatefulWidget {
  const IncidentReportingScreen({super.key});

  @override
  State<IncidentReportingScreen> createState() =>
      _IncidentReportingScreenState();
}

class _IncidentReportingScreenState extends State<IncidentReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIncidentType;
  List<File> _selectedMedia = [];
  bool _isLoading = false;

  static const yellow = Color(0xFFFEC00F);

  final List<String> _incidentTypes = [
    'Suspicious Activity',
    'Unsafe Acts',
    'Minor Injury',
    'Obstruction',
    'Structural Damage',
    'Other'
  ];

  void _reviewSubmission() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text;
    final location = _locationController.text;
    final description = _descriptionController.text;

    if (_selectedIncidentType == null || _selectedMedia.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmIncidentReportScreen(
          title: title,
          location: location,
          incidentType: _selectedIncidentType!,
          description: description,
          media: _selectedMedia,

        ),
      ),
    );
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
            child: Form(
              key: _formKey,
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.assignment, color: yellow),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Title input
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title:',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Media input
                  ImageInput(onPickMedia: (media) {
                    setState(() => _selectedMedia = media);
                  }),
                  const SizedBox(height: 15),

                  // Location input (readonly)
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on, color: yellow),
                      labelText: 'Location:',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an incident type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Description input
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description of the Incident:',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _reviewSubmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'REVIEW SUBMISSION',
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
      ),
    );
  }
}
