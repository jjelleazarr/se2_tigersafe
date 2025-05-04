import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incidents_collection.dart';

class IncidentsController {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('incidents');

  /// Basic create (if you allow web operators to open a new incident)
  Future<String> createIncident(IncidentModel model) async {
    final doc = await _ref.add(model.toJson());
    return doc.id;
  }

  /// Generic update – reuse for status changes, etc.
  Future<void> updateIncident(String id, Map<String, dynamic> update) =>
      _ref.doc(id).update(update);

  /// Assign a team and reset dispatched list.
  Future<void> assignTeam(String incidentId, String team) => _ref.doc(incidentId)
      .update({'assigned_team': team, 'dispatched_members': <String>[]});

  /// Add a responder UID; first responder flips status to "Personnel Dispatched".
  Future<void> addDispatchedMember(String incidentId, String uid) =>
      FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = _ref.doc(incidentId);
        final snap = await tx.get(ref);
        final members = List<String>.from(snap['dispatched_members'] ?? []);
        if (!members.contains(uid)) {
          members.add(uid);
          tx.update(ref, {
            'dispatched_members': members,
            'status': 'Personnel Dispatched',
          });
        }
      });

  /// Stream incidents filtered by team specialisation.
  Stream<List<IncidentModel>> incidentsForTeam(String team) => _ref
      .where('assigned_team', isEqualTo: team)
      .where('status', whereIn: ['Pending', 'Personnel Dispatched'])
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => IncidentModel.fromJson(d.data(), d.id))
          .toList());
}

