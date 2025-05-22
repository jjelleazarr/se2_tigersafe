import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ert_members_collection.dart';

class ERTMemberController {
  final CollectionReference ertMembersRef =
      FirebaseFirestore.instance.collection('ert_members');

  /// Fetch All ERT Members
  Future<List<ERTMemberModel>> getAllERTMembers() async {
    try {
      QuerySnapshot snapshot = await ertMembersRef.get();
      return snapshot.docs.map((doc) {
        return ERTMemberModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching ERT members: $e');
      return [];
    }
  }

  /// Get a Specific ERT Member by ID
  Future<ERTMemberModel?> getERTMemberById(String memberId) async {
    try {
      DocumentSnapshot doc = await ertMembersRef.doc(memberId).get();
      if (doc.exists) {
        return ERTMemberModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching ERT member: $e');
    }
    return null;
  }

  /// Add a New ERT Member
  Future<void> addERTMember(String userId, String specialization) async {
    try {
      await ertMembersRef.add({
        'user_id': userId,
        'status': "Active",
        'specialization': specialization, // medical, security, rescue, etc.
        'created_at': Timestamp.now(),
      });
      print("ERT member added successfully!");
    } catch (e) {
      print('Error adding ERT member: $e');
    }
  }


  /// Update ERT Member Status
  Future<void> updateERTMemberStatus(String memberId, String newStatus) async {
    const allowedStatuses = ["Active", "Dispatched", "Arrived", "On-Duty", "Off-Duty"];
    if (!allowedStatuses.contains(newStatus)) {
      print("Invalid status update. Use one of: " + allowedStatuses.join(", "));
      return;
    }
    try {
      await ertMembersRef.doc(memberId).update({
        'status': newStatus,
      });
      print("ERT member status updated successfully!");
    } catch (e) {
      print('Error updating ERT member status: $e');
    }
  }

  /// Delete an ERT Member
  Future<void> deleteERTMember(String memberId) async {
    try {
      await ertMembersRef.doc(memberId).delete();
      print("ERT member deleted successfully!");
    } catch (e) {
      print('Error deleting ERT member: $e');
    }
  }

  /// Stream All ERT Members (real-time updates)
  Stream<List<ERTMemberModel>> streamAllERTMembers() {
    return ertMembersRef.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) =>
        ERTMemberModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)
      ).toList()
    );
  }
}
