import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardDrawerRight extends StatelessWidget {
  const DashboardDrawerRight({super.key, required this.onSelectScreen});

  final void Function(String identifier) onSelectScreen;

  Future<List<Map<String, dynamic>>> fetchAnnouncementsForUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userRoles = List<String>.from(userSnap.data()?['roles'] ?? []);
    final snap = await FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).get();
    return snap.docs
        .where((doc) {
          final scope = List<String>.from(doc['visibility_scope'] ?? []);
          if (scope.contains('public')) return true;
          return userRoles.any((role) => scope.contains(role));
        })
        .map((doc) => doc.data())
        .toList();
  }

  @override
  Widget build(context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(width: 18),
                Text(
                  'Announcements',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAnnouncementsForUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final announcements = snapshot.data!;
                if (announcements.isEmpty) return const Center(child: Text('No announcements.', style: TextStyle(color: Colors.white)));
                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final ann = announcements[index];
                    return Card(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFFEC00F), width: 2),
                      ),
                      child: ListTile(
                        title: Text(
                          ann['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          (ann['timestamp'] as Timestamp?)?.toDate().toString() ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AnnouncementDetailDialog(announcement: ann),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementDetailDialog extends StatelessWidget {
  final Map<String, dynamic> announcement;
  const AnnouncementDetailDialog({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(announcement['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By: ${announcement['creator_name'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text(
              (announcement['timestamp'] as Timestamp?)?.toDate().toString() ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(announcement['content'] ?? ''),
            if (announcement['attachments'] != null && (announcement['attachments'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image.network(announcement['attachments']),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}