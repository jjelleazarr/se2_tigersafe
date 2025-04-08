import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:video_player/video_player.dart';

class ConfirmIncidentReportScreen extends StatefulWidget {
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
    required this.context
  });

  @override
  State<ConfirmIncidentReportScreen> createState() => _ConfirmIncidentReportScreenState();
}

class _ConfirmIncidentReportScreenState extends State<ConfirmIncidentReportScreen> {
  final List<VideoPlayerController> _videoControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  void _initVideos() {
    for (var file in widget.media) {
      if (file.path.endsWith(".mp4") || file.path.endsWith(".mov") || file.path.endsWith(".avi")) {
        final controller = VideoPlayerController.file(file);
        controller.initialize().then((_) {
          setState(() {});
        });
        _videoControllers.add(controller);
      } else {
        _videoControllers.add(VideoPlayerController.file(File(''))); // placeholder
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitIncident(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<String> mediaUrls = [];
      User? user = FirebaseAuth.instance.currentUser;

      for (final file in widget.media) {
        final fileName = file.path.split('/').last;
        final ref = FirebaseStorage.instance.ref().child('incident_media/$fileName');
        await ref.putFile(file);
        mediaUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'title': widget.title,
        'location': widget.location,
        'incident_type': widget.incidentType,
        'description': widget.description,
        'media_urls': mediaUrls,
        'timestamp': Timestamp.now(),
        'created_by': user?.uid,
        'status': 'Pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident submitted successfully.')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving incident: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmAndSubmitIncident(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Report'),
        content: const Text(
            'Please ensure the information you are submitting is accurate. False reports may lead to disciplinary actions. Do you confirm all details are correct?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _submitIncident(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          '$label: $value',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Incident Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailCard("Title", widget.title),
            _buildDetailCard("Location", widget.location),
            _buildDetailCard("Incident Type", widget.incidentType),
            _buildDetailCard("Description", widget.description),

            const SizedBox(height: 10),
            const Text("Attached Media:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.media.length,
                itemBuilder: (context, index) {
                  final file = widget.media[index];
                  final isVideo = file.path.endsWith(".mp4") || file.path.endsWith(".mov") || file.path.endsWith(".avi");

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.black12,
                        width: 200, // Adjusted width
                        height: 200, // Adjusted height
                        child: isVideo && _videoControllers[index].value.isInitialized
                            ? Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _videoControllers[index].value.aspectRatio,
                              child: VideoPlayer(_videoControllers[index]),
                            ),
                            const Icon(Icons.play_circle_fill, size: 40, color: Colors.white70),
                          ],
                        )
                            : !isVideo
                            ? Image.file(file, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _confirmAndSubmitIncident(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SUBMIT REPORT',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
