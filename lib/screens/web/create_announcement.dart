
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/controllers/announcements_controller.dart';
import 'package:se2_tigersafe/models/announcements_collection.dart';
import 'package:se2_tigersafe/widgets/rightdrawer_black';

class CreateAnnouncementScreen extends StatefulWidget {
  @override
  _CreateAnnouncementScreenState createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedRoles = [];
  final _formKey = GlobalKey<FormState>();
  String? _announcementType;
  String? _priority;
  PlatformFile? _attachment;
  bool _isUploading = false;
  final List<String> _roles = [
    "stakeholder",
    "command_center",
    "emergency_response_team"
  ];

  final Map<String, String> _roleLabels = {
    "stakeholder": "Stakeholder",
    "command_center": "Command Center", // merged
    "emergency_response_team": "Emergency Response Team"
  };


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
    if (!_formKey.currentState!.validate() ||
      _selectedRoles.isEmpty ||
      _announcementType == null ||
      _priority == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    setState(() => _isUploading = true);
    final controller = AnnouncementController();

    String? attachmentUrl;
    if (_attachment != null) {
      attachmentUrl = await controller.uploadAttachment(_attachment!.bytes!, _attachment!.name);
    }

    final rawScope = _selectedRoles.expand((role) {
      if (role == 'command_center') {
        return ['command_center_operator', 'command_center_admin'];
      }
      return [role];
    }).toList();

    final announcement = AnnouncementModel(
      announcementId: '',
      title: _titleController.text,
      content: _descriptionController.text,
      createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user',
      announcementType: _announcementType!,
      priority: _priority!,
      timestamp: Timestamp.now(),
      visibilityScope: rawScope,
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
                child: Form(
                  key: _formKey,
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
                          ElevatedButton.icon(
                            onPressed: _toggleSelectAll,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                            icon: Icon(Icons.select_all),
                            label: Text(_allSelected() ? "Deselect All" : "Select All"),
                          ),
                          ..._roleLabels.entries.map((entry) {
                            return FilterChip(
                              label: Text(entry.value),
                              selected: _selectedRoles.contains(entry.key),
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _selectedRoles.add(entry.key) : _selectedRoles.remove(entry.key);
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: "Title",
                          prefixIcon: Icon(Icons.title),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          } else if (value.length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          labelText: "Description",
                          prefixIcon: Icon(Icons.description),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          } else if (value.length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_attachment != null)
                        Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.attach_file),
                            title: Text(_attachment!.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.refresh), onPressed: _pickFile),
                                IconButton(icon: Icon(Icons.close), onPressed: () => setState(() => _attachment = null)),
                              ],
                            ),
                          ),
                        )
                      else
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
                        decoration: InputDecoration(
                          labelText: "Announcement Type",
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: ["General", "Hazard", "Emergency Alert"]
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) => setState(() => _announcementType = value!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: "Priority",
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: _priorities
                            .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                            .toList(),
                        onChanged: (value) => setState(() => _priority = value!),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _submitAnnouncement,
                        icon: Icon(Icons.campaign),
                        label: _isUploading
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
      ),
    );
  }
}
