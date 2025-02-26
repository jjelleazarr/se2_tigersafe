import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String announcementId; // Auto-generated document ID
  final String title; 
  final String content; 
  final Timestamp createdAt;
  final List<String> targetRoles;

  AnnouncementModel({
    required this.announcementId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.targetRoles,
  });

  /// Convert Firestore document to Dart Object
  factory AnnouncementModel.fromJson(Map<String, dynamic> json, String documentId) {
    return AnnouncementModel(
      announcementId: documentId,
      title: json['title'],
      content: json['content'],
      createdAt: json['created_at'],
      targetRoles: List<String>.from(json['target_roles'] ?? []),
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'created_at': createdAt,
      'target_roles': targetRoles,
    };
  }
}
