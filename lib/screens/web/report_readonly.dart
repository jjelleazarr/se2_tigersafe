import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WebReportReadonlyScreen extends StatelessWidget {
  final List<String> mediaUrls;
  final String location;
  final String description;
  final String reporter;
  final DateTime timestamp;
  final String? profileUrl;
  final String reportStatus;
  final String reportId;

  const WebReportReadonlyScreen({
    super.key,
    required this.mediaUrls,
    required this.location,
    required this.description,
    required this.reporter,
    required this.timestamp,
    this.profileUrl,
    required this.reportStatus,
    required this.reportId,
  });

  String formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location:', style: Theme.of(context).textTheme.titleMedium),
            Text(location, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Description:', style: Theme.of(context).textTheme.titleMedium),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Status: $reportStatus'),
            Text('Reported At: ${formatTimestamp(timestamp)}'),
            const SizedBox(height: 16),
            Row(
              children: [
                if (profileUrl != null && profileUrl!.isNotEmpty)
                  CircleAvatar(backgroundImage: NetworkImage(profileUrl!), radius: 20),
                if (profileUrl != null && profileUrl!.isNotEmpty) const SizedBox(width: 12),
                Text('Reporter: $reporter'),
              ],
            ),
            const SizedBox(height: 24),
            if (mediaUrls.isNotEmpty) ...[
              Text('Media Attachments:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: mediaUrls.map((url) {
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
          ],
        ),
      ),
    );
  }
} 