import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';

class ERTDashboardScreen extends StatefulWidget {
  final bool medicalTeam;
  final bool ambulance;
  final bool stretcher;
  final bool hazardTeam;
  final bool security;
  final String? incidentType;
  final String? severity;

  const ERTDashboardScreen({
    super.key,
    this.medicalTeam = false,
    this.ambulance = false,
    this.stretcher = false,
    this.hazardTeam = false,
    this.security = false,
    this.incidentType,
    this.severity,
  });

  @override
  State<ERTDashboardScreen> createState() => _ERTDashboardScreenState();
}

class _ERTDashboardScreenState extends State<ERTDashboardScreen> {
  void _setScreen(String identifier) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(),
      drawer: DashboardDrawerLeft(onSelectScreen: _setScreen),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 500 ? 400 : constraints.maxWidth * 0.95;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                width: maxWidth.toDouble(),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟨 Title
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Emergency ',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                            TextSpan(
                              text: 'Personnel',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 📋 Scrollable Reports Section
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            color: Colors.black,
                            child: const Text(
                              "Reports",
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox( //Need the back end part 
                            height: 300, // make scrollable section fixed height
                            child: ListView.builder(
                              itemCount: 10, // You can change this or use real data
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.location_on, color: Colors.amber),
                                  title: Text("Location: UST Report #$index"),
                                  subtitle: const Text("Status: Dispatched"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Chip(
                                        label: Text("Fire"),
                                        backgroundColor: Colors.red,
                                        labelStyle: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ☎️ Emergency
                    _reportingButton(
                      icon: Icons.phone,
                      iconColor: Colors.black,
                      text: "Emergency",
                      textColor: Colors.red,
                      subText: "Reporting",
                    ),

                    // 📝 Incident
                    _reportingButton(
                      icon: Icons.assignment,
                      iconColor: Colors.black,
                      text: "Incident",
                      textColor: const Color(0xFFFEC00F),
                      subText: "Reporting",
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const IncidentReportingScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _reportingButton({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    required String subText,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 80,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: double.infinity,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black, width: 1.5)),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 36),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
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
