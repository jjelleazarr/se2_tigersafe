import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final showStatus = screenWidth >= 950;
    final showRole = screenWidth >= 800;
    final showEmail = screenWidth >= 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.white,
                ),
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No accounts found."));
                    }

                    final users = snapshot.data!.docs;

                    return Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: Colors.black,
                          child: Row(
                            children: [
                              const Expanded(flex: 2, child: Text('Name', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                              if (showEmail) const Expanded(flex: 3, child: Text('Email', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                              if (showRole) const Expanded(flex: 2, child: Text('Role', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                              if (showStatus) const Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                              const Expanded(flex: 2, child: Text('Actions', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        // Table Body
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: users.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final fullName = "${data['first_name']} ${data['surname']}";
                                final String singleRole = (data['roles'] as List).isNotEmpty ? data['roles'][0] : 'unknown';
                                final role = roleLabels[singleRole] ?? "Unknown";
                                final status = data['account_status'] ?? "Unknown";
                                final email = data['email'] ?? 'no-email';

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.black12)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(fullName)),
                                      if (showEmail) Expanded(flex: 3, child: Text(email)),
                                      if (showRole) Expanded(flex: 2, child: Text(role)),
                                      if (showStatus) Expanded(flex: 2, child: Text(status)),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () => _editAccount(context, doc.id, data),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.block, color: Colors.orange),
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(doc.id)
                                                    .update({'account_status': 'Banned'});
                                                setState(() {});
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
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
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddAccountDialog(onSubmitted: () => setState(() {})),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.add, color: Color(0xFFFEC00F)),
                label: const Text('Add Account', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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
        title: const Text("Edit Account"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: firstNameController, decoration: const InputDecoration(labelText: "First Name")),
              TextField(controller: middleNameController, decoration: const InputDecoration(labelText: "Middle Name")),
              TextField(controller: surnameController, decoration: const InputDecoration(labelText: "Surname")),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: "Role"),
                items: roleLabels.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                onChanged: (value) => role = value!,
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Account Status"),
                items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (value) => status = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}
