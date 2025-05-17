import 'package:flutter/material.dart';
import 'package:se2_tigersafe/screens/mobile/reports_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardDrawerLeft extends StatelessWidget {
  const DashboardDrawerLeft({super.key, required this.onSelectScreen});

  final void Function(String identifier) onSelectScreen;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login_screen', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          // Header with user name
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
              builder: (context, snapshot) {
                String displayName = 'User';
                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    displayName = [
                      data['first_name'] ?? '',
                      data['middle_name'] ?? '',
                      data['surname'] ?? '',
                    ].where((p) => p.toString().trim().isNotEmpty).join(' ').trim();
                  }
                }
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome, ',
                        style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      TextSpan(
                        text: displayName,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Items
          ListTile(
            leading: const Icon(Icons.account_box, size: 26, color: Colors.blue),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'My ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  TextSpan(
                    text: 'Account',
                    style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, size: 26, color: Colors.blue),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Your ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  TextSpan(
                    text: 'Reports',
                    style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const ReportsListScreen()),
              );
            },
          ),
          const Spacer(),
          // Logout Button
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, size: 26, color: Colors.white),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              onTap: () {
                _logout(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

