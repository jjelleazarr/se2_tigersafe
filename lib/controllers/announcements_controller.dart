import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/announcements_collection.dart';

class AnnouncementController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Create a new announcement
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestore.collection('announcements').add(announcement.toJson());
      print("Announcement created.");
    } catch (e) {
      print("Error creating announcement: $e");
      rethrow;
    }
  }

  /// Update an existing announcement by ID
  Future<void> updateAnnouncement(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('announcements').doc(id).update(updates);
      print("Announcement updated.");
    } catch (e) {
      print("Error updating announcement: $e");
      rethrow;
    }
  }

  /// Delete an announcement by ID
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
      print("Announcement deleted.");
    } catch (e) {
      print("Error deleting announcement: $e");
      rethrow;
    }
  }

  /// Upload an attachment and return its URL
  Future<String> uploadAttachment(File file, String fileName) async {
    try {
      final ref = _storage.ref().child('announcement_attachments/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      print("📎 Attachment uploaded.");
      return url;
    } catch (e) {
      print("Error uploading attachment: $e");
      rethrow;
    }
  }
}
