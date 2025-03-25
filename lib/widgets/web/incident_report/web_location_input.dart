import 'package:flutter/material.dart';

class WebLocationInput extends StatelessWidget {
  final String? locationName;
  final String? staticMapUrl;

  const WebLocationInput({
    super.key,
    required this.locationName,
    required this.staticMapUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 Incident Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Read-only location display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            locationName ?? 'No location data available',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),

        // Static map preview
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: staticMapUrl == null
              ? const Center(child: Text('No map preview available'))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(staticMapUrl!, fit: BoxFit.cover),
                ),
        ),
      ],
    );
  }
}
