import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/screens/web/incident_report.dart';
import 'package:intl/intl.dart';

class IncidentDashboardScreen extends StatelessWidget {
  const IncidentDashboardScreen({super.key});

  String formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(timestamp);
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('reports').get();
    final querySnapshot2 = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> reports = [];
    for (var doc1 in querySnapshot.docs) {
      var data1 = doc1.data();
      String createdBy = data1['created_by'];
      List<dynamic> mediaUrls = data1['media_urls'];
      for (var doc in querySnapshot2.docs) {
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
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(
            child: Image.asset('assets/UST_LOGO_NO_TEXT.png', height: 40)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.report_problem, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Incident ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  'Reporting',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    return const Center(child: Text('Error fetching reports'));
                  }
                  final reports = snapshot.data ?? [];
                  return GridView.builder(
                    itemCount: reports.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300, // ✅ Max width per card
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 3 / 2, // ✅ Card aspect ratio
                    ),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return GestureDetector(
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
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.amber, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        report['location'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  report['description'],
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  "By: ${report['reporter']}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  formatTimestamp(report['timestamp']),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
