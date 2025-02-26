import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestModel {
  final String requestId; // Auto-generated document ID
  final String userId; // Reference to the user requesting verification
  final String roleRequested; // Role being requested ("Emergency Response Team", "Command Center Personnel")
  final String status; // Pending, Approved, Denied
  final String? adminId; // ID of the admin who reviewed the request
  final Timestamp createdAt; // Timestamp
  final Timestamp? reviewedAt; // Timestamp when the request was reviewed

  VerificationRequestModel({
    required this.requestId,
    required this.userId,
    required this.roleRequested,
    required this.status,
    this.adminId,
    required this.createdAt,
    this.reviewedAt,
  });

  /// Convert Firestore document to Dart Object
  factory VerificationRequestModel.fromJson(Map<String, dynamic> json, String documentId) {
    return VerificationRequestModel(
      requestId: documentId,
      userId: json['user_id'],
      roleRequested: json['role_requested'],
      status: json['status'],
      adminId: json['admin_id'],
      createdAt: json['created_at'],
      reviewedAt: json['reviewed_at'],
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role_requested': roleRequested,
      'status': status,
      'admin_id': adminId,
      'created_at': createdAt,
      'reviewed_at': reviewedAt,
    };
  }
}
