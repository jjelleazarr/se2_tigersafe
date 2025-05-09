import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/action_buttons.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/description_box.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/media_viewer.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/responder_form.dart';
import 'package:se2_tigersafe/widgets/web/incident_report/user_info_card.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:intl/intl.dart';
import 'package:se2_tigersafe/utils/notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

class WebIncidentReportScreen extends StatefulWidget {
  const WebIncidentReportScreen({
    super.key,
    required this.mediaUrls,
    required this.location,
    required this.description,
    required this.reporter,
    required this.timestamp,
    this.profileUrl,
    required this.reportStatus,
    required this.reportId,
  });

  final List<dynamic> mediaUrls;
  final String location;
  final String description;
  final String reporter;
  final DateTime timestamp;
  final String? profileUrl;
  final String reportStatus;
  final String reportId;

  @override
  State<WebIncidentReportScreen> createState() =>
      _WebIncidentReportScreenState();
}

class _WebIncidentReportScreenState extends State<WebIncidentReportScreen> {
  String drop_reason = '';
  bool medicalTeam = false;
  bool ambulance = false;
  bool stretcher = false;
  bool hazardTeam = false;
  bool security = false;

  String? incidentType;
  String? severity;

  late final List<Map<String, String>> mediaList;

  // Store widget properties here
  late String _reportId;
  late String _reportStatus;
  late String _location;
  late String _description;

  @override
  void initState() {
    super.initState();
    mediaList = widget.mediaUrls.map<Map<String, String>>((url) {
      return {
        "type": url.endsWith('.mp4') ? "video" : "image",
        "url": url,
      };
    }).toList();

    // Store widget properties
    _reportId = widget.reportId;
    _reportStatus = widget.reportStatus;
    _location = widget.location;
    _description = widget.description;
  }

  String formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(timestamp);
  }

  final List<String> incidentTypes = [
    'Suspicious Activity',
    'Unsafe Acts',
    'Minor Injury',
    'Obstruction',
    'Structural Damage',
    'Other'
  ];
  final List<String> severityLevels = ['Low', 'Moderate', 'High', 'Critical'];

  void handleDropReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Drop Report"),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select Reason Why The Report Will Be Dropped:"),
                RadioListTile(
                  title: const Text("False Report"),
                  value: "False Report",
                  groupValue: drop_reason,
                  onChanged: (value) => setState(() => drop_reason = value!),
                ),
                RadioListTile(
                  title: const Text("Incident Has Already Cleared"),
                  value: "Incident Has Already Cleared",
                  groupValue: drop_reason,
                  onChanged: (value) => setState(() => drop_reason = value!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Use stored _reportId here
              await FirebaseFirestore.instance
                  .collection('reports')
                  .doc(_reportId)
                  .update({'status': 'Dropped', 'dropReason': drop_reason});

              // Fetch created_by for notification
              final reportDoc = await FirebaseFirestore.instance.collection('reports').doc(_reportId).get();
              final createdBy = reportDoc.data()?['created_by'];
              if (createdBy != null) {
                await NotificationService.sendReportStatusUpdate(
                  userId: createdBy,
                  reportId: _reportId,
                  newStatus: 'Dropped',
                  location: _location,
                  incidentType: incidentType,
                );
              }

              // Notify the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report dropped: $drop_reason')),
              );
              //  Navigate the user back to the incident dashboard
              Navigator.pushReplacementNamed(context, '/incident_dashboard');
            },
            child: const Text("Drop Report"),
          ),
        ],
      ),
    );
  }

  void handleDispatch() {
    if (incidentType == null || severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select incident type and severity.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Dispatch"),
        content: const Text("Are you sure all the information provided is true?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacementNamed(context, '/incident_dashboard');
              print("Dispatching personnel...");
              try {
                // Update the Firestore database with the provided information
                await FirebaseFirestore.instance.collection('dispatches').add({
                  'medical_team': medicalTeam,
                  'ambulance': ambulance,
                  'stretcher': stretcher,
                  'hazard_team': hazardTeam,
                  'security': security,
                  'incident_type': incidentType,
                  'severity': severity,
                  'location': _location,
                  'description': _description,
                  'media_urls': mediaList,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                print("Dispatch information sent to Firestore");
                // Use stored _reportId here
                await FirebaseFirestore.instance
                    .collection('reports')
                    .doc(_reportId)
                    .update({'status': 'Personnel Dispatched'});
                print("Report status updated to 'Personnel Dispatched'");

                // Notify ERT members by specialization
                List<String> responderTypes = [];
                if (medicalTeam) responderTypes.add('medical_team');
                if (ambulance) responderTypes.add('ambulance');
                if (stretcher) responderTypes.add('stretcher');
                if (hazardTeam) responderTypes.add('hazard_team');
                if (security) responderTypes.add('security');

                final Map<String, String> typeToSpecialization = {
                  'medical_team': 'medical',
                  'ambulance': 'medical',
                  'stretcher': 'medical',
                  'security': 'security',
                  'hazard_team': 'others',
                };
                final Set<String> specializations = responderTypes
                    .map((type) => typeToSpecialization[type])
                    .where((spec) => spec != null)
                    .cast<String>()
                    .toSet();

                for (final specialization in specializations) {
                  final ertMembersSnap = await FirebaseFirestore.instance
                      .collection('ert_members')
                      .where('specialization', isEqualTo: specialization)
                      .get();
                  for (final memberDoc in ertMembersSnap.docs) {
                    final userId = memberDoc['user_id'];
                    final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                    final fcmToken = userSnap.data()?['fcm_token'];
                    if (fcmToken == null) continue;
                    final callable = FirebaseFunctions.instance.httpsCallable('sendReportStatusNotification');
                    await callable.call({
                      'userId': userId,
                      'reportId': _reportId,
                      'newStatus': 'Dispatched',
                      'location': _location,
                      'incidentType': incidentType ?? '',
                      'description': _description,
                      'recipientType': 'ert',
                    });
                  }
                }

                // Fetch created_by for notification
                final reportDoc = await FirebaseFirestore.instance.collection('reports').doc(_reportId).get();
                final createdBy = reportDoc.data()?['created_by'];
                if (createdBy != null) {
                  await NotificationService.sendReportStatusUpdate(
                    userId: createdBy,
                    reportId: _reportId,
                    newStatus: 'Personnel Dispatched',
                    location: _location,
                    incidentType: incidentType,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void handleMarkResolved() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark As Resolved"),
        content: const Text("Are you sure you want to mark this report as resolved?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              // Navigate back to IncidentDashboardScreen
              Navigator.pushReplacementNamed(context, '/incident_dashboard');
              try {
                // Update the report status to "Resolved"
                await FirebaseFirestore.instance
                    .collection('reports')
                    .doc(_reportId)
                    .update({'status': 'Resolved'});

                // Fetch created_by for notification
                final reportDoc = await FirebaseFirestore.instance.collection('reports').doc(_reportId).get();
                final createdBy = reportDoc.data()?['created_by'];
                if (createdBy != null) {
                  await NotificationService.sendReportStatusUpdate(
                    userId: createdBy,
                    reportId: _reportId,
                    newStatus: 'Resolved',
                    location: _location,
                    incidentType: incidentType,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const DashboardAppBar(), 
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
                      Text('📍 ${_location}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      MediaViewer(mediaList: mediaList),
                      const SizedBox(height: 24),
                      DescriptionBox(description: _description),
                      const SizedBox(height: 12),
                      UserInfo(
                        name: widget.reporter,
                        profileUrl: widget.profileUrl,
                        timestamp: 'Submitted on ${formatTimestamp(widget.timestamp)}',
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
                      // Add the status placeholder text
                      Text(
                        'Report Status: ${_reportStatus}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  @override
  void dispose() {
    // You can use _reportId and _reportStatus here safely, as they are stored in the state.
    print("Disposing report with ID: $_reportId, Status: $_reportStatus");
    super.dispose();
  }
}