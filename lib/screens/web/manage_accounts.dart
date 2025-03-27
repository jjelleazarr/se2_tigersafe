import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/controllers/manage_accounts_controller.dart';

class ManageAccountsScreen extends StatelessWidget {
  final List<String> statusOptions = ["Active", "Pending", "Rejected", "Banned"];

  final Map<String, String> roleLabels = {
    "Stakeholder": "Stakeholder",
    "Command Center Personnel": "Command Center Personnel",
    "Emergency Response Team": "Emergency Response Team",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Accounts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final fullName = "${data['first_name']} ${data['surname']}";
              final role = roleLabels[data['roles']] ?? "Unknown";
              final status = data['account_status'] ?? "Unknown";

              return ListTile(
                tileColor: status == "Banned" ? Colors.red.shade100 : null,
                title: Text(fullName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Role: $role, Account Status: $status"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editAccount(context, doc.id, data),
                    ),
                    IconButton(
                      icon: Icon(Icons.block, color: Colors.orange),
                      onPressed: () async {
                        final controller = ManageAccountsController();
                        await controller.updateStatus(doc.id, "Banned", context);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final controller = ManageAccountsController();
                        await controller.deleteAccount(doc.id, context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editAccount(BuildContext context, String docId, Map<String, dynamic> data) {
    final controller = ManageAccountsController();

    final firstNameController = TextEditingController(text: data['first_name']);
    final middleNameController = TextEditingController(text: data['middle_name']);
    final surnameController = TextEditingController(text: data['surname']);
    final phoneController = TextEditingController(text: data['phone_number']);
    final addressController = TextEditingController(text: data['address']);
    String role = data['roles']?.toString() ?? "Stakeholder";
    String status = data['account_status']?.toString() ?? "Pending";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Account"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: firstNameController, decoration: InputDecoration(labelText: "First Name")),
              TextField(controller: middleNameController, decoration: InputDecoration(labelText: "Middle Name")),
              TextField(controller: surnameController, decoration: InputDecoration(labelText: "Surname")),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone Number")),
              TextField(controller: addressController, decoration: InputDecoration(labelText: "Address")),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: "Role"),
                items: roleLabels.entries
                    .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                    .toList(),
                onChanged: (value) => role = value!,
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(labelText: "Account Status"),
                items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) => status = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await controller.updateAccountFields(
                userId: docId,
                updatedFields: {
                  'first_name': firstNameController.text,
                  'middle_name': middleNameController.text,
                  'surname': surnameController.text,
                  'phone_number': phoneController.text,
                  'address': addressController.text,
                  'roles': role,
                  'account_status': status,
                },
                context: context,
              );
              Navigator.pop(context);
            },
            child: Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : "";
}
