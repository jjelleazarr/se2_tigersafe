import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_types_collection.dart';

class IncidentTypeController {
  final CollectionReference incidentTypesRef =
      FirebaseFirestore.instance.collection('incident_types');

  /// Fetch All Incident Types
  Future<List<IncidentTypeModel>> getAllIncidentTypes() async {
    try {
      QuerySnapshot snapshot = await incidentTypesRef.get();
      return snapshot.docs.map((doc) {
        return IncidentTypeModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching incident types: $e');
      return [];
    }
  }

  /// Get a Specific Incident Type by ID
  Future<IncidentTypeModel?> getIncidentTypeById(String typeId) async {
    try {
      DocumentSnapshot doc = await incidentTypesRef.doc(typeId).get();
      if (doc.exists) {
        return IncidentTypeModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching incident type: $e');
    }
    return null;
  }

  /// Add a New Incident Type
  Future<void> addIncidentType(
      String name, String description, int priorityLevel) async {
    try {
      await incidentTypesRef.add({
        'name': name,
        'description': description,
        'priority_level': priorityLevel,
      });
      print("Incident type added successfully!");
    } catch (e) {
      print('Error adding incident type: $e');
    }
  }

  /// Update an Incident Type
  Future<void> updateIncidentType(String typeId, String name, String description, int priorityLevel) async {
    try {
      await incidentTypesRef.doc(typeId).update({
        'name': name,
        'description': description,
        'priority_level': priorityLevel,
      });
      print("Incident type updated successfully!");
    } catch (e) {
      print('Error updating incident type: $e');
    }
  }

  /// Delete an Incident Type
  Future<void> deleteIncidentType(String typeId) async {
    try {
      await incidentTypesRef.doc(typeId).delete();
      print("Incident type deleted successfully!");
    } catch (e) {
      print('Error deleting incident type: $e');
    }
  }
}
