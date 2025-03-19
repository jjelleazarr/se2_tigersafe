import 'package:flutter/material.dart';

class PriorityVerificationScreen extends StatelessWidget {
  final List<Map<String, String>> requests = [
    {"name": "Pete Mitchell", "role": "Command Center"},
    {"name": "Bradley Bradshaw", "role": "Security"},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            requests[index]['name']!, 
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("Role: ${requests[index]['role']}"),
          trailing: Icon(Icons.check, color: Colors.green),
        );
      },
    );
  }
}
