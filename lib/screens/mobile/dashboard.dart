import 'package:flutter/material.dart';
import 'package:se2_tigersafe/screens/mobile/emergency_precall.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';
import 'package:se2_tigersafe/screens/mobile/safety_text.dart';
import 'package:se2_tigersafe/guides/cpr_guide.dart';
import 'package:se2_tigersafe/guides/emergency_guide.dart';
import 'package:se2_tigersafe/guides/fire_safety_guide.dart';
import 'package:se2_tigersafe/guides/mental_health_guide.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _specialization;
  bool? _isERTMember;
  late Future<List<Map<String, dynamic>>> _dispatchesFuture;

  @override
  void initState() {
    super.initState();
    _checkERTMember();
  }

  Future<void> _checkERTMember() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('ert_members')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final spec = snap.docs.first['specialization'] as String?;
      setState(() {
        _isERTMember = true;
        _specialization = spec;
        _dispatchesFuture = _getRelevantDispatches(spec ?? '');
      });
    } else {
      setState(() {
        _isERTMember = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getRelevantDispatches(String specialization) async {
    final Map<String, List<String>> specializationToDispatchFields = {
      'medical': ['medical_team', 'ambulance', 'stretcher'],
      'security': ['security'],
      'others': ['hazard_team'],
    };
    final fields = specializationToDispatchFields[specialization] ?? [];
    if (fields.isEmpty) return [];
    final snap = await FirebaseFirestore.instance.collection('dispatches').get();
    final relevant = snap.docs.where((doc) {
      final data = doc.data();
      return fields.any((field) => data[field] == true);
    }).map((doc) => doc.data()).toList();
    return relevant;
  }

  Stream<List<Map<String, dynamic>>> _getRelevantDispatchesStream(String specialization) {
    final Map<String, List<String>> specializationToDispatchFields = {
      'medical': ['medical_team', 'ambulance', 'stretcher'],
      'security': ['security'],
      'others': ['hazard_team'],
    };
    final fields = specializationToDispatchFields[specialization] ?? [];
    if (fields.isEmpty) return Stream.value([]);
    return FirebaseFirestore.instance.collection('dispatches').snapshots().map((snap) {
      return snap.docs.where((doc) {
        final data = doc.data();
        return fields.any((field) => data[field] == true);
      }).map((doc) => doc.data()).toList();
    });
  }

  void _setScreen(BuildContext context, String identifier) {
    if (identifier == 'filters') {
      // Handle filter selection
    } else {
      Navigator.of(context).pop(); // Close the drawer
    }
  }

  void _openSafetyText(BuildContext context, String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SafetyTextScreen(title: title, content: content),
      ),
    );
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth < 300) return 300;
    if (screenWidth > 500) return 500;
    return 350;
  }

  double _getReportingCardHeight(double screenWidth) {
    if (screenWidth < 300) return 80;
    if (screenWidth > 500) return 90;
    return 90;
  }

  double _getGuideCardHeight(double screenWidth) {
    if (screenWidth < 300) return 120;
    if (screenWidth > 500) return 170;
    return 140;
  }

  @override
  Widget build(BuildContext context) {
    if (_isERTMember == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isERTMember == true) {
      // ERT Dashboard
      return Scaffold(
        appBar: AppBar(
          title: Text('${_specialization?.substring(0, 1).toUpperCase()}${_specialization?.substring(1) ?? ''} Personnel'),
          backgroundColor: Colors.black,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getRelevantDispatchesStream(_specialization ?? ''),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final dispatches = snapshot.data!;
            if (dispatches.isEmpty) {
              return Center(child: Text('No reports found.'));
            }
            return ListView.builder(
              itemCount: dispatches.length,
              itemBuilder: (context, index) {
                final dispatch = dispatches[index];
                return ListTile(
                  title: Text(dispatch['location'] ?? 'Unknown Location'),
                  subtitle: Text(dispatch['description'] ?? ''),
                  trailing: Text(dispatch['incident_type'] ?? ''),
                  onTap: () {
                    // Show details, allow to accept/mark "On the way"
                  },
                );
              },
            );
          },
        ),
      );
    } else {
      // Stakeholder Dashboard (existing logic)
      return _buildStakeholderDashboard(context);
    }
  }

  Widget _buildStakeholderDashboard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = _getResponsiveWidth(screenWidth);
    final double reportingCardHeight = _getReportingCardHeight(screenWidth);
    final double guideCardHeight = _getGuideCardHeight(screenWidth);

    return Scaffold(
      appBar: const DashboardAppBar(),
      drawer: DashboardDrawerLeft(onSelectScreen: (id) => _setScreen(context, id)),
      endDrawer: DashboardDrawerRight(onSelectScreen: (id) => _setScreen(context, id)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Column(
              children: [
                _reportingButton(
                  width: containerWidth,
                  height: reportingCardHeight,
                  icon: Icons.phone,
                  iconColor: Colors.black,
                  text: "Emergency",
                  textColor: Colors.red,
                  subText: "Reporting",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EmergencyPrecallScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _reportingButton(
                  width: containerWidth,
                  height: reportingCardHeight,
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
                const SizedBox(height: 30),
                _infoCard(
                  context,
                  width: containerWidth,
                  height: guideCardHeight,
                  title: "How to Perform CPR",
                  description: "Step-by-step CPR instructions for emergencies.",
                  onTap: () => _openSafetyText(context, "How to Perform CPR", cprText),
                ),
                const SizedBox(height: 10),
                _infoCard(
                  context,
                  width: containerWidth,
                  height: guideCardHeight,
                  title: "Emergency Response Guide",
                  description: "What to do in case of fire, earthquake, or threat.",
                  onTap: () => _openSafetyText(context, "Emergency Response Guide", emergencyGuideText),
                ),
                const SizedBox(height: 10),
                _infoCard(
                  context,
                  width: containerWidth,
                  height: guideCardHeight,
                  title: "Fire Safety Basics",
                  description: "What to do in case of a fire emergency.",
                  onTap: () => _openSafetyText(context, "Fire Safety Basics", fireSafetyGuideText),
                ),
                const SizedBox(height: 10),
                _infoCard(
                  context,
                  width: containerWidth,
                  height: guideCardHeight,
                  title: "Mental Health First Aid",
                  description: "Support someone facing emotional distress.",
                  onTap: () => _openSafetyText(context, "Mental Health First Aid", mentalHealthGuideText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportingButton({
    required double width,
    required double height,
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
        height: height,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(5),
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
                child: Icon(icon, color: iconColor, size: 40),
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

  Widget _infoCard(
    BuildContext context, {
    required double width,
    required double height,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
