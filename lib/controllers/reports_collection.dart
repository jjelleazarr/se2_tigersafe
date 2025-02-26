import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reports_collection.dart';

class ReportController {
  final CollectionReference reportsRef =
      FirebaseFirestore.instance.collection('reports');

  /// Fetch All Reports
  Future<List<ReportModel>> getAllReports() async {
    try {
      QuerySnapshot snapshot = await reportsRef.get();
      return snapshot.docs.map((doc) {
        return ReportModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  /// Get a Specific Report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      DocumentSnapshot doc = await reportsRef.doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching report: $e');
    }
    return null;
  }

  /// Submit a New Report
  Future<void> submitReport(String userId, String type, String description,
      String location, List<String> mediaUrls) async {
    try {
      await reportsRef.add({
        'user_id': userId,
        'type': type,
        'description': description,
        'location': location,
        'status': "Pending", // Default status
        'reported_at': Timestamp.now(),
        'media_urls': mediaUrls,
      });
      print("Report submitted successfully!");
    } catch (e) {
      print('Error submitting report: $e');
    }
  }

  /// Update Report Status
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await reportsRef.doc(reportId).update({
        'status': newStatus,
      });
      print("Report status updated to $newStatus");
    } catch (e) {
      print('Error updating report status: $e');
    }
  }

  /// Delete a Report
  Future<void> deleteReport(String reportId) async {
    try {
      await reportsRef.doc(reportId).delete();
      print("Report deleted successfully!");
    } catch (e) {
      print('Error deleting report: $e');
    }
  }
}
