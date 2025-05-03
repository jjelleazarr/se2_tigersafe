import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class StakeholderVerificationDetailsScreen extends StatelessWidget {
  final VerificationRequestModel request;
  final VerificationRequestsController _controller = VerificationRequestsController();

  StakeholderVerificationDetailsScreen({super.key, required this.request});

  void _approveRequest(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _controller.updateRequestStatus(
      requestId: request.requestId,
      newStatus: 'Active',
      adminId: currentUser.uid,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(request.submittedBy)
          .set({
        'first_name': request.firstName,
        'middle_name': request.middleName,
        'surname': request.surname,
        'id_number': request.idNumber,
        'email': request.email,
        'phone_number': request.phoneNumber,
        'address': request.address,
        'profile_picture': '', // No image for stakeholder
        'roles': request.roles,
        'account_status': 'Active',
        'created_at': request.submittedAt,
      });

      Navigator.pushReplacementNamed(context, '/stakeholder_verification');
    } catch (e) {
      print('Error creating user document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating user document.')),
      );
    }
  }

  void _rejectRequest(BuildContext context) async {
    final reasons = [
      'Incorrect ID Number',
      'Incorrect Name',
      'Duplicate Application',
      'Fraudulent Application',
      'Unauthorized Role',
    ];
    final selectedReasons = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                await _controller.updateRequestStatus(
                  requestId: request.requestId,
                  newStatus: 'Rejected',
                  adminId: currentUser.uid,
                );
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/stakeholder_verification');
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
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
                      text: 'Stakeholder ',
                      style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    TextSpan(
                      text: 'Verification',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 900,
              constraints: const BoxConstraints(maxHeight: 500),
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
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildInfoLabel("ID Number", request.idNumber)),
                                Expanded(child: _buildInfoLabel("Phone Number", request.phoneNumber)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildInfoLabel("Surname", request.surname)),
                                Expanded(child: _buildInfoLabel("Address", request.address)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildInfoLabel("First Name", request.firstName)),
                                Expanded(child: _buildRoleChip("Role", "Stakeholder")),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildInfoLabel("Middle Name", request.middleName ?? "N/A")),
                                Expanded(child: _buildInfoLabel("Email", request.email)),
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
                          child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                          child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 18)),
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
            style: const TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 14),
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
        Text(label, style: const TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold)),
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
