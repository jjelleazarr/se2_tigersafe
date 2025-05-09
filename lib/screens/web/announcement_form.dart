import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/announcements_controller.dart';
import 'package:se2_tigersafe/models/announcements_collection.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class AnnouncementFormScreen extends StatefulWidget {
  const AnnouncementFormScreen({super.key, this.initial});

  final AnnouncementModel? initial;

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  // ───────────────── controllers & state ──────────────────── //
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  final List<String> _allRoles = const [
    'public',
    'stakeholder',
    'command_center_operator',
    'command_center_admin',
  ];
  late List<String> _selectedRoles;

  String _announcementType = 'General';
  String _priority = 'Low';
  String? _attachmentUrl;
  bool get _isEdit => widget.initial != null;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Pre‑populate when editing
    if (_isEdit) {
      final m = widget.initial!;
      _titleCtrl = TextEditingController(text: m.title);
      _contentCtrl = TextEditingController(text: m.content);
      _announcementType = m.announcementType;
      _priority = m.priority;
      _selectedRoles = [...m.visibilityScope];
      _attachmentUrl = m.attachments;
    } else {
      _titleCtrl = TextEditingController();
      _contentCtrl = TextEditingController();
      _selectedRoles = ['public'];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ─────────────────── UI helpers ─────────────────────────── //

  Future<void> _pickAttachment() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null || res.files.isEmpty) return;
    final picked = res.files.single;

    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }
    if (bytes == null) return;

    final url = await AnnouncementController().uploadAttachment(bytes, picked.name);
    if (mounted) setState(() => _attachmentUrl = url);
  }

  void _toggleRole(String role) {
    setState(() {
      _selectedRoles.contains(role)
          ? _selectedRoles.remove(role)
          : _selectedRoles.add(role);
    });
  }

  Future<void> _handleSubmit() async {
    if (_saving) return;
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      // Resolve display name
      String displayName = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final u = userDoc.data();
        if (u != null) {
          displayName = [
            u['first_name'] ?? '',
            u['middle_name'] ?? '',
            u['surname'] ?? '',
          ].where((p) => p.toString().trim().isNotEmpty).join(' ').trim();
        }
      } catch (_) {}

      if (_isEdit) {
        // ============ UPDATE ============ //
        await AnnouncementController().updateAnnouncement(
          widget.initial!.announcementId,
          {
            'title'            : _titleCtrl.text.trim(),
            'content'          : _contentCtrl.text.trim(),
            'announcement_type': _announcementType,
            'priority'         : _priority,
            'visibility_scope' : _selectedRoles,
            'attachments'      : _attachmentUrl,
          },
        );
      } else {
        // ============ CREATE ============ //
        final model = AnnouncementModel(
          announcementId   : '',
          title            : _titleCtrl.text.trim(),
          content          : _contentCtrl.text.trim(),
          createdBy        : uid,
          announcementType : _announcementType,
          priority         : _priority,
          timestamp        : Timestamp.now(),
          visibilityScope  : _selectedRoles,
          attachments      : _attachmentUrl,
          creatorName      : displayName.isNotEmpty ? displayName : null,
          isHidden         : false,
        );
        await AnnouncementController().createAnnouncement(model);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ────────────────────── build ──────────────────────────── //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _isEdit ? 'Edit ' : 'Create ',
                        style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                      TextSpan(
                        text: 'Announcement',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title field
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content field
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Content / Description',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Type dropdown
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildDropdown(
                label: 'Type',
                value: _announcementType,
                items: const ['General', 'Hazard', 'Emergency Alert'],
                onChanged: (v) => setState(() => _announcementType = v!),
              ),
            ),
            const SizedBox(height: 12),

            // Priority dropdown
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildDropdown(
                label: 'Priority',
                value: _priority,
                items: const ['High', 'Medium', 'Low'],
                onChanged: (v) => setState(() => _priority = v!),
              ),
            ),
            const SizedBox(height: 12),

            // Visibility scope
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visibility Scope', 
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                    )
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allRoles.map((role) {
                      final selected = _selectedRoles.contains(role);
                      return FilterChip(
                        label: Text(role),
                        selected: selected,
                        selectedColor: Color(0xFFFEC00F).withOpacity(0.2),
                        checkmarkColor: Colors.black,
                        onSelected: (_) => _toggleRole(role),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Buttons row
            LayoutBuilder(
              builder: (context, constraints) {
                // If width is less than 600, stack buttons vertically
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Attachment button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: _pickAttachment,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Text(_attachmentUrl == null ? "Add " : "Change ",
                                style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              Text("Attachment",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              if (_attachmentUrl != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Submit button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: _saving ? null : _handleSubmit,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_saving)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEC00F)),
                                  ),
                                )
                              else
                                Icon(Icons.save, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Text(_isEdit ? "Update " : "Publish ",
                                style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              Text("Announcement",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                // Otherwise, keep buttons side by side
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Attachment button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: _pickAttachment,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(_attachmentUrl == null ? "Add " : "Change ",
                              style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            Text("Attachment",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            if (_attachmentUrl != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Submit button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: _saving ? null : _handleSubmit,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_saving)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEC00F)),
                                ),
                              )
                            else
                              Icon(Icons.save, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(_isEdit ? "Update " : "Publish ",
                              style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            Text("Announcement",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}