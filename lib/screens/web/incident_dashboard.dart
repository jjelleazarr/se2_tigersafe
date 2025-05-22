import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/web/incident_report.dart';
import 'package:intl/intl.dart';
import '../../widgets/dashboard_appbar.dart';
import '../../widgets/dashboard_drawer_right.dart';

class IncidentDashboardScreen extends StatefulWidget {
  const IncidentDashboardScreen({super.key});

  @override
  _IncidentDashboardScreenState createState() => _IncidentDashboardScreenState();
}

class _IncidentDashboardScreenState extends State<IncidentDashboardScreen> {
  String? _selectedStatus;
  bool _isAscending = true;
  List<Map<String, dynamic>> _reports = [];

  int _currentPage = 0;
  final int _rowsPerPage = 15;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  String formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(timestamp);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'personnel dispatched':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchReports() async {
    final reportsSnap = await FirebaseFirestore.instance.collection('reports').get();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> reports = [];

    for (var doc1 in reportsSnap.docs) {
      var data1 = doc1.data();
      String createdBy = data1['created_by'];
      List<dynamic> mediaUrls = data1['media_urls'];

      for (var doc in usersSnap.docs) {
        if (createdBy == doc.id.toString()) {
          var data = doc.data();
          reports.add({
            "reporter": "${data['first_name']} ${data['surname']}",
            "location": data1['location'],
            "description": data1['description'],
            "timestamp": data1['timestamp'].toDate(),
            "media_urls": mediaUrls,
            "profile_url": data['profile_image_url'],
            "report_status": data1['status'],
            "report_id": doc1.id
          });
        }
      }
    }

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      reports = reports.where((report) => report['report_status'] == _selectedStatus).toList();
    }

    reports.sort((a, b) => _isAscending
        ? a['timestamp'].compareTo(b['timestamp'])
        : b['timestamp'].compareTo(a['timestamp']));

    setState(() {
      _reports = reports;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_reports.length / _rowsPerPage).ceil();
    int start = _currentPage * _rowsPerPage;
    int end = (_currentPage + 1) * _rowsPerPage;
    List<Map<String, dynamic>> pageItems = _reports.sublist(
      start,
      end > _reports.length ? _reports.length : end,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final bool showStatus = screenWidth >= 1000;
    final bool showDescription = screenWidth >= 850;
    final bool showReporter = screenWidth >= 700;
    final bool showTime = screenWidth >= 600;

    return Scaffold(
      appBar: const DashboardAppBar(),
      endDrawer: DashboardDrawerRight(onSelectScreen: (_) {}),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Incident ',
                        style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                      TextSpan(
                        text: 'Reporting',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Filters: Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                bool isNarrow = constraints.maxWidth < 650;

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSortByDate(),
                          const SizedBox(height: 12),
                          _buildSortByStatus(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSortByDate(),
                          _buildSortByStatus(),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),

            // Table
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text('Location', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                          if (showReporter) Expanded(flex: 2, child: Text('Reporter', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                          if (showDescription) Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                          if (showTime) Expanded(flex: 2, child: Text('Time', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                          if (showStatus) Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: pageItems.map((report) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebIncidentReportScreen(
                                      mediaUrls: report['media_urls'],
                                      location: report['location'],
                                      description: report['description'],
                                      reporter: report['reporter'],
                                      timestamp: report['timestamp'],
                                      profileUrl: report['profile_url'],
                                      reportStatus: report['report_status'],
                                      reportId: report['report_id'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black12)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(report['location'])),
                                    if (showReporter) Expanded(flex: 2, child: Text(report['reporter'])),
                                    if (showDescription) Expanded(flex: 3, child: Text(report['description'], maxLines: 2, overflow: TextOverflow.ellipsis)),
                                    if (showTime) Expanded(flex: 2, child: Text(formatTimestamp(report['timestamp']))),
                                    if (showStatus)
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          report['report_status'],
                                          style: TextStyle(
                                            color: getStatusColor(report['report_status']),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Pagination
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            Text('Page ${_currentPage + 1} of $totalPages'),
                            IconButton(
                              onPressed: _currentPage < totalPages - 1
                                  ? () => setState(() => _currentPage++)
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
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

  Widget _buildSortByDate() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Sorted ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("by date: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          DropdownButton<bool>(
            dropdownColor: Colors.white,
            value: _isAscending,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: true,
                child: Text("Ascending", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              DropdownMenuItem(
                value: false,
                child: Text("Descending", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _isAscending = value!;
                _reports.sort((a, b) => _isAscending
                    ? a['timestamp'].compareTo(b['timestamp'])
                    : b['timestamp'].compareTo(a['timestamp']));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortByStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Sorted ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("by status: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedStatus,
            hint: const Text("Select", style: TextStyle(color: Colors.white, fontSize: 16)),
            underline: const SizedBox(),
            items: ['None', 'Pending', 'Resolved', 'Dropped', 'Personnel Dispatched'].map((String status) {
              return DropdownMenuItem<String>(
                value: status == 'None' ? null : status,
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'None' ? Colors.white : getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedStatus = newValue;
                _fetchReports();
              });
            },
          ),
        ],
      ),
    );
  }
}
