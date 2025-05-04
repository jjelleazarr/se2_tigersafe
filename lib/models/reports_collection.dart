import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String incidentId;            
  final String userId;
  final String typeId;                
  final String description;
  final String location;
  final String status;
  final String? resolvedBy;           
  final Timestamp reportedAt;
  final List<String> mediaUrls;
  final String? exportUrl;            

  ReportModel({
    required this.reportId,
    required this.incidentId,
    required this.userId,
    required this.typeId,
    required this.description,
    required this.location,
    required this.status,
    required this.reportedAt,
    this.resolvedBy,
    this.mediaUrls = const [],
    this.exportUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> j, String id) => ReportModel(
        reportId: id,
        incidentId: j['incident_id'] as String,
        userId: j['user_id'] as String,
        typeId: j['type'] as String,
        description: j['description'] as String,
        location: j['location'] as String,
        status: j['status'] as String,
        reportedAt: j['reported_at'] as Timestamp,
        resolvedBy: j['resolved_by'] as String?,
        mediaUrls: List<String>.from(j['media_urls'] ?? []),
        exportUrl: j['export_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'incident_id': incidentId,
        'user_id': userId,
        'type': typeId,
        'description': description,
        'location': location,
        'status': status,
        'reported_at': reportedAt,
        'resolved_by': resolvedBy,
        'media_urls': mediaUrls,
        'export_url': exportUrl,
      };
}
