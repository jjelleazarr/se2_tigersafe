import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  _WebDashboardScreenState createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc['roles'];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setScreen(String identifier) {
    if (identifier == 'filters') {
      // Future logic for filters
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: DashboardAppBar(),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainFunctionsSection(context),
            const SizedBox(height: 60),
            _buildEmergencyReportsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFunctionsSection(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          _buildFunctionCard('Incident', 'Reporting', Icons.assignment, '6',
              () => Navigator.pushNamed(context, '/incident_report')),
          _buildFunctionCard('Response', 'Teams', Icons.medical_services, '',
              () => Navigator.pushNamed(context, '/response_teams')),
          _buildFunctionCard('Report', 'Logging', Icons.insert_chart, '',
              () => Navigator.pushNamed(context, '/report_logging')),
          _buildFunctionCard('Announcements', 'Board', Icons.campaign, '',
              () => Navigator.pushNamed(context, '/announcement_board')),
          if (_userRole == 'command_center_admin')
            _buildFunctionCard('Manage', 'Accounts', Icons.manage_accounts, '',
                () => Navigator.pushNamed(context, '/account_management')),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(
      String title, String subtitle, IconData icon, String count, VoidCallback onTap) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double cardWidth = screenWidth > 700 ? 400 : screenWidth * 0.9;
    double cardHeight = screenHeight > 900 ? 200 : screenHeight * 0.2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFFEC00F)),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Icon(icon, size: 40, color: Colors.blue),
            if (count.isNotEmpty)
              Text(
                count,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyReportsSection() {
    List<String> emergencyReports = []; // Replace with Firebase data

    return emergencyReports.isEmpty
        ? Center(
            child: Text(
              'No Emergency Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          )
        : Wrap(
            spacing: 20,
            runSpacing: 20,
            children: emergencyReports
                .map((location) => _buildEmergencyCard(location))
                .toList(),
          );
  }

  Widget _buildEmergencyCard(String location) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double cardWidth = screenWidth > 600 ? 250 : screenWidth * 0.9;
    double cardHeight = screenHeight > 800 ? 150 : screenHeight * 0.18;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Emergency',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red),
          ),
          Text(
            'Location: $location',
            style: const TextStyle(fontSize: 16),
          ),
          const Icon(Icons.phone, size: 40, color: Colors.blue),
        ],
      ),
    );
  }
}
