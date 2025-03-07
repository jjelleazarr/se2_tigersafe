import 'package:flutter/material.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/widgets/footer.dart'; 

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
            );
          },
        ),
        title: const Text(
          'Reports',
          style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Reports List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: ListView(
                children: [
                  // Add the Report Logs here, I don't know how you guys will implement the extraction of data and placing them as arguments but maybe use a while loop??
                  // while(data != null) {
                  //   _reportLog(data.title, data.status, data.statusColor); } something like this??? Unless you guys got a better idea
                  _reportLog('Report 1', 'Pending', Colors.orange), // for Testing purposes, please remove this later
                ],
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  // Report List Item
  Widget _reportLog(String title, String status, Color statusColor) { // change whatever needed, maybe add the statusColor part in a model since like the color is dependent on the status enums
    return Container( // so maybe remove the statusColor parameter and just pass the status?? // also needs a new model file I guess for the status?? not sure 
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor, // should depend on the status
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.chevron_right), 
                color: Colors.black,
                iconSize: 24,
                onPressed: () {
                  //Navigator
                },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
