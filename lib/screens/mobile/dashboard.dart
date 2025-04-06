import 'package:flutter/material.dart';
import 'package:se2_tigersafe/screens/mobile/emergency_precall.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_left.dart';
import 'package:se2_tigersafe/widgets/dashboard_drawer_right.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() {
    return _DashboardScreenState();
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  late YoutubePlayerController _controller1;
  late YoutubePlayerController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=dQw4w9WgXcQ")!,
      flags: YoutubePlayerFlags(autoPlay: false, mute: false),
    );
    _controller2 = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=3JZ_D3ELwOQ")!,
      flags: YoutubePlayerFlags(autoPlay: false, mute: false),
    );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _reportingButton(
                  icon: Icons.phone,
                  iconColor: Colors.black,
                  text: "Emergency",
                  textColor: Colors.red,
                  subText: "Reporting",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EmergencyPrecallScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _reportingButton(
                  icon: Icons.assignment,
                  iconColor: Colors.black,
                  text: "Incident",
                  textColor: Color(0xFFFEC00F),
                  subText: "Reporting",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const IncidentReportingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _videoThumbnail(_controller1),
                const SizedBox(height: 10),
                _videoThumbnail(_controller2),
              ],
            ),
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
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
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

  Widget _videoThumbnail(YoutubePlayerController controller) {
    return GestureDetector(
      onTap: () {
        _showVideoDialog(controller);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 150,
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              image: DecorationImage(
                image: NetworkImage(YoutubePlayer.getThumbnail(videoId: controller.initialVideoId)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Icon(
            Icons.play_circle_filled,
            color: Colors.red,
            size: 50,
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(YoutubePlayerController controller) {
    setState(() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: YoutubePlayer(controller: controller),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }
}