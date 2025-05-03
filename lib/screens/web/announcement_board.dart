import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/announcements_collection.dart';
import 'announcement_form.dart';

class AnnouncementBoardScreen extends StatefulWidget {
  const AnnouncementBoardScreen({super.key});

  @override
  State<AnnouncementBoardScreen> createState() => _AnnouncementBoardScreenState();
}

class _AnnouncementBoardScreenState extends State<AnnouncementBoardScreen> {
  final DateFormat _fmt = DateFormat('MMM d, y  h:mm a');

  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedDoc;
  String? _resolvedAuthor;

  // ───────────────────────── helpers ────────────────────────── //

  void _selectDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    setState(() {
      _selectedDoc = doc;
      _resolvedAuthor = null;
    });

    // prefer cached name first
    final cached = doc.data()['creator_name'] as String?;
    if (cached != null && cached.isNotEmpty) {
      setState(() => _resolvedAuthor = cached);
      return;
    }

    // fallback to /users lookup
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.data()['created_by'])
          .get();
      final u = snap.data();
      if (u != null) {
        final name = [u['first_name'] ?? '', u['middle_name'] ?? '', u['surname'] ?? '']
            .where((p) => p.toString().trim().isNotEmpty)
            .join(' ')
            .trim();
        if (mounted) setState(() => _resolvedAuthor = name);
      }
    } catch (_) {}
  }

  void _clearSelection() => setState(() => _selectedDoc = null);

  // ───────────────────────── actions ────────────────────────── //

  Future<void> _toggleHidden() async {
    if (_selectedDoc == null) return;
    final hidden = _selectedDoc!.data()['is_hidden'] == true;
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(_selectedDoc!.id)
        .update({'is_hidden': !hidden});
  }

  void _handleEdit() {
    if (_selectedDoc == null) return;
    final model = AnnouncementModel.fromJson(_selectedDoc!.data(), _selectedDoc!.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnnouncementFormScreen(initial: model)),
    );
  }

  Future<void> _handleDelete() async {
    if (_selectedDoc == null) return;
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(_selectedDoc!.id)
        .delete();
    _clearSelection();
  }

  // ───────────────────── card builder ──────────────────────── //

  Widget _buildPriorityChip(String? priority) {
    final p = (priority ?? 'Low').toLowerCase();
    final c = p == 'high'
        ? Colors.red.shade700
        : p == 'medium'
            ? Colors.orange.shade700
            : Colors.green.shade700;
    return Chip(
      label: Text(p[0].toUpperCase() + p.substring(1)),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: TextStyle(color: c),
    );
  }

  Widget _buildAnnouncementCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isHidden = data['is_hidden'] == true;

    return Card(
      color: isHidden ? Colors.grey.shade200 : null,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: isHidden ? const Icon(Icons.visibility_off, size: 20) : null,
        title: Text(
          data['title'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isHidden ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
        subtitle: Text(_fmt.format((data['timestamp'] as Timestamp).toDate())),
        trailing: _buildPriorityChip(data['priority'] as String?),
        selected: _selectedDoc?.id == doc.id,
        onTap: () => _selectDocument(doc),
      ),
    );
  }

  // ───────────────────── attachment helpers ────────────────── //

  Widget _buildImage(String url) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Image failed to load'),
          ),
        ),
      );

  Widget _buildAttachmentPreview(String? attachment) {
    if (attachment == null || attachment.isEmpty) return const SizedBox.shrink();

    final uri = Uri.parse(attachment);
    final path = uri.path.toLowerCase();
    final isImg = path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');

    if (isImg) {
      // gs:// Storage reference – convert to https
      if (attachment.startsWith('gs://')) {
        return FutureBuilder<String>(
          future: FirebaseStorage.instance.refFromURL(attachment).getDownloadURL(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              );
            }
            return _buildImage(snap.data!);
          },
        );
      }
      return _buildImage(attachment);
    }

    // non‑image → link
    final fileName = Uri.decodeComponent(uri.pathSegments.last);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: TextButton.icon(
        icon: const Icon(Icons.attach_file),
        label: Text(fileName),
        onPressed: () async {
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to open attachment')),
              );
            }
          }
        },
      ),
    );
  }

  // ───────────────────── detail pane ───────────────────────── //

  Widget _buildDetailPane() {
    if (_selectedDoc == null) {
      return const Center(child: Text('Select an announcement to view'));
    }

    final data = _selectedDoc!.data();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(_resolvedAuthor ?? '…', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: 12),
              Text(
                _fmt.format((data['timestamp'] as Timestamp).toDate()),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const Divider(height: 24),
          Text(data['content'] ?? ''),
          _buildAttachmentPreview(data['attachments'] as String?),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: Icon(data['is_hidden'] == true ? Icons.visibility_off : Icons.visibility),
                tooltip: data['is_hidden'] == true ? 'Unhide' : 'Hide',
                onPressed: _toggleHidden,
              ),
              IconButton(icon: const Icon(Icons.edit), onPressed: _handleEdit),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _handleDelete),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────── main build ───────────────────────── //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcement Board')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No announcements'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _buildAnnouncementCard(docs[i]),
                );
              },
            ),
          ),
          Expanded(flex: 3, child: _buildDetailPane()),
        ],
      ),
    );
  }
}