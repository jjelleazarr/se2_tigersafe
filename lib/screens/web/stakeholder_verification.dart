import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _openDetails(VerificationRequestModel request) {
    Navigator.pushNamed(
      context,
      '/stakeholder_verification_details',
      arguments: request,
    ).then((_) {
      // Refresh list after returning from details screen
      setState(() => _requestsFuture = _controller.getAllRequests());
    });
  }

  Widget _buildRequestCard(VerificationRequestModel request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text('${request.firstName} ${request.middleName ?? ''} ${request.surname}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Email: ${request.email}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openDetails(request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stakeholder Verification')),
      body: FutureBuilder<List<VerificationRequestModel>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }

          final requests = snapshot.data!
              .where((r) => r.roles.contains('stakeholder') && r.accountStatus == 'Pending')
              .toList();

          if (requests.isEmpty) {
            return const Center(child: Text('No pending stakeholder requests.'));
          }

          return ListView(
            children: requests.map(_buildRequestCard).toList(),
          );
        },
      ),
    );
  }
}
