import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class AnnouncementBoardScreen extends StatefulWidget {
  @override
  _AnnouncementBoardScreenState createState() => _AnnouncementBoardScreenState();
}

class _AnnouncementBoardScreenState extends State<AnnouncementBoardScreen> {
  final priorityColors = {
    "High": Colors.red,
    "Medium": Colors.orange,
    "Low": Colors.grey,
  };

  DocumentSnapshot? _selectedAnnouncement;

  void _selectAnnouncement(DocumentSnapshot doc) {
    setState(() {
      _selectedAnnouncement = doc;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAnnouncement = null;
    });
  }

  Widget _buildAnnouncementCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'No Title';
    final content = data['content'] ?? '';
    final type = data['announcement_type'] ?? 'General';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final priority = data['priority'] ?? 'Low';
    final attachmentUrl = data['attachments'];

    return InkWell(
      onTap: () => _selectAnnouncement(doc),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachmentUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  attachmentUrl,
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image, color: Colors.grey[700], size: 48),
                  ),
                )
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("[$type] $title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(content.length > 100 ? content.substring(0, 100) + '...' : content),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _selectAnnouncement(doc),
                    child: Text("Read More", style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedAnnouncement == null) return SizedBox();
    final data = _selectedAnnouncement!.data() as Map<String, dynamic>;
    final attachmentUrl = data['attachments'];
    return Expanded(
      flex: 3,
      child: Container(
        margin: EdgeInsets.only(left: 16),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "[${data['announcement_type']}] ${data['title']}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close), onPressed: _clearSelection),
                ],
              ),
              const SizedBox(height: 12),
              Chip(label: Text("Priority: ${data['priority']}")),
              const SizedBox(height: 12),
              if (attachmentUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    attachmentUrl,
                    fit: BoxFit.cover,
                    height: 150,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: Colors.grey[700], size: 48),
                    ),
                  )
                ),
              const SizedBox(height: 12),
              Text(data['content'], style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              if (data['visibility_scope'] != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Visible To:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...List<String>.from(data['visibility_scope']).map((role) => Text("- $role")),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(icon: Icon(Icons.visibility), onPressed: () {}),
                  IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                  IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () async {
                    await FirebaseFirestore.instance.collection('announcements').doc(_selectedAnnouncement!.id).delete();
                    _clearSelection();
                  }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Row(
              children: [
                Expanded(
                  flex: _selectedAnnouncement == null ? 1 : 2,
                  child: Column(
                    children: [
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Announcement ',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              TextSpan(
                                text: 'Board',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('announcements')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No announcements available."));
                            }

                            final docs = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) => _buildAnnouncementCard(docs[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedAnnouncement != null) _buildDetailPanel(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create_announcement');
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("New Announcement", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber[800],
      ),
    );
  }
}
