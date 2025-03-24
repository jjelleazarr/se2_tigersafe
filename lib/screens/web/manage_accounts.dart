import 'package:flutter/material.dart';
import 'package:se2_tigersafe/controllers/manage_accounts_controller.dart';

class ManageAccountsScreen extends StatefulWidget {
  @override
  _ManageAccountsScreenState createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  List<Map<String, String>> accounts = [
    {
      "first_name": "Peter",
      "middle_name": "",
      "surname": "Parker",
      "phone_number": "09123456789",
      "address": "New York City",
      "roles": "/roles/stakeholder",
      "status": "Approved"
    },
    {
      "first_name": "Nathan",
      "middle_name": "",
      "surname": "Drake",
      "phone_number": "09111111111",
      "address": "Boston",
      "roles": "/roles/stakeholder",
      "status": "Pending"
    },
    {
      "first_name": "Jake",
      "middle_name": "",
      "surname": "Seresin",
      "phone_number": "09999999999",
      "address": "Los Angeles",
      "roles": "/roles/stakeholder",
      "status": "Approved"
    },
  ];

  final List<String> statusOptions = [
    "Approved",
    "Pending",
    "Rejected",
    "Banned"
  ];

  void _editAccount(int index) {
    final acc = accounts[index];

    TextEditingController firstNameController =
        TextEditingController(text: acc['first_name']);
    TextEditingController middleNameController =
        TextEditingController(text: acc['middle_name']);
    TextEditingController surnameController =
        TextEditingController(text: acc['surname']);
    TextEditingController phoneController =
        TextEditingController(text: acc['phone_number']);
    TextEditingController addressController =
        TextEditingController(text: acc['address']);
    String role = acc['roles'] ?? "/roles/stakeholder";
    String status = acc['status'] ?? "Pending";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Account"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(labelText: "First Name")),
                TextField(
                    controller: middleNameController,
                    decoration: InputDecoration(labelText: "Middle Name")),
                TextField(
                    controller: surnameController,
                    decoration: InputDecoration(labelText: "Surname")),
                TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: "Phone Number")),
                TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: "Address")),
                DropdownButtonFormField<String>(
                  value: role,
                  items: [
                    DropdownMenuItem(
                      value: "/roles/stakeholder",
                      child: Text("Stakeholder"),
                    ),
                    DropdownMenuItem(
                      value: "/roles/command_center_personnel",
                      child: Text("Command Center"),
                    ),
                    DropdownMenuItem(
                      value: "/roles/emergency_response_team",
                      child: Text("Emergency Response Team"),
                    ),
                  ],
                  onChanged: (value) {
                    role = value!;
                  },
                  decoration: InputDecoration(labelText: "Role"),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: statusOptions
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    status = value!;
                  },
                  decoration: InputDecoration(labelText: "Status"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  accounts[index] = {
                    "first_name": firstNameController.text,
                    "middle_name": middleNameController.text,
                    "surname": surnameController.text,
                    "phone_number": phoneController.text,
                    "address": addressController.text,
                    "roles": role,
                    "status": status,
                  };
                });

                final userId = "some_user_id"; // Replace with actual user document ID
                final controller = ManageAccountsController();

                await controller.adminRoleUpdate(userId, role, context);
                await controller.accountApproval(userId, status.toLowerCase(), context);

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

  void _banAccount(int index) async {
    final userId = "some_user_id"; // Replace with actual user document ID
    final controller = ManageAccountsController();

    // Update local UI state
    setState(() {
      accounts[index]['status'] = "Banned";
    });

    // Then update Firestore
    await controller.accountApproval(userId, "banned", context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Accounts")),
      body: ListView.builder(
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final name = "${accounts[index]['first_name']} ${accounts[index]['surname']}";
          final role = accounts[index]['roles']!.split("/").last;

          return ListTile(
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Role: ${role.capitalize()}, Status: ${accounts[index]['status']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editAccount(index)),
                IconButton(icon: Icon(Icons.block, color: Colors.orange), onPressed: () => _banAccount(index)),
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAccount(index)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Helper to capitalize the first letter
extension StringCasingExtension on String {
  String capitalize() =>
      this.isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : "";
}
