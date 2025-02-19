import 'package:cloud_firestore/cloud_firestore.dart';

class ERTMemberModel {
  final String memberId; // Auto-generated document ID
  final String userId; 
  final String teamId;
  final String status; // Active, On-Duty, Off-Duty
  final Timestamp createdAt; // Timestamp of when the member was added

  ERTMemberModel({
    required this.memberId,
    required this.userId,
    required this.teamId,
    required this.status,
    required this.createdAt,
  });

  /// Convert Firestore document to Dart Object
  factory ERTMemberModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ERTMemberModel(
      memberId: documentId,
      userId: json['user_id'],
      teamId: json['team_id'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'team_id': teamId,
      'status': status,
      'created_at': createdAt,
    };
  }
}
