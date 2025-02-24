import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcements_collection.dart';

class AnnouncementController {
  final CollectionReference announcementsRef =
      FirebaseFirestore.instance.collection('announcements');

  /// 🔹 **Fetch All Announcements**
  Future<List<AnnouncementModel>> getAllAnnouncements() async {
    try {
      QuerySnapshot snapshot = await announcementsRef.get();
      return snapshot.docs.map((doc) {
        return AnnouncementModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  /// 🔹 **Get a Specific Announcement by ID**
  Future<AnnouncementModel?> getAnnouncementById(String announcementId) async {
    try {
      DocumentSnapshot doc = await announcementsRef.doc(announcementId).get();
      if (doc.exists) {
        return AnnouncementModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching announcement: $e');
    }
    return null;
  }

  /// 🔹 **Add a New Announcement**
  Future<void> addAnnouncement(String title, String content, List<String> targetRoles) async {
    try {
      await announcementsRef.add({
        'title': title,
        'content': content,
        'created_at': Timestamp.now(),
        'target_roles': targetRoles, // List of role names allowed to see the announcement
      });
      print("✅ Announcement '$title' added successfully!");
    } catch (e) {
      print('Error adding announcement: $e');
    }
  }

  /// 🔹 **Update an Announcement**
  Future<void> updateAnnouncement(String announcementId, String newTitle, String newContent) async {
    try {
      await announcementsRef.doc(announcementId).update({
        'title': newTitle,
        'content': newContent,
      });
      print("✅ Announcement updated successfully!");
    } catch (e) {
      print('Error updating announcement: $e');
    }
  }

  /// 🔹 **Delete an Announcement**
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await announcementsRef.doc(announcementId).delete();
      print("✅ Announcement deleted successfully!");
    } catch (e) {
      print('Error deleting announcement: $e');
    }
  }
}
