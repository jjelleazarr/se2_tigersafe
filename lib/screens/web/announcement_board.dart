import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcements_collection.dart';

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

    // Attempt to use cached name first
    final cached = doc.data()['creator_name'] as String?;
    if (cached != null && cached.isNotEmpty) {
      setState(() => _resolvedAuthor = cached);
      return;
    }

    // Fallback lookup from /users/{uid}
    final uid = doc.data()['created_by'];
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final u = snap.data();
      if (u != null) {
        final name = [
          u['first_name'] ?? '',
          u['middle_name'] ?? '',
          u['surname'] ?? '',
        ].where((p) => p.toString().trim().isNotEmpty).join(' ').trim();
        if (mounted) setState(() => _resolvedAuthor = name);
      }
    } catch (_) {
      // silently ignore
    }
  }

  void _clearSelection() => setState(() => _selectedDoc = null);

  // ───────────────────────── actions ────────────────────────── //

  Future<void> _toggleHidden() async {
    if (_selectedDoc == null) return;
    final current = _selectedDoc!.data()['is_hidden'] == true;
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(_selectedDoc!.id)
        .update({'is_hidden': !current});
  }

  void _handleEdit() {
    if (_selectedDoc == null) return;
    final model = AnnouncementModel.fromJson(_selectedDoc!.data(), _selectedDoc!.id);
    Navigator.pushNamed(context, '/announcement_form', arguments: model);
  }

  Future<void> _handleDelete() async {
    if (_selectedDoc == null) return;
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(_selectedDoc!.id)
        .delete();
    _clearSelection();
  }

  // ───────────────────────── build card  ────────────────────── //

  Widget _buildAnnouncementCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final priority = data['priority'] as String? ?? 'Low';
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red.shade700;
        break;
      case 'medium':
        priorityColor = Colors.orange.shade700;
        break;
      default:
        priorityColor = Colors.green.shade700;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(data['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(_fmt.format((data['timestamp'] as Timestamp).toDate())),
        trailing: Chip(label: Text(priority), backgroundColor: priorityColor.withOpacity(0.15), labelStyle: TextStyle(color: priorityColor)),
        selected: _selectedDoc?.id == doc.id,
        onTap: () => _selectDocument(doc),
      ),
    );
  }

  // ───────────────────────── detail pane  ───────────────────── //

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
              Text(_fmt.format((data['timestamp'] as Timestamp).toDate()), style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const Divider(height: 24),
          Text(data['content'] ?? ''),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: Icon(data['is_hidden'] == true ? Icons.visibility_off : Icons.visibility),
                onPressed: _toggleHidden,
                tooltip: data['is_hidden'] == true ? 'Unhide' : 'Hide',
              ),
              IconButton(icon: const Icon(Icons.edit), onPressed: _handleEdit),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _handleDelete),
            ],
          )
        ],
      ),
    );
  }

  // ───────────────────────── main build  ───────────────────── //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcement Board')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/announcement_form'),
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
      ),
      body: Row(
        children: [
          // —— Left: list —— //
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .where('is_hidden', isEqualTo: false)
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
                  itemBuilder: (ctx, i) => _buildAnnouncementCard(docs[i]),
                );
              },
            ),
          ),
          // —— Right: details —— //
          Expanded(flex: 3, child: _buildDetailPane()),
        ],
      ),
    );
  }
}
