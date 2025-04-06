import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';
import 'package:se2_tigersafe/screens/mobile/safety_text.dart';
import 'package:se2_tigersafe/guides/cpr_guide.dart';
import 'package:se2_tigersafe/guides/emergency_guide.dart';
import 'package:se2_tigersafe/guides/fire_safety_guide.dart';
import 'package:se2_tigersafe/guides/mental_health_guide.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
