import 'package:flutter/material.dart';

class StakeholderVerificationScreen extends StatelessWidget {
  final List<Map<String, String>> requests = [
    {"name": "Elena Fisher", "role": "Professor"},
    {"name": "Victor Sullivan", "role": "Staff"},
  ];

  void _verifyRequest(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Approve Request"),
        content: Text("Approve ${requests[index]['name']} as ${requests[index]['role']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text("Approve")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(requests[index]['name']!),
          subtitle: Text("Role: ${requests[index]['role']}"),
          trailing: IconButton(icon: Icon(Icons.check, color: Colors.green), onPressed: () => _verifyRequest(context, index)),
        );
      },
    );
  }
}
