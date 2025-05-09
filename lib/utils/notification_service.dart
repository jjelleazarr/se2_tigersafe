import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  /// Sends a status update notification to the user who created the report.
  static Future<void> sendReportStatusUpdate({
    required String userId,
    required String reportId,
    required String newStatus,
  }) async {
    // 1. Fetch the user's FCM token
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcm_token'];
    if (fcmToken == null) {
      print('No FCM token for user $userId');
      return;
    }

    // 2. Build the notification payload
    final notification = {
      'title': 'Report Status Updated',
      'body': 'Your report ($reportId) status is now: $newStatus',
    };
    final data = {
      'type': 'report_status_update',
      'report_id': reportId,
      'new_status': newStatus,
    };

    // 3. Placeholder for actual FCM send (should be done via backend/Cloud Function)
    print('Would send notification to $fcmToken: $notification, $data');
  }
} 