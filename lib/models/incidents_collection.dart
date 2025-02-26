import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String incidentId; // Auto-generated document ID
  final String reporterId; 
  final String type; // e.g., fire, medical emergency
  final String location; 
  final String status; // Pending, In Progress, Resolved
  final Timestamp reportedAt;
  final List<String> assignedTeams; 

  IncidentModel({
    required this.incidentId,
    required this.reporterId,
    required this.type,
    required this.location,
    required this.status,
    required this.reportedAt,
    required this.assignedTeams,
  });

  /// Convert Firestore document to Dart Object
  factory IncidentModel.fromJson(Map<String, dynamic> json, String documentId) {
    return IncidentModel(
      incidentId: documentId,
      reporterId: json['reporter_id'],
      type: json['type'],
      location: json['location'],
      status: json['status'],
      reportedAt: json['reported_at'],
      assignedTeams: List<String>.from(json['assigned_teams'] ?? []),
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'reporter_id': reporterId,
      'type': type,
      'location': location,
      'status': status,
      'reported_at': reportedAt,
      'assigned_teams': assignedTeams,
    };
  }
}
