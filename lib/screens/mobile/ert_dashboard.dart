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
  String? _ertStatus;
  Map<String, dynamic>? _assignedDispatch;

  @override
  void initState() {
    super.initState();
    _fetchERTStatusAndSpecialization();
  }

  Future<void> _fetchERTStatusAndSpecialization() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('ert_members')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data() as Map<String, dynamic>;
      setState(() {
        _specialization = data['specialization'] as String?;
        _ertStatus = data['status'] as String?;
      });
      // If dispatched or arrived, find the assigned dispatch
      if (_ertStatus == 'Dispatched' || _ertStatus == 'Arrived') {
        final dispatchSnap = await FirebaseFirestore.instance
            .collection('dispatches')
            .where('responders', arrayContains: userId)
            .where('status', isEqualTo: _ertStatus)
            .limit(1)
            .get();
        if (dispatchSnap.docs.isNotEmpty) {
          setState(() {
            _assignedDispatch = {'id': dispatchSnap.docs.first.id, ...dispatchSnap.docs.first.data()};
          });
        } else {
          setState(() {
            _assignedDispatch = null;
          });
        }
      } else {
        setState(() {
          _assignedDispatch = null;
        });
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _getRelevantDispatchesStream(String specialization) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    // First check if user has any active dispatches (where they are a responder)
    return FirebaseFirestore.instance
        .collection('dispatches')
        .where('responders', arrayContains: userId)
        .where('status', whereIn: ['Dispatched', 'Arrived'])
        .snapshots()
        .asyncMap((activeDispatches) async {
          // If user has active dispatches, only show those
          if (activeDispatches.docs.isNotEmpty) {
            return activeDispatches.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          }

          // If no active dispatches, show available dispatches based on specialization
          final Map<String, List<String>> specializationToDispatchFields = {
            'medical': ['medical_team', 'ambulance', 'stretcher'],
            'security': ['security'],
            'others': ['hazard_team'],
          };
          final fields = specializationToDispatchFields[specialization] ?? [];
          if (fields.isEmpty) return [];

          final allDispatches = await FirebaseFirestore.instance
              .collection('dispatches')
              .get();

          return allDispatches.docs.where((doc) {
            final data = doc.data();
            final responders = List<String>.from(data['responders'] ?? []);
            final declined = List<String>.from(data['declined'] ?? []);
            final resolved = List<String>.from(data['resolved'] ?? []);
            
            // Show if matches specialization, not declined, not resolved, and not already a responder
            final matchesSpecialization = fields.any((field) => data[field] == true);
            return matchesSpecialization &&
                   !responders.contains(userId) &&
                   !declined.contains(userId) &&
                   !resolved.contains(userId);
          }).map((doc) => {'id': doc.id, ...doc.data()}).toList();
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
    return Scaffold(
      appBar: const DashboardAppBar(),
      drawer: DashboardDrawerLeft(onSelectScreen: _setScreen),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double containerHeight = constraints.maxHeight * 0.9;
              return Container(
                width: screenWidth < 400 ? screenWidth * 0.98 : 360,
                height: containerHeight,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: (_specialization != null && _specialization!.toLowerCase() == 'medical') ? 'Medical ' : 'Emergency ',
                              style: const TextStyle(
                                color: Color(0xFFFEC00F),
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            TextSpan(
                              text: 'Personnel',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Reports Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Reports',
                              style: TextStyle(
                                color: Color(0xFFFEC00F),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 350,
                            child: _specialization == null || _ertStatus == null
                                ? const Center(child: CircularProgressIndicator())
                                : (_ertStatus == 'Dispatched' || _ertStatus == 'Arrived') && _assignedDispatch != null
                                    ? _buildReportRow(_assignedDispatch!)
                                    : StreamBuilder<List<Map<String, dynamic>>>(
                                        stream: _getRelevantDispatchesStream(_specialization!),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                          final dispatches = snapshot.data!;
                                          if (dispatches.isEmpty) {
                                            return const Center(child: Text('No reports found.', style: TextStyle(fontSize: 16)));
                                          }
                                          return ListView.builder(
                                            itemCount: dispatches.length,
                                            itemBuilder: (context, index) {
                                              final dispatch = dispatches[index];
                                              return _buildReportRow(dispatch);
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(Map<String, dynamic> dispatch) {
    final dispatchId = dispatch['id'];
    if (dispatchId == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Color(0xFFFEC00F)),
        title: Text(
          'Location: ${dispatch['location'] ?? 'Unknown'}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            if (dispatch['incident_type'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                child: Chip(
                  label: Text(
                    dispatch['incident_type'],
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ERTDispatchDetailScreen(dispatch: dispatch, dispatchId: dispatchId),
            ),
          );
        },
      ),
    );
  }
}
