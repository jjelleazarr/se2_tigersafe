import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String announcementId;
  final String title;
  final String content;
  final String createdBy;
  final String announcementType;
  final String priority;
  final Timestamp timestamp;
  final List<String> visibilityScope;
  final String? attachments;

  AnnouncementModel({
    required this.announcementId,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.announcementType,
    required this.priority,
    required this.timestamp,
    required this.visibilityScope,
    this.attachments,
  });

  /// Convert Firestore document to Dart Object
  factory AnnouncementModel.fromJson(Map<String, dynamic> json, String documentId) {
    return AnnouncementModel(
      announcementId: documentId,
      title: json['title'],
      content: json['content'],
      createdBy: json['created_by'],
      announcementType: json['announcement_type'],
      priority: json['priority'],
      timestamp: json['timestamp'],
      visibilityScope: List<String>.from(json['visibility_scope'] ?? []),
      attachments: json['attachments'],
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'created_by': createdBy,
      'announcement_type': announcementType,
      'priority': priority,
      'timestamp': timestamp,
      'visibility_scope': visibilityScope,
      if (attachments != null) 'attachments': attachments,
    };
  }
}
