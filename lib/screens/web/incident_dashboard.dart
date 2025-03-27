import 'package:flutter/material.dart';
import 'package:se2_tigersafe/screens/web/incident_report.dart';

class IncidentDashboardScreen extends StatelessWidget {
  const IncidentDashboardScreen({super.key});

  // 🧪 Dummy report data (replace with Firestore later)
  final List<Map<String, dynamic>> reports = const [
    {
      "location": "UST Carpark",
      "description": "Fallen Tree Branch along Parking Entrance",
      "reporter": "Max Verstappen",
      "timestamp": "December 20  8:00PM",
    },
    {
      "location": "Frassati 19th Floor",
      "description": "Exposed Electrical Wires that could make someone trip",
      "reporter": "Yuki Tsunoda",
      "timestamp": "November 30  10:53AM",
    },
    {
      "location": "Dapitan Gate",
      "description": "Broken Glass along the sidewalk",
      "reporter": "Hideo Kojima",
      "timestamp": "October 20  7:25PM",
    },
    {
      "location": "QPAV 3rd Floor",
      "description":
          "Multiple cracks on the floor and the walls, you need to jump to avoid them",
      "reporter": "Dan Santos",
      "timestamp": "October 16  10:01AM",
    },
    {
      "location": "UST Hospital",
      "description":
          "Chemical Contamination due to Chemical Spillage in the Main Lobby",
      "reporter": "Kazuha Nakamura",
      "timestamp": "October 12  5:24PM",
    },
    {
      "location": "Albertus Magnus",
      "description": "A lot of doors can’t be opened due to broken locks",
      "reporter": "Hayoung Ahn",
      "timestamp": "September 18  3:10PM",
    },
  ];

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
              child: GridView.builder(
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
                          builder: (_) => const WebIncidentReportScreen(),
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
                              report['timestamp'],
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
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
