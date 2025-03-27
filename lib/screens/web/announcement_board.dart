import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementBoardScreen extends StatelessWidget {
  final priorityColors = {
    "High": Colors.red,
    "Medium": Colors.orange,
    "Low": Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Announcements")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('priority', descending: true)
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
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              final title = data['title'] ?? 'No Title';
              final content = data['content'] ?? '';
              final type = data['announcement_type'] ?? 'General';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final priority = data['priority'] ?? 'Low';
              final hasAttachment = data.containsKey('attachments');

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("[$type] $title", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag, color: priorityColors[priority] ?? Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text("Priority: $priority"),
                          Spacer(),
                          if (timestamp != null)
                            Text(DateFormat.yMMMd().add_jm().format(timestamp), style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(content.length > 100 ? content.substring(0, 100) + '...' : content),
                      if (hasAttachment)
                        Row(
                          children: [
                            Icon(Icons.attachment, size: 16),
                            SizedBox(width: 4),
                            Text("Attachment Available", style: TextStyle(fontSize: 12))
                          ],
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility),
                        onPressed: () {
                          // TODO: View details
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // TODO: Navigate to edit screen or show dialog
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
