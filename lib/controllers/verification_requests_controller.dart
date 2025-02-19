import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_requests_collection.dart';

class VerificationRequestController {
  final CollectionReference verificationRequestsRef =
      FirebaseFirestore.instance.collection('verification_requests');

  /// Fetch All Verification Requests
  Future<List<VerificationRequestModel>> getAllVerificationRequests() async {
    try {
      QuerySnapshot snapshot = await verificationRequestsRef.get();
      return snapshot.docs.map((doc) {
        return VerificationRequestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching verification requests: $e');
      return [];
    }
  }

  /// Get a Specific Verification Request by ID
  Future<VerificationRequestModel?> getVerificationRequestById(String requestId) async {
    try {
      DocumentSnapshot doc = await verificationRequestsRef.doc(requestId).get();
      if (doc.exists) {
        return VerificationRequestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching verification request: $e');
    }
    return null;
  }

  /// 🔹 Submit a New Verification Request
  Future<void> submitVerificationRequest(String userId, String roleRequested) async {
    try {
      await verificationRequestsRef.add({
        'user_id': userId,
        'role_requested': roleRequested,
        'status': "Pending",
        'admin_id': null,
        'created_at': Timestamp.now(),
        'reviewed_at': null,
      });
      print("Verification request submitted successfully!");
    } catch (e) {
      print('Error submitting verification request: $e');
    }
  }

  /// Approve or Deny a Verification Request
  Future<void> updateVerificationRequest(String requestId, String adminId, String status) async {
    if (status != "Approved" && status != "Denied") {
      print("❌ Invalid status update. Use 'Approved' or 'Denied'.");
      return;
    }
    try {
      await verificationRequestsRef.doc(requestId).update({
        'status': status,
        'admin_id': adminId,
        'reviewed_at': Timestamp.now(),
      });
      print("Verification request updated successfully!");
    } catch (e) {
      print('Error updating verification request: $e');
    }
  }

  /// Delete a Verification Request
  Future<void> deleteVerificationRequest(String requestId) async {
    try {
      await verificationRequestsRef.doc(requestId).delete();
      print("Verification request deleted successfully!");
    } catch (e) {
      print('Error deleting verification request: $e');
    }
  }
}
