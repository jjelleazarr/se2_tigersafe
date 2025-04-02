import 'package:cloud_firestore/cloud_firestore.dart';

class ERTMemberModel {
  final String memberId;
  final String userId;
  final String status; // Active, On-Duty, Off-Duty, Dispatched, etc.
  final String specialization; // medical, security, etc.
  final Timestamp createdAt;

  ERTMemberModel({
    required this.memberId,
    required this.userId,
    required this.status,
    required this.specialization,
    required this.createdAt,
  });

  factory ERTMemberModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ERTMemberModel(
      memberId: documentId,
      userId: json['user_id'],
      status: json['status'],
      specialization: json['specialization'] ?? 'general', // default fallback
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'specialization': specialization,
      'created_at': createdAt,
    };
  }
}

