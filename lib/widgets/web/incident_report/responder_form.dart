// Checkboxes and Dropdowns
import 'package:flutter/material.dart';

class ResponderForm extends StatelessWidget {
  final bool medicalTeam;
  final bool ambulance;
  final bool stretcher;
  final bool hazardTeam;
  final bool security;
  final String? incidentType;
  final String? severity;
  final Function(String, bool) onChanged;
  final Function(String, String?) onDropdownChanged;
  final List<String> incidentTypes;
  final List<String> severityLevels;

  const ResponderForm({
    super.key,
    required this.medicalTeam,
    required this.ambulance,
    required this.stretcher,
    required this.hazardTeam,
    required this.security,
    required this.incidentType,
    required this.severity,
    required this.onChanged,
    required this.onDropdownChanged,
    required this.incidentTypes,
    required this.severityLevels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Responders:',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        CheckboxListTile(
          title: const Text('Medical Team'),
          value: medicalTeam,
          onChanged: (v) => onChanged('medicalTeam', v!),
        ),
        if (medicalTeam)
          Column(
            children: [
              CheckboxListTile(
                title: const Text('Ambulance'),
                value: ambulance,
                onChanged: (v) => onChanged('ambulance', v!),
              ),
              CheckboxListTile(
                title: const Text('Stretcher'),
                value: stretcher,
                onChanged: (v) => onChanged('stretcher', v!),
              ),
            ],
          ),
        CheckboxListTile(
          title: const Text('Hazard Team'),
          value: hazardTeam,
          onChanged: (v) => onChanged('hazardTeam', v!),
        ),
        CheckboxListTile(
          title: const Text('Security'),
          value: security,
          onChanged: (v) => onChanged('security', v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Incident Type'),
          value: incidentType,
          items: incidentTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => onDropdownChanged('incidentType', val),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Severity'),
          value: severity,
          items: severityLevels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => onDropdownChanged('severity', val),
        ),
      ],
    );
  }
}