import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/users_collection.dart';

class UserController {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Create or Update User
  Future<void> saveUser(UserModel user) async {
    await usersCollection.doc(user.userId).set(user.toJson());
  }

  /// Fetch User by ID
  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  /// Fetch All Users
  Stream<List<UserModel>> getAllUsers() {
    return usersCollection.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Update User Info
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await usersCollection.doc(userId).update(updates);
  }

  /// Delete User
  Future<void> deleteUser(String userId) async {
    await usersCollection.doc(userId).delete();
  }
}
