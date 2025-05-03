import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String incidentId;
  final String typeId;
  final String location;
  final String status;
  final Timestamp reportedAt;
  final String? assignedTeam;               
  final List<String> dispatchedMembers;      

  IncidentModel({
    required this.incidentId,
    required this.typeId,
    required this.location,
    required this.status,
    required this.reportedAt,
    this.assignedTeam,
    this.dispatchedMembers = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> j, String id) => IncidentModel(
        incidentId: id,
        typeId: j['type'] as String,
        location: j['location'] as String,
        status: j['status'] as String,
        reportedAt: j['reported_at'] as Timestamp,
        assignedTeam: j['assigned_team'] as String?,
        dispatchedMembers: List<String>.from(j['dispatched_members'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'type': typeId,
        'location': location,
        'status': status,
        'reported_at': reportedAt,
        'assigned_team': assignedTeam,
        'dispatched_members': dispatchedMembers,
      };
}

