import 'package:flutter/material.dart';
import 'manage_accounts.dart';
import 'stakeholder_verification.dart';
import 'priority_verification.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class AccountManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const DashboardAppBar(),
        body: Column(
          children: [
            // Header: Account Management
            const SizedBox(height: 10),
            const Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Account ',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Management',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFEC00F)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tabs
            const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              indicator: BoxDecoration(color: Colors.blue),
              tabs: [
                Tab(text: "Manage Accounts"),
                Tab(text: "Stakeholder Verification"),
                Tab(text: "Priority Verification"),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  ManageAccountsScreen(),
                  StakeholderVerificationScreen(),
                  PriorityVerificationScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
