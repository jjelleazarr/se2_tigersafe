import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/controllers/users_controller.dart';
import 'package:se2_tigersafe/controllers/ert_members_controller.dart';
import 'package:se2_tigersafe/models/users_collection.dart';
import 'package:url_launcher/url_launcher.dart';

class PriorityVerificationDetailsScreen extends StatelessWidget {
  final VerificationRequestModel request;
  final VerificationRequestsController _verificationController = VerificationRequestsController();
  final UserController _userController = UserController();
  final ERTMemberController _ertController = ERTMemberController();

  PriorityVerificationDetailsScreen({super.key, required this.request});

  void _approveRequest(BuildContext context) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    // 1. Update verification status
    await _verificationController.updateRequestStatus(
      requestId: request.requestId,
      newStatus: 'Active',
      adminId: admin.uid,
    );

    // 2. Create user document
    final newUser = UserModel(
      userId: request.submittedBy,
      email: request.email,
      idNumber: request.idNumber,
      firstName: request.firstName,
      middleName: request.middleName,
      surname: request.surname,
      phoneNumber: request.phoneNumber,
      address: request.address,
      profilePicture: request.profileImageUrl,
      accountStatus: 'Active',
      createdAt: request.submittedAt.toDate(),
      roles: ['emergency_response_team'],
    );
    await _userController.saveUser(newUser);

    // 3. Create ERT member record
    await _ertController.addERTMember(request.submittedBy, request.specialization);

    Navigator.pushReplacementNamed(context, '/priority_verification');
  }

  void _rejectRequest(BuildContext context) async {
    final reasons = [
      'Missing Credentials',
      'Insufficient Justification',
      'Invalid Specialization',
      'Duplicate Request',
    ];
    final selectedReasons = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((reason) {
              return CheckboxListTile(
                title: Text(reason),
                value: selectedReasons.contains(reason),
                onChanged: (val) {
                  setState(() {
                    val!
                        ? selectedReasons.add(reason)
                        : selectedReasons.remove(reason);
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final admin = FirebaseAuth.instance.currentUser;
              if (admin == null) return;

              await _verificationController.updateRequestStatus(
                requestId: request.requestId,
                newStatus: 'Rejected',
                adminId: admin.uid,
              );
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/priority_verification');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ERT Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${request.firstName} ${request.middleName} ${request.surname}', style: const TextStyle(fontSize: 18)),
            Text('Email: ${request.email}'),
            Text('Phone: ${request.phoneNumber}'),
            Text('ID Number: ${request.idNumber}'),
            Text('Address: ${request.address}'),
            const SizedBox(height: 10),
            Text('Specialization: ${request.specialization}'),
            Text('Justification: ${request.description}'),
            if (request.proofOfIdentity.isNotEmpty)
              InkWell(
                onTap: () => launchUrl(Uri.parse(request.proofOfIdentity)),
                child: const Text('View Proof of Identity', style: TextStyle(color: Colors.blue)),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveRequest(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectRequest(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}