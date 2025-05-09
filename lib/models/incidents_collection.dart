import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String incidentId;
  final String title;
  final String type;
  final List<String> locations;
  final String status;
  final Timestamp reportedAt;
  final Timestamp? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final List<String> connectedReports;
  final List<String> dispatchedMembers;
  final List<String> specializations;
  final String description;
  final List<Map<String, dynamic>> attachments;

  IncidentModel({
    required this.incidentId,
    required this.title,
    required this.type,
    required this.locations,
    required this.status,
    required this.reportedAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    required this.connectedReports,
    required this.dispatchedMembers,
    required this.specializations,
    required this.description,
    this.attachments = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> j, String id) => IncidentModel(
        incidentId: id,
        title: j['title'] as String? ?? '',
        type: j['type'] as String,
        locations: List<String>.from(j['locations'] ?? []),
        status: j['status'] as String,
        reportedAt: j['reported_at'] as Timestamp,
        updatedAt: j['updated_at'] as Timestamp?,
        createdBy: j['created_by'] as String,
        updatedBy: j['updated_by'] as String?,
        connectedReports: List<String>.from(j['connected_reports'] ?? []),
        dispatchedMembers: List<String>.from(j['dispatched_members'] ?? []),
        specializations: List<String>.from(j['specializations'] ?? []),
        description: j['description'] as String? ?? '',
        attachments: (j['attachments'] as List?)?.map((a) => Map<String, dynamic>.from(a)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'locations': locations,
        'status': status,
        'reported_at': reportedAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        'created_by': createdBy,
        if (updatedBy != null) 'updated_by': updatedBy,
        'connected_reports': connectedReports,
        'dispatched_members': dispatchedMembers,
        'specializations': specializations,
        'description': description,
        if (attachments.isNotEmpty) 'attachments': attachments,
      };
}

