import 'package:flutter/material.dart';

class ERTDashboardScreen extends StatelessWidget {
  final bool medicalTeam;
  final bool ambulance;
  final bool stretcher;
  final bool hazardTeam;
  final bool security;
  final String? incidentType;
  final String? severity;

  const ERTDashboardScreen({
    super.key,
    required this.medicalTeam,
    required this.ambulance,
    required this.stretcher,
    required this.hazardTeam,
    required this.security,
    this.incidentType,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    // Implement the UI to display the dispatched personnel information
    return Scaffold(
      appBar: AppBar(title: const Text('ERT Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medical Team: $medicalTeam'),
            Text('Ambulance: $ambulance'),
            Text('Stretcher: $stretcher'),
            Text('Hazard Team: $hazardTeam'),
            Text('Security: $security'),
            Text('Incident Type: $incidentType'),
            Text('Severity: $severity'),
          ],
        ),
      ),
    );
  }
}