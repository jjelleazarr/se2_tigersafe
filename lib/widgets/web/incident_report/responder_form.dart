import 'package:flutter/material.dart';

class ResponderForm extends StatelessWidget {
  final bool medicalTeam;
  final bool ambulance;
  final bool stretcher;
  final bool hazardTeam;
  final bool security;
  final String? incidentType;
  final String? severity;
  final String? additionalInfo;

  final Function(String field, bool value) onChanged;
  final Function(String field, String? value) onDropdownChanged;
  final Function(String value)? onAdditionalInfoChanged;

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
    this.onAdditionalInfoChanged,
    this.additionalInfo,
    required this.incidentTypes,
    required this.severityLevels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🚑 Responders',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        CheckboxListTile(
          title: const Text('Medical Team'),
          value: medicalTeam,
          onChanged: (v) => onChanged('medicalTeam', v!),
        ),
        if (medicalTeam) ...[
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
          value: incidentType,
          decoration: const InputDecoration(labelText: 'Incident Type'),
          items: incidentTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (val) => onDropdownChanged('incidentType', val),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: severity,
          decoration: const InputDecoration(labelText: 'Severity'),
          items: severityLevels
              .map((level) => DropdownMenuItem(value: level, child: Text(level)))
              .toList(),
          onChanged: (val) => onDropdownChanged('severity', val),
        ),

        const SizedBox(height: 20),

        // ✅ Additional Info
        TextField(
          decoration: const InputDecoration(
            labelText: 'Additional Information (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: onAdditionalInfoChanged,
          controller: TextEditingController(text: additionalInfo),
        ),
      ],
    );
  }
}