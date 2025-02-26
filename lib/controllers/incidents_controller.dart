import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incidents_collection.dart';

class IncidentController {
  final CollectionReference incidentsRef =
      FirebaseFirestore.instance.collection('incidents');

  /// Fetch All Incidents
  Future<List<IncidentModel>> getAllIncidents() async {
    try {
      QuerySnapshot snapshot = await incidentsRef.get();
      return snapshot.docs.map((doc) {
        return IncidentModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching incidents: $e');
      return [];
    }
  }

  /// Get a Specific Incident by ID
  Future<IncidentModel?> getIncidentById(String incidentId) async {
    try {
      DocumentSnapshot doc = await incidentsRef.doc(incidentId).get();
      if (doc.exists) {
        return IncidentModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching incident: $e');
    }
    return null;
  }

  /// Report a New Incident
  Future<void> reportIncident(
      String reporterId, String type, String location) async {
    try {
      await incidentsRef.add({
        'reporter_id': reporterId,
        'type': type,
        'location': location,
        'status': "Pending", // Default status
        'reported_at': Timestamp.now(),
        'assigned_teams': [], // Initially empty
      });
      print("Incident reported successfully!");
    } catch (e) {
      print('Error reporting incident: $e');
    }
  }

  /// Update Incident Status
  Future<void> updateIncidentStatus(String incidentId, String newStatus) async {
    try {
      await incidentsRef.doc(incidentId).update({
        'status': newStatus,
      });
      print("Incident status updated to $newStatus");
    } catch (e) {
      print('Error updating incident status: $e');
    }
  }

  /// Assign Emergency Teams to Incident
  Future<void> assignTeams(String incidentId, List<String> teamIds) async {
    try {
      await incidentsRef.doc(incidentId).update({
        'assigned_teams': teamIds,
      });
      print("Emergency teams assigned to incident.");
    } catch (e) {
      print('Error assigning teams: $e');
    }
  }

  /// Delete an Incident
  Future<void> deleteIncident(String incidentId) async {
    try {
      await incidentsRef.doc(incidentId).delete();
      print("Incident deleted successfully!");
    } catch (e) {
      print('Error deleting incident: $e');
    }
  }
}
