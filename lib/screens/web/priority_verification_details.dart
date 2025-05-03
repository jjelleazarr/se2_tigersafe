import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/controllers/users_controller.dart';
import 'package:se2_tigersafe/controllers/ert_members_controller.dart';
import 'package:se2_tigersafe/models/users_collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class PriorityVerificationDetailsScreen extends StatelessWidget {
  final VerificationRequestModel request;
  final VerificationRequestsController _verificationController =
      VerificationRequestsController();
  final UserController _userController = UserController();
  final ERTMemberController _ertController = ERTMemberController();

  PriorityVerificationDetailsScreen({super.key, required this.request});

  void _approveRequest(BuildContext context) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    await _verificationController.updateRequestStatus(
      requestId: request.requestId,
      newStatus: 'Active',
      adminId: admin.uid,
    );

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
    await _ertController.addERTMember(
        request.submittedBy, request.specialization);

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
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
      appBar: const DashboardAppBar(),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Priority ',
                      style: TextStyle(
                          color: Color(0xFFFEC00F),
                          fontWeight: FontWeight.bold,
                          fontSize: 28),
                    ),
                    TextSpan(
                      text: 'Verification',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 900,
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: request.proofOfIdentity.isNotEmpty
                            ? NetworkImage(request.proofOfIdentity)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInfoLabel(
                                        "ID Number", request.idNumber)),
                                Expanded(
                                    child: _buildInfoLabel(
                                        "Phone Number", request.phoneNumber)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInfoLabel(
                                        "Surname", request.surname)),
                                Expanded(
                                    child: _buildInfoLabel(
                                        "Address", request.address)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInfoLabel(
                                        "First Name", request.firstName)),
                                Expanded(
                                    child: _buildRoleChip(
                                        "Role", "Emergency Response")),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInfoLabel("Middle Name",
                                        request.middleName ?? "N/A")),
                                Expanded(
                                    child: _buildInfoLabel("Specialization",
                                        request.specialization)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoLabel(
                                    "Justification",
                                    request.description.isNotEmpty
                                        ? request.description
                                        : "N/A",
                                  ),
                                ),
                                if (request.proofOfIdentity.isNotEmpty)
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: InkWell(
                                        onTap: () => launchUrl(
                                            Uri.parse(request.proofOfIdentity)),
                                        child: const Text(
                                          'View Proof of Identity',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveRequest(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rejectRequest(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Deny',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$label\n",
            style: const TextStyle(
                color: Color(0xFFFEC00F),
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFFEC00F), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            role,
            style: const TextStyle(color: Color(0xFFFEC00F), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
