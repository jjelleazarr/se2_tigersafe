import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/reports_collection.dart';
// ─────────────────────────────────────────────────────────────
//  ReportsController – handles /reports collection CRUD
// ─────────────────────────────────────────────────────────────
class ReportsController {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('reports');

  /// Create a new report, returning the generated reportId.
  Future<String> createReport(ReportModel model) async {
    final doc = await _ref.add(model.toJson());
    return doc.id;
  }

  /// Update an existing report by ID.
  Future<void> updateReport(String reportId, Map<String, dynamic> update) =>
      _ref.doc(reportId).update(update);

  /// Delete a report (rare but useful for admin corrections).
  Future<void> deleteReport(String reportId) => _ref.doc(reportId).delete();

  /// Stream all reports for a given incident, newest first.
  Stream<List<ReportModel>> reportsForIncident(String incidentId) => _ref
      .where('incident_id', isEqualTo: incidentId)
      .orderBy('reported_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ReportModel.fromJson(d.data(), d.id))
          .toList());

  /// Upload an attachment (image / PDF) to Storage and return its https URL.
  Future<String> uploadAttachment(Uint8List bytes, String fileName) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('report_attachments/$fileName');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}
