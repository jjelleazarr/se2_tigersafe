import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ERTDispatchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dispatch;
  const ERTDispatchDetailScreen({super.key, required this.dispatch});

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp is DateTime ? timestamp : (timestamp.toDate?.call() ?? DateTime.tryParse(timestamp.toString()));
    if (dt == null) return '';
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final attachments = dispatch['attachments'] is List
        ? List<String>.from(dispatch['attachments'])
        : (dispatch['attachments'] is String && dispatch['attachments'].isNotEmpty)
            ? [dispatch['attachments']]
            : <String>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident type tag
            if (dispatch['incident_type'] != null)
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(
                    (dispatch['incident_type'] as String).split(' ').join('\n'),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.red,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            const SizedBox(height: 12),
            // Location
            Text('Location:', style: Theme.of(context).textTheme.titleMedium),
            Text(dispatch['location'] ?? '', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            // Description
            Text('Description of the Incident:', style: Theme.of(context).textTheme.titleMedium),
            Text(dispatch['description'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            // Status
            if (dispatch['status'] != null)
              Text('Status: ${dispatch['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            // Timestamp
            if (dispatch['timestamp'] != null)
              Text('Dispatched At: ${formatTimestamp(dispatch['timestamp'])}'),
            const SizedBox(height: 16),
            // Attachments
            if (attachments.isNotEmpty) ...[
              Text('Media Attachments:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: attachments.map((url) {
                  final isImage = url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png');
                  final isPdf = url.endsWith('.pdf');
                  if (isImage) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                    );
                  } else if (isPdf) {
                    return InkWell(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red)),
                      ),
                    );
                  } else {
                    return InkWell(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.attach_file, size: 40)),
                      ),
                    );
                  }
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            // On the Way button (optional)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                onPressed: () {
                  // TODO: Implement "On the Way" logic
                },
                child: const Text("I'M ON THE WAY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 