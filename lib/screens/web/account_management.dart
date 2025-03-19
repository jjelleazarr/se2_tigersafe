import 'package:flutter/material.dart';
import 'manage_accounts.dart';
import 'stakeholder_verification.dart';
import 'priority_verification.dart';

class AccountManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Account Verification',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: Colors.black, // Active tab text color
            unselectedLabelColor: Colors.grey, // Inactive tab text color
            indicatorColor: Colors.purple, // Matches mockup
            tabs: [
              Tab(text: "Manage Accounts"),
              Tab(text: "Stakeholder Verification"),
              Tab(text: "Priority Verification"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ManageAccountsScreen(),
            StakeholderVerificationScreen(),
            PriorityVerificationScreen(),
          ],
        ),
      ),
    );
  }
}