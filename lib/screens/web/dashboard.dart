import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/mobile/emergency_call.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  _WebDashboardScreenState createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setScreen(String identifier) {
    if (identifier == 'filters') {
      // Handle filter selection
    } else {
      Navigator.of(context).pop(); // Close the drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardAppBar(),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              height: 200, // Adjust height to fit function cards
              child: _buildMainFunctionsSection(context),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 150, // Adjust height to fit emergency reports
              child: _buildEmergencyReportsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFunctionsSection(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Allow horizontal scrolling
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFunctionCard(
            'Incident', 'Reporting', Icons.assignment, '6',
                () => Navigator.pushNamed(context, '/incident_report'),
          ),
          _buildFunctionCard(
            'Response', 'Teams', Icons.medical_services, '',
                () => Navigator.pushNamed(context, '/response_teams'),
          ),
          _buildFunctionCard(
            'Report', 'Logging', Icons.insert_chart, '',
                () => Navigator.pushNamed(context, '/report_logging'),
          ),
          _buildFunctionCard(
            'Announcements', 'Board', Icons.campaign, '',
                () => Navigator.pushNamed(context, '/announcement_board'),
          ),
          _buildFunctionCard(
            'Manage', 'Accounts', Icons.manage_accounts, '',
                () => Navigator.pushNamed(context, '/account_management'),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(String title, String subtitle, IconData icon, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Handle navigation
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Container(
          width: 250,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFFEC00F)),
              ),
              Text(
                subtitle,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Icon(icon, size: 40, color: Colors.blue),
              if (count.isNotEmpty)
                Text(
                  count,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        width: 250,
        height: 150,
        decoration: BoxDecoration(
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
              'Timestamp: ${data['timestamp'].toDate().toString()}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
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
              child: const Text('Join Call'),
            ),
          ],
        ),
      ),
    );
  }
}