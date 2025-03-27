import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAccountsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateAccountFields({
    required String userId,
    required Map<String, dynamic> updatedFields,
    BuildContext? context,
  }) async {
    try {
      await _firestore.collection("users").doc(userId).update(updatedFields);

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account updated successfully.")),
        );
      } else {
        print("Account updated successfully.");
      }
    } catch (e) {
      print("Error updating account fields: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error updating account.")),
        );
      }
    }
  }

  Future<void> updateRole(String userId, String newRole, BuildContext? context) async {
    await updateAccountFields(
      userId: userId,
      updatedFields: {"roles": newRole},
      context: context,
    );
    sendNotification(userId, "Role Updated", "Your role has been updated to $newRole");
  }

  Future<void> updateStatus(String userId, String newStatus, BuildContext? context) async {
    await updateAccountFields(
      userId: userId,
      updatedFields: {"account_status": newStatus},
      context: context,
    );
    sendNotification(userId, "Account Status Updated", "Your account status is now $newStatus.");
  }

  Future<void> deleteAccount(String userId, BuildContext? context) async {
    try {
      await _firestore.collection("users").doc(userId).delete();

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deleted successfully.")),
        );
      } else {
        print("Account deleted successfully.");
      }
    } catch (e) {
      print("Error deleting account: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting account.")),
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
