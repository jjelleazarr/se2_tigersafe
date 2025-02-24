import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAccountsController {
// adminRoleUpdate(userId, newRole):
//     when admin updates a stakeholder's role:
//         FirebaseFirestore.collection("users").document(userId).update({
//             "role": newRole
//         })
//
//         sendNotification(userId, "Role Updated", "Your role has been updated to " + newRole)
//         displaySuccess("Role Updated")
//
// accountApproval(userId, action):
//     when an admin reviews an account update request:
//         if action == "approve":
//             FirebaseFirestore.collection("users").document(userId).update({
//                 "status": "Approved"
//             })
//             sendNotification(userId, "Account Approved", "Your account has been approved.")
//         else:
//             FirebaseFirestore.collection("users").document(userId).update({
//                 "status": "Rejected"
//             })
//             sendNotification(userId, "Account Rejected", "Your account application has been rejected.")
//
//         displaySuccess("Account " + action)
}