import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/models/ert_members_collection.dart';
import 'package:se2_tigersafe/controllers/ert_members_controller.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class ResponseTeamsScreen extends StatefulWidget {
  @override
  _ResponseTeamsScreenState createState() => _ResponseTeamsScreenState();
}

class _ResponseTeamsScreenState extends State<ResponseTeamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> specializations = ['medical', 'security', 'others'];
  final ERTMemberController _controller = ERTMemberController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: specializations.length, vsync: this);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'dispatched':
        return Colors.red;
      case 'offline':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPersonnelTable(String specialization) {
    return StreamBuilder<List<ERTMemberModel>>(
      stream: _controller.streamAllERTMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No personnel available."));

        final filtered = snapshot.data!.where((e) => e.specialization == specialization).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(filtered.map((member) async {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(member.userId).get();
            String fullName = "Unknown User";
            if (userDoc.exists) {
              final user = userDoc.data()!;
              fullName = [
                user['first_name'] ?? '',
                user['middle_name'] ?? '',
                user['surname'] ?? ''
              ].where((name) => name.trim().isNotEmpty).join(' ');
            }
            return {
              'member': member,
              'name': fullName,
            };
          })),
          builder: (context, innerSnapshot) {
            if (innerSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
            if (!innerSnapshot.hasData || innerSnapshot.data!.isEmpty) return Center(child: Text("No personnel found."));

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text('Name', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                        Text('Status', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ...innerSnapshot.data!.map((entry) {
                    final member = entry['member'] as ERTMemberModel;
                    final fullName = entry['name'] as String;

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 8),
                                Text(fullName),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(member.status),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              member.status,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 16),
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
                    text: 'Emergency ',
                    style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  TextSpan(
                    text: 'Personnel',
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
              tabs: specializations.map((label) {
                return Tab(text: label.capitalize() + ' Personnel');
              }).toList(),
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.blue,
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 32),
              child: TabBarView(
                controller: _tabController,
                children: specializations.map(_buildPersonnelTable).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
