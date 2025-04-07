import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:url_launcher/url_launcher.dart';

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
    Navigator.pop(context);
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
                Navigator.pop(context);
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
    final isUST = request.email.endsWith('@ust.edu.ph');
    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
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
            if (request.profileImageUrl != null && request.profileImageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Image.network(request.profileImageUrl!, height: 100),
              ),
            if (!isUST && request.proofOfIdentity.isNotEmpty)
              InkWell(
                onTap: () => launchUrl(Uri.parse(request.proofOfIdentity)),
                child: Text('Proof of Identity: Tap to View', style: const TextStyle(color: Colors.blue)),
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
