import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  /// Sends a status update notification to the user who created the report.
  static Future<void> sendReportStatusUpdate({
    required String userId,
    required String reportId,
    required String newStatus,
    String? location,
    String? incidentType,
  }) async {
    // Call the Cloud Function with userId (not fcmToken)
    final callable = FirebaseFunctions.instance.httpsCallable('sendReportStatusNotification');
    try {
      final result = await callable.call({
        'userId': userId,
        'reportId': reportId,
        'newStatus': newStatus,
        'location': location ?? '',
        'incidentType': incidentType ?? '',
      });
      print('Notification sent: [32m${result.data}[0m');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
} 