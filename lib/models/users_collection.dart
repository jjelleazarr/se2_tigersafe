import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId; // Firestore Document ID (Auto-generated)
  final String email;
  final String idNumber;
  final String firstName;
  final String? middleName;
  final String surname;
  final String? phoneNumber;
  final String? address;
  final String? profilePicture;
  final String accountStatus; // Enum: Pending, Active, Denied, Banned
  final DateTime createdAt; // Timestamp
  final String roles; // Reference to roles collection

  UserModel({
    required this.userId,
    required this.email,
    required this.idNumber,
    required this.firstName,
    this.middleName,
    required this.surname,
    this.phoneNumber,
    this.address,
    this.profilePicture,
    required this.accountStatus,
    required this.createdAt,
    required this.roles,
  });

  /// Convert Firestore document (Map) to Dart Object
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      userId: documentId,
      email: json['email'],
      idNumber: json['id_number'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      surname: json['surname'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      accountStatus: json['account_status'],
      createdAt: (json['created_at'] as Timestamp).toDate(),
      roles: json['roles'],
    );
  }

  /// Convert Dart Object to Firestore document (Map)
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'id_number': idNumber,
      'first_name': firstName,
      'middle_name': middleName,
      'surname': surname,
      'phone_number': phoneNumber,
      'address': address,
      'profile_picture': profilePicture,
      'account_status': accountStatus,
      'created_at': Timestamp.fromDate(createdAt),
      'roles': roles, // Reference to roles
    };
  }
}
