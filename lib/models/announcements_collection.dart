import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String announcementId;

  // ——————————————————— visible metadata ———————————————————— //
  final String title;
  final String content;
  final String createdBy;            // UID of poster
  final String announcementType;     // e.g. "Hazard", "General"
  final String priority;             // "High" | "Medium" | "Low"
  final Timestamp timestamp;         // serverTimestamp()
  final List<String> visibilityScope;// allowed reader roles
  final String? attachments;         // gs:// or https:// link (nullable)
  final String? creatorName;         // cached "First M. Last"
  final bool isHidden;               // soft‑delete flag (default false)

  const AnnouncementModel({
    required this.announcementId,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.announcementType,
    required this.priority,
    required this.timestamp,
    required this.visibilityScope,
    this.attachments,
    this.creatorName,
    this.isHidden = false,
  });

  // ————————————————— factory helpers ———————————————————— //

  factory AnnouncementModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return AnnouncementModel(
      announcementId: id,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      announcementType: json['announcement_type'] as String? ?? 'General',
      priority: json['priority'] as String? ?? 'Low',
      timestamp: json['timestamp'] as Timestamp? ?? Timestamp.now(),
      visibilityScope: List<String>.from(json['visibility_scope'] ?? <String>[]),
      attachments: json['attachments'] as String?,
      creatorName: json['creator_name'] as String?,
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title'            : title,
      'content'          : content,
      'created_by'       : createdBy,
      'announcement_type': announcementType,
      'priority'         : priority,
      'timestamp'        : timestamp,
      'visibility_scope' : visibilityScope,
      if (attachments  != null) 'attachments'  : attachments,
      if (creatorName  != null) 'creator_name' : creatorName,
      'is_hidden'       : isHidden,
    };
  }

  /// Convenience method for immutability‑friendly updates.
  AnnouncementModel copyWith({
    String? title,
    String? content,
    String? announcementType,
    String? priority,
    List<String>? visibilityScope,
    String? attachments,
    String? creatorName,
    bool? isHidden,
  }) {
    return AnnouncementModel(
      announcementId : announcementId,
      title          : title ?? this.title,
      content        : content ?? this.content,
      createdBy      : createdBy,
      announcementType: announcementType ?? this.announcementType,
      priority       : priority ?? this.priority,
      timestamp      : timestamp, // immutable
      visibilityScope: visibilityScope ?? this.visibilityScope,
      attachments    : attachments ?? this.attachments,
      creatorName    : creatorName ?? this.creatorName,
      isHidden       : isHidden ?? this.isHidden,
    );
  }

  /// An empty placeholder – handy for forms before data is loaded.
  static AnnouncementModel empty() => AnnouncementModel(
        announcementId  : '',
        title           : '',
        content         : '',
        createdBy       : '',
        announcementType: 'General',
        priority        : 'Low',
        timestamp       : Timestamp.now(),
        visibilityScope : const <String>[],
        attachments     : null,
      );
}
