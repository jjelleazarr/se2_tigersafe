import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';

class PriorityVerificationScreen extends StatefulWidget {
  @override
  _PriorityVerificationScreenState createState() => _PriorityVerificationScreenState();
}

class _PriorityVerificationScreenState extends State<PriorityVerificationScreen> {
  final VerificationRequestsController _controller = VerificationRequestsController();
  Future<List<VerificationRequestModel>> _requestsFuture = Future.value([]);

  Future<void> _loadRequests() async {
    try {
      final requests = await _controller.getAllRequests();
      setState(() {
        _requestsFuture = Future.value(requests);
      });
    } catch (e) {
      print('Error fetching priority requests: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _openDetails(VerificationRequestModel request) {
    Navigator.pushNamed(
      context,
      '/priority_verification_details',
      arguments: request,
    ).then((_) => _loadRequests());
  }

  Widget _buildRequestCard(VerificationRequestModel request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text('${request.firstName} ${request.middleName ?? ''} ${request.surname}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Role: ${request.roles.join(', ')}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openDetails(request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Priority Verification')),
      body: FutureBuilder<List<VerificationRequestModel>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading priority verification requests'));
          }

          final requests = snapshot.data!
              .where((r) => r.roles.contains('emergency_response_team') && r.accountStatus == 'Pending')
              .toList();

          if (requests.isEmpty) {
            return const Center(child: Text('No pending priority verification requests.'));
          }

          return ListView(
            children: requests.map(_buildRequestCard).toList(),
          );
        },
      ),
    );
  }
}
