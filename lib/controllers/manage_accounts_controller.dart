import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAccountsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> adminRoleUpdate(String userId, String newRole, BuildContext? context) async {
    try {
      await _firestore.collection("users").doc(userId).update({
        "role": newRole,
      });

      sendNotification(userId, "Role Updated", "Your role has been updated to $newRole");

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Role Updated")),
        );
      } else {
        print("Role Updated");
      }
    } catch (e) {
      print("Error updating role: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating role")),
        );
      }
    }
  }

  Future<void> accountApproval(String userId, String action, BuildContext? context) async {
    try {
      if (action == "approve") {
        await _firestore.collection("users").doc(userId).update({
          "status": "Approved",
        });
        sendNotification(userId, "Account Approved", "Your account has been approved.");
      } else {
        await _firestore.collection("users").doc(userId).update({
          "status": "Rejected",
        });
        sendNotification(userId, "Account Rejected", "Your account application has been rejected.");
      }

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account $action")),
        );
      } else {
        print("Account $action");
      }
    } catch (e) {
      print("Error approving/rejecting account: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing account action")),
        );
      }
    }
  }

  void sendNotification(String userId, String title, String message) {
    try {
      Map<String, dynamic> notification = {
        "title": title,
        "message": message,
        "timestamp": FieldValue.serverTimestamp(),
        "userId": userId,
      };
      _firestore.collection("notifications").add(notification);
      print("Notification sent to user $userId: $title");
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
