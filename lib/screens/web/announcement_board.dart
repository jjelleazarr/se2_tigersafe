import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/announcements_collection.dart';
import 'announcement_form.dart';
import '../../widgets/dashboard_appbar.dart';

class AnnouncementBoardScreen extends StatefulWidget {
  const AnnouncementBoardScreen({super.key});

  @override
  State<AnnouncementBoardScreen> createState() => _AnnouncementBoardScreenState();
}

class _AnnouncementBoardScreenState extends State<AnnouncementBoardScreen> {
  final DateFormat _fmt = DateFormat('MMM d, y  h:mm a');

  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedDoc;
  String? _resolvedAuthor;
  
  // Add pagination state
  int _currentPage = 0;
  final int _rowsPerPage = 15;
  bool _isAscending = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final snap = await FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('timestamp', descending: !_isAscending)
        .get();
    setState(() {
      _announcements = snap.docs;
      _currentPage = 0;
    });
  }

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

  Widget _buildPriorityChip(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          priority,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isHidden = data['is_hidden'] == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      color: isHidden ? Colors.grey.shade200 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: isHidden ? const Icon(Icons.visibility_off, size: 20) : null,
        title: Text(
          data['title'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          _fmt.format((data['timestamp'] as Timestamp).toDate()),
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: _buildPriorityChip(data['priority'] as String),
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
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData) {
              return const Text('Image failed to load');
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

  Widget _buildDetailPane({required bool showActionButtons}) {
    if (_selectedDoc == null) {
      return const Center(child: Text('Select an announcement to view'));
    }

    final data = _selectedDoc!.data();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Announcement ',
                    style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  TextSpan(
                    text: 'Details',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Basic Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildInfoRow('Title', data['title'] ?? ''),
                  _buildInfoRow('Author', _resolvedAuthor ?? '…'),
                  _buildInfoRow('Posted At', _fmt.format((data['timestamp'] as Timestamp).toDate())),
                  _buildInfoRow('Priority', data['priority'] ?? 'Low', valueColor: _getPriorityColor(data['priority'] as String?)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 12),
                  Text(
                    data['content'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  _buildAttachmentPreview(data['attachments'] as String?),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showActionButtons)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: _toggleHidden,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data['is_hidden'] == true ? Icons.visibility_off : Icons.visibility,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['is_hidden'] == true ? "Unhide " : "Hide ",
                          style: const TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          "Announcement",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showActionButtons)
                const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: _handleEdit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text("Edit ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Announcement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: _handleDelete,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.delete, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text("Delete ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Announcement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    final p = (priority ?? 'Low').toLowerCase();
    return p == 'high'
        ? Colors.red.shade700
        : p == 'medium'
            ? Colors.orange.shade700
            : Colors.green.shade700;
  }

  Widget _buildAnnouncementsTable({
    required bool showSort, 
    required bool showPriority,
    required bool showNewButton,
    required bool showHeader,
  }) {
    int totalPages = (_announcements.length / _rowsPerPage).ceil();
    int start = _currentPage * _rowsPerPage;
    int end = (_currentPage + 1) * _rowsPerPage;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pageItems = _announcements.sublist(
      start,
      end > _announcements.length ? _announcements.length : end,
    );

    return Column(
      children: [
        // Header with title and sort controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showHeader)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'All ',
                          style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                        TextSpan(
                          text: 'Announcements',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showSort)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Sort ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text("by date: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      DropdownButton<bool>(
                        dropdownColor: Colors.white,
                        value: _isAscending,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text("Ascending", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text("Descending", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _isAscending = value!;
                            _fetchAnnouncements();
                          });
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text('Title', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      const Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      if (showPriority)
                        const Expanded(flex: 2, child: Text('Priority', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                // Table Body
                Expanded(
                  child: ListView.builder(
                    itemCount: pageItems.length,
                    itemBuilder: (context, index) {
                      final doc = pageItems[index];
                      final data = doc.data();
                      final isHidden = data['is_hidden'] == true;
                      
                      return InkWell(
                        onTap: () => _selectDocument(doc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: const Border(bottom: BorderSide(color: Colors.black12)),
                            color: _selectedDoc?.id == doc.id ? Colors.grey[100] : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    if (isHidden) 
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(Icons.visibility_off, size: 16, color: Colors.grey),
                                      ),
                                    Expanded(
                                      child: Text(
                                        data['title'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _fmt.format((data['timestamp'] as Timestamp).toDate()),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                              if (showPriority)
                                Expanded(
                                  flex: 2,
                                  child: _buildPriorityChip(data['priority'] as String),
                                ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Pagination
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // New Announcement Button
                      if (showNewButton)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AnnouncementFormScreen()),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text("New ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Announcement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(width: 8),
                                Icon(Icons.add, color: Color(0xFFFEC00F), size: 16),
                              ],
                            ),
                          ),
                        ),
                      // Pagination Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Text('Page ${_currentPage + 1} of $totalPages'),
                          IconButton(
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showSort = screenWidth >= 1500;
    final bool showPriority = screenWidth >= 1000;
    final bool showLeftPane = screenWidth >= 800;
    final bool showActionButtons = screenWidth >= 1000;
    final bool showHeader = screenWidth >= 900;

    return Scaffold(
      appBar: const DashboardAppBar(),
      body: Row(
        children: [
          if (showLeftPane)
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                child: _buildAnnouncementsTable(
                  showSort: showSort, 
                  showPriority: showPriority,
                  showNewButton: showActionButtons,
                  showHeader: showHeader,
                ),
              ),
            ),
          Expanded(
            flex: showLeftPane ? 3 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: showLeftPane ? const Border(
                  left: BorderSide(color: Colors.black, width: 1),
                ) : null,
              ),
              child: _buildDetailPane(showActionButtons: showActionButtons),
            ),
          ),
        ],
      ),
    );
  }
}