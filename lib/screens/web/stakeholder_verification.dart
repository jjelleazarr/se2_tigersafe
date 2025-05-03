import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';

class StakeholderVerificationScreen extends StatefulWidget {
  @override
  _StakeholderVerificationScreenState createState() => _StakeholderVerificationScreenState();
}

class _StakeholderVerificationScreenState extends State<StakeholderVerificationScreen> {
  final VerificationRequestsController _controller = VerificationRequestsController();
  Future<List<VerificationRequestModel>> _requestsFuture = Future.value([]);

  Future<void> _loadRequests() async {
    try {
      final requests = await _controller.getAllRequests();
      setState(() {
        _requestsFuture = Future.value(requests);
      });
    } catch (e) {
      print('Error fetching requests: $e');
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
      '/stakeholder_verification_details',
      arguments: request,
    ).then((_) => _loadRequests());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VerificationRequestModel>>(
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

        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black,
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 3,
                        child: Text('Name', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('Email', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Table Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: requests.map((request) {
                        String fullName = [
                          request.firstName,
                          request.middleName ?? '',
                          request.surname,
                        ].where((name) => name.trim().isNotEmpty).join(' ');

                        return InkWell(
                          onTap: () => _openDetails(request),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black12)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(fullName)),
                                Expanded(flex: 4, child: Text(request.email)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
