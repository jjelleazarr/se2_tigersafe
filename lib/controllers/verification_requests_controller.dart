import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/verification_requests_collection.dart';

class VerificationRequestsController {
  final CollectionReference _verificationRef =
      FirebaseFirestore.instance.collection('verification_requests');

  /// Submit a new verification request using the model object
  Future<void> submitRequest(
    VerificationRequestModel request,
    PlatformFile proofFile, {
    String? profileImageUrl,
  }) async {
    try {
      // Upload file to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('proof_of_identity/${DateTime.now().millisecondsSinceEpoch}_${proofFile.name}');
      await storageRef.putFile(File(proofFile.path!));
      final fileUrl = await storageRef.getDownloadURL();

      // Convert model to JSON and inject uploaded file URL and optional profile image
      final data = request.toJson();
      data['proof_of_identity'] = fileUrl;

      if (profileImageUrl != null) {
        data['profile_image_url'] = profileImageUrl;
      }

      // Save request to Firestore
      await _verificationRef.add(data);
    } catch (e) {
      print('Error submitting verification request: $e');
      rethrow;
    }
  }

  /// Get a single verification request by Firebase UID
  Future<VerificationRequestModel?> getRequestByUid(String uid) async {
    try {
      final querySnapshot = await _verificationRef
          .where('submitted_by', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return VerificationRequestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching verification request by UID: $e');
    }
    return null;
  }


  /// Fetch all verification requests
  Future<List<VerificationRequestModel>> getAllRequests() async {
    try {
      final snapshot = await _verificationRef.get();
      return snapshot.docs.map((doc) {
        return VerificationRequestModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching requests: $e');
      return [];
    }
  }

  /// Approve or reject a request (admin flow)
  Future<void> updateRequestStatus({
    required String requestId,
    required String newStatus,
    required String adminId,
  }) async {
    try {
      await _verificationRef.doc(requestId).update({
        'account_status': newStatus,
        'admin_id': adminId,
        'reviewed_at': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating request: $e');
    }
  }

  /// Delete a request (optional admin cleanup)
  Future<void> deleteRequest(String requestId) async {
    try {
      await _verificationRef.doc(requestId).delete();
    } catch (e) {
      print('Error deleting request: $e');
    }
  }
}
