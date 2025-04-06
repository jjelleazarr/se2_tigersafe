import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:se2_tigersafe/utilities/AppID.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String tokenServerUrl =
kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

class EmergencyCallScreen extends StatefulWidget {
  final String channelName;
  final String emergencyType;

  const EmergencyCallScreen({super.key, required this.channelName, required this.emergencyType});

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isJoined = false; // Track if joined.

  // Function to fetch the Agora token from your server
  Future<String?> fetchAgoraToken({
    required String channelName,
    required int uid,
    required String role,
  }) async {
    try {
      final Uri url = Uri.parse('$tokenServerUrl/rtc/$channelName/$uid/$role'); // Construct the URL
      final http.Response response = await http.get(url); // Make the HTTP request

      if (response.statusCode == 200) {
        // If the request was successful
        final Map<String, dynamic> data = json.decode(response.body); // Decode the JSON response
        final String? token = data['token']; // Extract the token
        return token; // Return the token
      } else {
        // Handle server errors
        print('Failed to fetch token: ${response.statusCode}, body: ${response.body}');
        return null;
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error fetching token: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appID, // Use the App ID from your AppID.dart file
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            setState(() {
              _localUserJoined = true;
              _isJoined = true; // set to true when the local user joins the channel
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");
            setState(() {
              _remoteUid = null;
            });
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint(
                '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
            // Implement token renewal here (important for production)
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {  // listen for leave channel
            print("onLeaveChannel: local user left");
            setState(() {
              _isJoined = false; // set to false when the local user leaves the channel
              _remoteUid = null;
            });
          }
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    // Fetch and use the token:
    await _joinChannel();
  }

  Future<void> _joinChannel() async {
    final String? token = await fetchAgoraToken(
      channelName: widget.channelName,
      uid: 0, // Or your user ID if you have one.
      role: kIsWeb ? 'subscriber' : 'publisher', //  Important:  Set the correct role ('publisher' or 'subscriber')
    );

    if (token != null) {
      await _engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: 0, //  Use 0 for anonymous, or your user ID
        options: const ChannelMediaOptions(),
      );
    } else {
      // Handle the error:  Show a dialog, navigate back, etc.
      print('Failed to get token.  Cannot join channel.');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to connect to the call.  Please check your connection and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('OK'),
            ),
          ],
        ),
      ).then((_) => Navigator.of(context).pop());
    }
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Call'),
      ),
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      //check if the user is joined.
      if (_isJoined) {
        return const Text(
          'Waiting for an officer to join the call.',
          textAlign: TextAlign.center,
        );
      } else {
        return const Center(child: CircularProgressIndicator()); // show indicator
      }
    }
  }
}
