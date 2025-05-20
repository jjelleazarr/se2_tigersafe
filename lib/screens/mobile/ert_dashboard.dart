import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';
import 'package:se2_tigersafe/screens/mobile/ert_dispatch_detail.dart';

class ERTDashboardScreen extends StatefulWidget {
  const ERTDashboardScreen({super.key});

  @override
  State<ERTDashboardScreen> createState() => _ERTDashboardScreenState();
}

class _ERTDashboardScreenState extends State<ERTDashboardScreen> {
  String? _specialization;

  @override
  void initState() {
    super.initState();
    _fetchSpecialization();
  }

  Future<void> _fetchSpecialization() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('ert_members')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      setState(() {
        _specialization = snap.docs.first['specialization'] as String?;
      });
    }
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

  void _setScreen(String identifier) {
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = _getResponsiveWidth(screenWidth);
    final double reportingCardHeight = _getReportingCardHeight(screenWidth);
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

                    // 📋 Reports Section (now real-time)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
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
                          SizedBox(
                            height: 300, // make scrollable section fixed height
                            child: _specialization == null
                                ? const Center(child: CircularProgressIndicator())
                                : StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: _getRelevantDispatchesStream(_specialization!),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                      final dispatches = snapshot.data!;
                                      if (dispatches.isEmpty) {
                                        return const Center(child: Text('No reports found.'));
                                      }
                                      return ListView.builder(
                                        itemCount: dispatches.length,
                                        itemBuilder: (context, index) {
                                          final dispatch = dispatches[index];
                                          return ListTile(
                                            leading: const Icon(Icons.location_on, color: Colors.amber),
                                            title: Text("Location: "+(dispatch['location'] ?? 'Unknown')),
                                            subtitle: Text("Status: "+(dispatch['status'] ?? 'Dispatched')+"\n"+(dispatch['description'] ?? '')),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (dispatch['incident_type'] != null)
                                                  Chip(
                                                    label: Text(
                                                      (dispatch['incident_type'] as String).split(' ').join('\n'),
                                                      style: const TextStyle(fontSize: 12),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    labelPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_ios, size: 16),
                                              ],
                                            ),
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => ERTDispatchDetailScreen(dispatch: dispatch),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                          )
                        ],
                      ),
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
}
