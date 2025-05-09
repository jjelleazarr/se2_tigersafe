import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/verification_requests_collection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class VerificationRequestsController {
  final CollectionReference _verificationRef =
      FirebaseFirestore.instance.collection('verification_requests');
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection('users');

  /// Submit a new verification request using the model object
  Future<void> submitRequest(
    VerificationRequestModel request,
    PlatformFile? proofFile, {
    PlatformFile? profileImage,
  }) async {
    try {
      final data = request.toJson();

      // Upload proof of identity if provided
      if (proofFile != null && proofFile.path != null && proofFile.path!.isNotEmpty) {
        final proofRef = FirebaseStorage.instance
            .ref()
            .child('proof_of_identity/${DateTime.now().millisecondsSinceEpoch}_${proofFile.name}');
        await proofRef.putFile(File(proofFile.path!));
        final fileUrl = await proofRef.getDownloadURL();
        data['proof_of_identity'] = fileUrl;
      }

      // Upload profile image if provided
      if (profileImage != null && profileImage.path != null && profileImage.path!.isNotEmpty) {
        final profileRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${DateTime.now().millisecondsSinceEpoch}_${profileImage.name}');
        await profileRef.putFile(File(profileImage.path!));
        final profileUrl = await profileRef.getDownloadURL();
        data['profile_image_url'] = profileUrl;
      }

      // Save to Firestore
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

  /// Send notification to user about their verification request status
  Future<void> _sendVerificationNotification({
    required String userId,
    required String status,
    required String requestType,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        print('User document not found for ID: $userId');
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcm_token'] as String?;
      
      if (fcmToken == null) {
        print('No FCM token found for user: $userId');
        return;
      }

      print('Sending verification notification to token: $fcmToken');
      
      // Send notification using Firebase Cloud Messaging
      final message = {
        'token': fcmToken,
        'notification': {
          'title': 'Verification Request $status',
          'body': 'Your $requestType verification request has been $status',
        },
        'data': {
          'type': 'verification',
          'status': status.toLowerCase(),
          'requestType': requestType.toLowerCase(),
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'default_channel',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
          },
        },
      };

      // Send using Firebase Admin SDK (you'll need to set this up on your backend)
      // For now, we'll use the Firebase Console to send the notification
      print('Notification payload: $message');
      
      // TODO: Replace with actual FCM send implementation
      // This is just for testing - in production, use Firebase Admin SDK
      await FirebaseMessaging.instance.sendMessage(
        to: fcmToken,
        data: message['data'] as Map<String, String>,
      );
      
    } catch (e) {
      print('Error sending verification notification: $e');
    }
  }

  /// Approve or reject a request (admin flow)
  Future<void> updateRequestStatus({
    required String requestId,
    required String newStatus,
    required String adminId,
  }) async {
    try {
      // Get the request details first
      final requestDoc = await _verificationRef.doc(requestId).get();
      if (!requestDoc.exists) {
        print('Verification request not found: $requestId');
        return;
      }

      final request = VerificationRequestModel.fromJson(
        requestDoc.data() as Map<String, dynamic>,
        requestDoc.id,
      );

      // Update request status
      await _verificationRef.doc(requestId).update({
        'account_status': newStatus,
        'admin_id': adminId,
        'reviewed_at': Timestamp.now(),
      });

      print('Request status updated to: $newStatus');

      // Send notification to user
      final requestType = request.roles.contains('emergency_response_team') 
          ? 'Emergency Response Team' 
          : 'Stakeholder';
      
      await _sendVerificationNotification(
        userId: request.submittedBy,
        status: newStatus,
        requestType: requestType,
      );
    } catch (e) {
      print('Error updating request: $e');
      rethrow;
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
