import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentTypeModel {
  final String typeId; // Auto-generated document ID
  final String name; 
  final String description; 
  final int priorityLevel; // Priority level (1 = Low, 5 = Critical)

  IncidentTypeModel({
    required this.typeId,
    required this.name,
    required this.description,
    required this.priorityLevel,
  });

  /// Convert Firestore document to Dart Object
  factory IncidentTypeModel.fromJson(Map<String, dynamic> json, String documentId) {
    return IncidentTypeModel(
      typeId: documentId,
      name: json['name'],
      description: json['description'],
      priorityLevel: json['priority_level'],
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'priority_level': priorityLevel,
    };
  }
}
