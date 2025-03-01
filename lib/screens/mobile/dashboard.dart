import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() {
    return _DashboardScreenState();
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _setScreen(String identifier) {
    if (identifier == 'filters') {
      // Handle filter selection
    } else {
      Navigator.of(context).pop(); // Close the drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(), // ✅ Uses the fixed AppBar
      drawer: DashboardDrawerLeft(onSelectScreen: _setScreen),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _reportingButton(
                icon: Icons.phone,
                iconColor: Colors.black,
                text: "Emergency",
                textColor: Colors.red,
                subText: "Reporting",
              ),
              const SizedBox(height: 20),
              _reportingButton(
                icon: Icons.assignment,
                iconColor: Colors.black,
                text: "Incident",
                textColor: Color(0xFFFEC00F),
                subText: "Reporting",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportingButton({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    required String subText,
  }) {
    return Container(
      height: 80,
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: double.infinity,
            decoration: BoxDecoration(
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
                crossAxisAlignment: CrossAxisAlignment.center, // Centers text
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
    );
  }
}
