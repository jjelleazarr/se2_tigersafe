import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/screens/mobile/emergency_call.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:intl/intl.dart';

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
      final data = doc.data()!;
      final roles = List<String>.from(data['roles'] ?? []);

      setState(() {
        _userRole = roles.contains('command_center_admin') ? 'command_center_admin' : null;
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('emergency').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching emergency reports'));
        }
        final emergencyReports = snapshot.data?.docs ?? [];
        return emergencyReports.isEmpty
            ? Center(
          child: Text(
            'No Emergency Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        )
            : SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Allow horizontal scrolling
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: emergencyReports.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildEmergencyCard(data);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> data) {
    final DateTime timestamp = data['timestamp'].toDate();
    final String formattedTimestamp = DateFormat('MMMM d, y h:mm a').format(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Emergency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red),
            ),
            Text(
              '${data['emergency_type']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              formattedTimestamp,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyCallScreen(
                      channelName: '${data['channel_name']}',
                      emergencyType: '${data['emergency_type']}'
                    ),
                  ),
                );
              },
              child: const Text('Join Call',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
