import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage(
                'assets/user_placeholder.png'), // Placeholder for user image on top left
          ),
        ),
        title: Center(
          child: Image.asset(
            'assets/ust_icon.png', // Placeholder for UST icon on top
            height: 80,
            width: 100,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 30,
              runSpacing: 30,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureCard(
                    context, 'Incident', 'Reporting', Icons.assignment, ''),
                _buildFeatureCard(
                  //need to change all icons to asset images // need to integrate the "count" from the database
                    context,
                    'Response',
                    'Teams',
                    Icons.medical_services,
                    ''),
                _buildFeatureCard(
                    context, 'Report', 'Logging', Icons.insert_chart, ''),
                _buildFeatureCard(
                    context, 'Announcement', 'Board', Icons.campaign, ''),
              ],
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 30,
              runSpacing: 30,
              alignment: WrapAlignment.center,
              children: [
                _buildEmergencyCard(context, ''),
                _buildEmergencyCard(context, ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      //styling of all boxes
      BuildContext context,
      String title,
      String subtitle, //change the icon to asset image
      IconData icon,
      String count) {
    return Container(
      width: 400,
      height: 270,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFEC00F),
                      fontSize: 30)),
              Text(' $subtitle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            ],
          ),
          Icon(icon, size: 60, color: Colors.blue),
          if (count.isNotEmpty)
            Text(count,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            height: 2,
            color: Colors.black,
            width: double.infinity,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: Icon(Icons.double_arrow_outlined,
                  color: Color(0xFFFEC00F), size: 45),
              onPressed: () {
                print('$title $subtitle clicked');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, String location) {
    return Container(
      width: 400,
      height: 270,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Emergency',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 40)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, size: 50, color: Colors.blue),
              const SizedBox(width: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location:',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                  Text(location, style: TextStyle(fontSize: 30)),
                ],
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            height: 2,
            color: Colors.black,
            width: double.infinity,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: Icon(Icons.double_arrow_outlined,
                  color: Color(0xFFFEC00F), size: 45),
              onPressed: () {
                print('Emergency at $location clicked');
              },
            ),
          ),
        ],
      ),
    );
  }
}