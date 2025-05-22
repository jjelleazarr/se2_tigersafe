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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Two-tone header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title.split(' ').first + ' ',
                        style: const TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 26),
                      ),
                      TextSpan(
                        text: title.split(' ').skip(1).join(' '),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 24),
              // Content Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.black, width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(lines.length, (index) {
                      final line = lines[index].trim();
                      if (line.isEmpty) return const SizedBox(height: 12);
                      if (line.startsWith('🔴') || line.startsWith('🛑') || line.startsWith('🔥') || line.startsWith('🧯') || line.startsWith('🧠')) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            line,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        );
                      } else if (line.startsWith('-') || line.startsWith('*')) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontSize: 16, color: Colors.black)),
                              Expanded(
                                child: Text(
                                  line.substring(1).trim(),
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(line, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
