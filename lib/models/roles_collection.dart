import 'package:cloud_firestore/cloud_firestore.dart';

class RoleModel {
  final String roleId; // Auto-generated Document ID
  final String roleName;

  RoleModel({
    required this.roleId,
    required this.roleName,
  });

  /// Convert Firestore document to Dart Object
  factory RoleModel.fromJson(Map<String, dynamic> json, String documentId) {
    return RoleModel(
      roleId: documentId,
      roleName: json['role_name'],
    );
  }

  /// Convert Dart Object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'role_name': roleName,
    };
  }
}
