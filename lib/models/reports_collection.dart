import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId; // Auto-generated document ID
  final String userId;
  final String type;
  final String description;
  final String location;
  final String status; 
  final Timestamp reportedAt; 
  final List<String> mediaUrls; // URLs of images/videos (if any)

  ReportModel({
    required this.reportId,
    required this.userId,
    required this.type,
    required this.description,
    required this.location,
    required this.status,
    required this.reportedAt,
    required this.mediaUrls,
  });

  /// Convert Firestore document to Dart Object
  factory ReportModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ReportModel(
      reportId: documentId,
      userId: json['user_id'],
      type: json['type'],
      description: json['description'],
      location: json['location'],
      status: json['status'],
      reportedAt: json['reported_at'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'description': description,
      'location': location,
      'status': status,
      'reported_at': reportedAt,
      'media_urls': mediaUrls,
    };
  }
}
