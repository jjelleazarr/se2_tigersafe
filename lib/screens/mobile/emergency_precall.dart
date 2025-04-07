import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/screens/mobile/emergency_call.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class EmergencyPrecallScreen extends StatefulWidget {
  const EmergencyPrecallScreen({super.key});

  @override
  State<EmergencyPrecallScreen> createState() => _EmergencyPrecallScreenState();
}

class _EmergencyPrecallScreenState extends State<EmergencyPrecallScreen> {
  String _selectedEmergencyType = 'Fire';
  final myController = TextEditingController();
  bool _validateError = false;
  final Uuid uuid = Uuid();

  Future<void> onJoin() async {
    setState(() {
      myController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });

    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);

    String channelName = '${_selectedEmergencyType}_${uuid.v4()}';

    User? user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
       .collection('emergency').add({
      'channel_name': channelName,
      'created_by': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'emergency_type': _selectedEmergencyType,
    });

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmergencyCallScreen(channelName: channelName, emergencyType: _selectedEmergencyType),
        ));
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

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
      appBar: const DashboardAppBar(),
      drawer: DashboardDrawerLeft(onSelectScreen: _setScreen),
      endDrawer: DashboardDrawerRight(onSelectScreen: _setScreen),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select the type of emergency:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Fire'),
              value: 'Fire',
              groupValue: _selectedEmergencyType,
              onChanged: (value) {
                setState(() {
                  _selectedEmergencyType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Robbery'),
              value: 'Robbery',
              groupValue: _selectedEmergencyType,
              onChanged: (value) {
                setState(() {
                  _selectedEmergencyType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Medical Emergency'),
              value: 'Medical Emergency',
              groupValue: _selectedEmergencyType,
              onChanged: (value) {
                setState(() {
                  _selectedEmergencyType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Chemical or Electricity Hazards'),
              value: 'CE Hazards',
              groupValue: _selectedEmergencyType,
              onChanged: (value) {
                setState(() {
                  _selectedEmergencyType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Others'),
              value: 'Others',
              groupValue: _selectedEmergencyType,
              onChanged: (value) {
                setState(() {
                  _selectedEmergencyType = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    onJoin();
                  },
                  child: const Text('Call for Emergency'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
