import 'package:flutter/material.dart';

class ManageAccountsScreen extends StatefulWidget {
  @override
  _ManageAccountsScreenState createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  List<Map<String, String>> accounts = [
    {"name": "Peter Parker", "role": "Professor"},
    {"name": "Nathan Drake", "role": "Student"},
    {"name": "Jake Seresin", "role": "Medical"},
  ];

  void _editAccount(int index) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController(text: accounts[index]['name']);
        TextEditingController roleController = TextEditingController(text: accounts[index]['role']);

        return AlertDialog(
          title: Text("Edit Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: roleController, decoration: InputDecoration(labelText: "Role")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  accounts[index]['name'] = nameController.text;
                  accounts[index]['role'] = roleController.text;
                });
                Navigator.pop(context);
              },
              child: Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(int index) {
    setState(() {
      accounts.removeAt(index);
    });
  }

  void _banAccount(int index) {
    setState(() {
      accounts[index]['role'] = "Banned";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Accounts")), // This ensures Material design is applied
      body: ListView.builder(
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              accounts[index]['name']!,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Role: ${accounts[index]['role']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editAccount(index),
                ),
                SizedBox(width: 8), // Spacing between icons
                IconButton(
                  icon: Icon(Icons.block, color: Colors.orange),
                  onPressed: () => _banAccount(index),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAccount(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}