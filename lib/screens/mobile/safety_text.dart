import 'package:flutter/material.dart';

class SafetyTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const SafetyTextScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index].trim();

          if (line.isEmpty) return const SizedBox(height: 12);

          if (line.startsWith('🔴') || line.startsWith('🛑') || line.startsWith('🔥') || line.startsWith('🧯') || line.startsWith('🧠')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          } else if (line.startsWith('-') || line.startsWith('*')) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      line.substring(1).trim(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          } else if (line.contains(':')) {
            final parts = line.split(':');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(text: '${parts[0]}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: parts.sublist(1).join(':').trim()),
                  ],
                ),
              ),
            );
          }

          return Text(line, style: const TextStyle(fontSize: 16, height: 1.5));
        },
      ),
    );
  }
}
