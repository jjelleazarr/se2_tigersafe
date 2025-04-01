import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/roles_collection.dart';

class RoleController {
  final CollectionReference rolesRef =
      FirebaseFirestore.instance.collection('roles');

  /// Fetch All Roles
  Future<List<RoleModel>> getAllRoles() async {
    try {
      QuerySnapshot snapshot = await rolesRef.get();
      return snapshot.docs.map((doc) {
        return RoleModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching roles: $e');
      return [];
    }
  }

  /// Get a Specific Role by ID
  Future<RoleModel?> getRoleById(String roleId) async {
    try {
      DocumentSnapshot doc = await rolesRef.doc(roleId).get();
      if (doc.exists) {
        return RoleModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching role: $e');
    }
    return null;
  }

  /// Add a New Role
  Future<void> addRole(String roleName) async {
    try {
      await rolesRef.add({'role_name': roleName});
      print("Role '$roleName' added successfully!");
    } catch (e) {
      print('Error adding role: $e');
    }
  }

  /// Update a Role Name
  Future<void> updateRole(String roleId, String newRoleName) async {
    try {
      await rolesRef.doc(roleId).update({'role_name': newRoleName});
      print("Role updated to '$newRoleName'");
    } catch (e) {
      print('Error updating role: $e');
    }
  }

  /// Delete a Role
  Future<void> deleteRole(String roleId) async {
    try {
      await rolesRef.doc(roleId).delete();
      print("Role deleted successfully!");
    } catch (e) {
      print('Error deleting role: $e');
    }
  }
}
