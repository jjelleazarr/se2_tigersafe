import 'package:flutter/material.dart';
import 'manage_accounts.dart';
import 'stakeholder_verification.dart';
import 'priority_verification.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';

class AccountManagementScreen extends StatefulWidget {
  @override
  _AccountManagementScreenState createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = ['Manage Accounts', 'Stakeholder Verification', 'Priority Verification'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: const DashboardAppBar(),
        endDrawer: DashboardDrawerRight(onSelectScreen: (_) {}),
        body: Column(
          children: [
            const SizedBox(height: 16),

            // Styled Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Account ',
                      style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    TextSpan(
                      text: 'Management',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 32),
              child: TabBar(
                controller: _tabController,
                tabs: tabs.map((label) => Tab(text: label)).toList(),
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black,
                indicatorColor: Colors.blue,
              ),
            ),

            // Tab content
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 32),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ManageAccountsScreen(),
                    StakeholderVerificationScreen(),
                    PriorityVerificationScreen(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
