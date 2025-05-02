// In manage_accounts.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/widgets/web/manage_accounts/add_account_dialog.dart';

class ManageAccountsScreen extends StatefulWidget {
  @override
  _ManageAccountsScreenState createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final List<String> statusOptions = ["Active", "Pending", "Rejected", "Banned"];

  final Map<String, String> roleLabels = {
    "stakeholder": "Stakeholder",
    "command_center_operator": "Command Center Operator",
    "command_center_admin": "Command Center Admin",
    "emergency_response_team": "Emergency Response Team"
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (_) => AddAccountDialog(
              onSubmitted: () => setState(() {}),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text("Add Account"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('users').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No accounts found."));

          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final fullName = "${data['first_name']} ${data['surname']}";
              final String singleRole = (data['roles'] as List).isNotEmpty ? data['roles'][0] : 'unknown';
              final role = roleLabels[singleRole] ?? "Unknown";
              final status = data['account_status'] ?? "Unknown";

              return ListTile(
                tileColor: status == "Banned" ? Colors.red.shade100 : null,
                leading: Icon(Icons.person),
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
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(doc.id)
                            .update({'account_status': 'Banned'});
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(doc.id)
                            .delete();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _editAccount(BuildContext context, String docId, Map<String, dynamic> data) {
    final firstNameController = TextEditingController(text: data['first_name']);
    final middleNameController = TextEditingController(text: data['middle_name']);
    final surnameController = TextEditingController(text: data['surname']);
    final phoneController = TextEditingController(text: data['phone_number']);
    final addressController = TextEditingController(text: data['address']);
    String role = (data['roles'] as List).isNotEmpty ? data['roles'][0] : 'stakeholder';
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
              await FirebaseFirestore.instance.collection('users').doc(docId).update({
                'first_name': firstNameController.text,
                'middle_name': middleNameController.text,
                'surname': surnameController.text,
                'phone_number': phoneController.text,
                'address': addressController.text,
                'roles': [role],
                'account_status': status,
              });
              Navigator.pop(context);
              setState(() {});
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
