// Displays the avatar, name, and timestamp
import 'package:flutter/material.dart';

class UserInfo extends StatelessWidget {
  final String name;
  final String profileUrl;
  final String timestamp;

  const UserInfo({
    super.key,
    required this.name,
    required this.profileUrl,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          CircleAvatar(backgroundImage: AssetImage(profileUrl), radius: 16),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(timestamp),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
