import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:url_launcher/url_launcher.dart';

class StakeholderVerificationScreen extends StatefulWidget {
  @override
  _StakeholderVerificationScreenState createState() => _StakeholderVerificationScreenState();
}

class _StakeholderVerificationScreenState extends State<StakeholderVerificationScreen> {
  final VerificationRequestsController _controller = VerificationRequestsController();
  late Future<List<VerificationRequestModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _controller.getAllRequests();
  }

  Future<void> _approveRequest(String requestId) async {
    await _controller.updateRequestStatus(
      requestId: requestId,
      newStatus: 'Active',
      adminId: 'admin-id', // Replace with actual admin logic
    );
    setState(() => _requestsFuture = _controller.getAllRequests());
  }

  Future<void> _showRejectionDialog(String requestId) async {
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
      builder: (context) {
        return AlertDialog(
          title: Text('Reject Application'),
          content: SingleChildScrollView(
            child: Column(
              children: reasons.map((reason) {
                return CheckboxListTile(
                  title: Text(reason),
                  value: selectedReasons.contains(reason),
                  onChanged: (bool? selected) {
                    setState(() {
                      selected!
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
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.updateRequestStatus(
                  requestId: requestId,
                  newStatus: 'Rejected',
                  adminId: 'admin-id',
                );
                Navigator.pop(context);
                setState(() => _requestsFuture = _controller.getAllRequests());
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(VerificationRequestModel request) {
    final isUST = request.email.endsWith('@ust.edu.ph');

    return ExpansionTile(
      title: Text('${request.firstName} ${request.middleName} ${request.surname}',
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Role: Stakeholder'),
      children: [
        ListTile(title: Text('Email: ${request.email}')),
        ListTile(title: Text('Phone: ${request.phoneNumber}')),
        ListTile(title: Text('ID Number: ${request.idNumber}')),
        ListTile(title: Text('Address: ${request.address}')),
        if (!isUST)
          ListTile(
            title: Text('Proof of Identity:'),
            subtitle: InkWell(
              onTap: () => launchUrl(Uri.parse(request.proofOfIdentity)),
              child: Text(
                request.proofOfIdentity,
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ButtonBar(
          children: [
            TextButton(
              onPressed: () => _showRejectionDialog(request.requestId),
              child: Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => _approveRequest(request.requestId),
              child: Text('Approve'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VerificationRequestModel>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading requests'));
        }
        final requests = snapshot.data!
            .where((r) => r.roles.contains('stakeholder') && r.accountStatus == 'Pending')
            .toList();

        if (requests.isEmpty) {
          return Center(child: Text('No pending stakeholder requests.'));
        }

        return ListView(
          children: requests.map(_buildRequestCard).toList(),
        );
      },
    );
  }
}
