import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';

class PriorityApplicationDeniedScreen extends StatelessWidget {
  final VerificationRequestModel request;

  const PriorityApplicationDeniedScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(request.reviewedAt!.toDate());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Denied'),
        backgroundColor: Colors.red[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(
              'Your application has been denied.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Reviewed by Admin ID: ${request.adminId ?? "Unknown"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Date Reviewed: $date',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please ensure your submitted information is accurate. You may apply again if needed.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
