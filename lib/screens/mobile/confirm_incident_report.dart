import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:video_player/video_player.dart';

class ConfirmIncidentReportScreen extends StatelessWidget {
  final String title;
  final String location;
  final String incidentType;
  final String description;
  final List<File> media;
  final dynamic context;

  const ConfirmIncidentReportScreen({
    super.key,
    required this.title,
    required this.location,
    required this.incidentType,
    required this.description,
    required this.media,
    required this.context,
  });


  Future<void> _submitIncident(BuildContext context) async {
    try {
      List<String> mediaUrls = [];
      User? user = FirebaseAuth.instance.currentUser;

      for (final file in media) {
        final fileName = file.path.split('/').last;
        final ref = FirebaseStorage.instance.ref().child('incident_media/$fileName');
        await ref.putFile(file);
        mediaUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'title': title,
        'location': location,
        'incident_type': incidentType,
        'description': description,
        'media_urls': mediaUrls,
        'timestamp': Timestamp.now(),
        'created_by': user?.uid,
        'status': 'Pending',
      });

      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving incident: $e");
    }
  }

  Future<void> _confirmAndSubmitIncident() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Report'),
        content: const Text(
            'Please ensure that the information you are submitting is accurate and truthful. Submitting false reports may result in disciplinary actions. Do you confirm that the details provided are correct?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _submitIncident(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Incident Report')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Title: $title', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Location: $location', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Incident Type: $incidentType', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Description: $description', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Media:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                itemBuilder: (context, index) {
                  final file = media[index];
                  final isVideo = file.path.endsWith(".mp4") || file.path.endsWith(".mov") || file.path.endsWith(".avi");

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isVideo
                        ? AspectRatio(
                      aspectRatio: 9 / 16,
                      child: VideoPlayer(VideoPlayerController.file(file)..initialize()),
                    )
                        : Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _confirmAndSubmitIncident(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}