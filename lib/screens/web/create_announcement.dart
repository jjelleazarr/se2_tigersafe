import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/controllers/announcements_controller.dart';
import 'package:se2_tigersafe/models/announcements_collection.dart';
import 'dart:io';

class CreateAnnouncementScreen extends StatefulWidget {
  @override
  _CreateAnnouncementScreenState createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedRoles = [];
  String? _announcementType;
  String? _priority;
  PlatformFile? _attachment;
  bool _isUploading = false;

  final List<String> _roles = ["Stakeholder", "Command Center Personnel", "Emergency Response Team"];
  final List<String> _priorities = ["High", "Medium", "Low"];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _attachment = result.files.single;
      });
    }
  }

  Future<void> _submitAnnouncement() async {
    if (_selectedRoles.isEmpty || _announcementType == null || _priority == null || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    setState(() => _isUploading = true);
    final controller = AnnouncementController();

    String? attachmentUrl;
    if (_attachment != null) {
      attachmentUrl = await controller.uploadAttachment(
        File(_attachment!.path!),
        _attachment!.name,
      );
    }

    final announcement = AnnouncementModel(
      announcementId: '', // Firestore will assign the ID
      title: _titleController.text,
      content: _descriptionController.text,
      createdBy: 'admin_id', // TODO: Replace with actual user ID
      announcementType: _announcementType!,
      priority: _priority!,
      timestamp: Timestamp.now(),
      visibilityScope: _selectedRoles,
      attachments: attachmentUrl,
    );

    await controller.createAnnouncement(announcement);
    setState(() => _isUploading = false);
    Navigator.pop(context);
  }

  bool _allSelected() => _selectedRoles.length == _roles.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected()) {
        _selectedRoles.clear();
      } else {
        _selectedRoles.clear();
        _selectedRoles.addAll(_roles);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withOpacity(0.9),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Create ',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            TextSpan(
                              text: 'Announcement',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(alignment: Alignment.centerLeft, child: Text("Select Visibility:", style: TextStyle(fontSize: 16))),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleSelectAll,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                          child: Text(_allSelected() ? "Deselect All" : "Select All"),
                        ),
                        ..._roles.map((role) {
                          final label = {
                            "Stakeholder": "Stakeholder",
                            "Command Center Personnel": "Command Center",
                            "Emergency Response Team": "Emergency Response Team",
                          }[role]!;
                          return FilterChip(
                            label: Text(label),
                            selected: _selectedRoles.contains(role),
                            onSelected: (selected) {
                              setState(() {
                                selected ? _selectedRoles.add(role) : _selectedRoles.remove(role);
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: "Announcement Title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(labelText: "Announcement Description"),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(Icons.attach_file),
                        label: Text("Add Attachment"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _announcementType,
                      decoration: InputDecoration(labelText: "Announcement Type"),
                      items: ["General", "Hazard", "Emergency Alert"]
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) => setState(() => _announcementType = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: InputDecoration(labelText: "Priority"),
                      items: _priorities
                          .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                          .toList(),
                      onChanged: (value) => setState(() => _priority = value!),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _submitAnnouncement,
                      child: _isUploading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Publish Announcement"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
