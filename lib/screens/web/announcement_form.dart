import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/announcements_controller.dart';
import 'package:se2_tigersafe/models/announcements_collection.dart';

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
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Announcement' : 'Create Announcement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Content / Description'),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Type',
              value: _announcementType,
              items: const ['General', 'Hazard', 'Emergency Alert'],
              onChanged: (v) => setState(() => _announcementType = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Priority',
              value: _priority,
              items: const ['High', 'Medium', 'Low'],
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 12),
            Text('Visibility Scope', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 6,
              children: _allRoles.map((role) {
                final selected = _selectedRoles.contains(role);
                return FilterChip(
                  label: Text(role),
                  selected: selected,
                  onSelected: (_) => _toggleRole(role),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickAttachment,
                  child: Text(_attachmentUrl == null ? 'Add Attachment' : 'Change Attachment'),
                ),
                if (_attachmentUrl != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline, size: 20),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _handleSubmit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEdit ? 'Update Announcement' : 'Publish Announcement'),
              ),
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
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}