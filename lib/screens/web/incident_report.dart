import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/action_buttons.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/description_box.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/media_viewer.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/responder_form.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/user_info_card.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';

class WebIncidentReportScreen extends StatefulWidget {
  const WebIncidentReportScreen({super.key});

  @override
  State<WebIncidentReportScreen> createState() =>
      _WebIncidentReportScreenState();
}

class _WebIncidentReportScreenState extends State<WebIncidentReportScreen> {
  String dropReason = '';
  bool medicalTeam = false;
  bool ambulance = false;
  bool stretcher = false;
  bool hazardTeam = false;
  bool security = false;

  String? incidentType;
  String? severity;

  final List<Map<String, String>> mediaList = [
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+1",
    },
    {
      "type": "video",
      "url": "https://www.w3schools.com/html/mov_bbb.mp4",
    },
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+2",
    },
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+2",
    },
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+2",
    },
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+2",
    },
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+2",
    },
    {
      "type": "image",
      "url": "https://via.placeholder.com/300x200.png?text=Image+2",
    },
  ];

  final List<String> incidentTypes = [
    'Tree Obstruction',
    'Fire',
    'Flood',
    'Other'
  ];
  final List<String> severityLevels = ['Low', 'Moderate', 'High', 'Critical'];

  void handleDropReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Drop Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Reason Why The Report Will Be Dropped:"),
            RadioListTile(
              title: const Text("False Report"),
              value: "False Report",
              groupValue: dropReason,
              onChanged: (value) => setState(() => dropReason = value!),
            ),
            RadioListTile(
              title: const Text("Incident Has Already Cleared"),
              value: "Incident Has Already Cleared",
              groupValue: dropReason,
              onChanged: (value) => setState(() => dropReason = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              print("Dropped report: $dropReason");
              Navigator.pop(context);
            },
            child: const Text("Drop Report"),
          ),
        ],
      ),
    );
  }

  void handleDispatch() {
    print("Dispatching responders...");
  }

  void handleMarkResolved() {
    print("Marked as resolved");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const DashboardAppBar(), // ✅ custom app bar
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label:
                  const Text("Back"), // Change to route back to dashboard
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () {
                    Navigator.of(context).pop(); // pop drawer
                    Navigator.of(context).maybePop(); // pop page
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      endDrawer: DashboardDrawerRight(
        onSelectScreen: (identifier) {
          // You can customize this to handle menu actions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped: $identifier')),
          );
        },
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 1000,
                  margin: const EdgeInsets.symmetric(
                      vertical: 10),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: Colors.grey.shade400), // optional: softer border
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📍 UST Carpark',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      MediaViewer(mediaList: mediaList),
                      const SizedBox(height: 24),
                      const DescriptionBox(
                          description:
                          'Fallen Tree Branch along Parking Entrance'),
                      const SizedBox(height: 12),
                      const UserInfo(
                        name: 'Max Verstappen',
                        profileUrl: 'assets/user_avatar.png',
                        timestamp: 'Submitted on October 16, 10:01 AM',
                      ),
                      const SizedBox(height: 24),
                      ResponderForm(
                        medicalTeam: medicalTeam,
                        ambulance: ambulance,
                        stretcher: stretcher,
                        hazardTeam: hazardTeam,
                        security: security,
                        incidentType: incidentType,
                        severity: severity,
                        onChanged: (field, value) => setState(() {
                          switch (field) {
                            case 'medicalTeam':
                              medicalTeam = value;
                              break;
                            case 'ambulance':
                              ambulance = value;
                              break;
                            case 'stretcher':
                              stretcher = value;
                              break;
                            case 'hazardTeam':
                              hazardTeam = value;
                              break;
                            case 'security':
                              security = value;
                              break;
                          }
                        }),
                        onDropdownChanged: (field, value) => setState(() {
                          if (field == 'incidentType') incidentType = value;
                          if (field == 'severity') severity = value;
                        }),
                        incidentTypes: incidentTypes,
                        severityLevels: severityLevels,
                      ),
                      const SizedBox(height: 24),
                      ActionButtons(
                        onDrop: handleDropReport,
                        onDispatch: handleDispatch,
                        onResolve: handleMarkResolved,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}