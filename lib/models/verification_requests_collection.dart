import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestModel {
  final String requestId;
  final String firstName;
  final String middleName;
  final String surname;
  final String idNumber;
  final String email;
  final String phoneNumber;
  final String address;
  final List<String> roles;
  final String specialization;
  final String proofOfIdentity;
  final String description;
  final String accountStatus;
  final String submittedBy;
  final Timestamp submittedAt;
  final String? adminId;
  final Timestamp? reviewedAt;
  final String? profileImageUrl;

  VerificationRequestModel({
    required this.requestId,
    required this.firstName,
    required this.middleName,
    required this.surname,
    required this.idNumber,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.roles,
    required this.specialization,
    required this.proofOfIdentity,
    required this.description,
    required this.accountStatus,
    required this.submittedBy,
    required this.submittedAt,
    this.adminId,
    this.reviewedAt,
    this.profileImageUrl,
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json, String docId) {
    return VerificationRequestModel(
      requestId: docId,
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      surname: json['surname'] ?? '',
      idNumber: json['id_number'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      specialization: json['specialization'] ?? '',
      proofOfIdentity: json['proof_of_identity'] ?? '',
      description: json['description'] ?? '',
      accountStatus: json['account_status'] ?? 'Pending',
      submittedBy: json['submitted_by'] ?? '',
      submittedAt: json['submitted_at'] ?? Timestamp.now(),
      adminId: json['admin_id'],
      reviewedAt: json['reviewed_at'],
      profileImageUrl: json['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'surname': surname,
      'id_number': idNumber,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'roles': roles,
      'specialization': specialization,
      'proof_of_identity': proofOfIdentity,
      'description': description,
      'account_status': accountStatus,
      'submitted_by': submittedBy,
      'submitted_at': submittedAt,
      'admin_id': adminId,
      'reviewed_at': reviewedAt,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    };
  }
}
