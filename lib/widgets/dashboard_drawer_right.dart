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
                  color: Color(0xFFFEC00F),
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
    final String? imageUrl = (announcement['attachments'] != null && (announcement['attachments'] as String).isNotEmpty)
        ? announcement['attachments'] as String
        : null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          width: 370,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'By: ${announcement['creator_name'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (announcement['timestamp'] as Timestamp?)?.toDate().toString() ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              announcement['content'] ?? '',
                              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFFFEC00F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('GOT IT'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}