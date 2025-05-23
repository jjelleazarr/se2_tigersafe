import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ERTDispatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dispatch;
  final String dispatchId;
  const ERTDispatchDetailScreen({super.key, required this.dispatch, required this.dispatchId});

  @override
  State<ERTDispatchDetailScreen> createState() => _ERTDispatchDetailScreenState();
}

class _ERTDispatchDetailScreenState extends State<ERTDispatchDetailScreen> {
  String? _ertStatus;
  bool _loading = false;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _fetchERTStatus();
  }

  Future<void> _fetchERTStatus() async {
    setState(() => _loading = true);
    final userId = await _getCurrentUserId();
    final snap = await FirebaseFirestore.instance.collection('ert_members').where('user_id', isEqualTo: userId).limit(1).get();
    if (snap.docs.isNotEmpty) {
      setState(() {
        _ertStatus = snap.docs.first['status'] as String?;
        _resolved = _ertStatus == 'Resolved' || _ertStatus == 'Unable to Respond';
      });
    }
    setState(() => _loading = false);
  }

  Future<String?> _getCurrentUserId() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _updateERTStatus(String newStatus) async {
    setState(() => _loading = true);
    final userId = await _getCurrentUserId();
    print('User ID: $userId');
    if (userId == null) {
      print('User ID is null');
      setState(() => _loading = false);
      return;
    }

    final docId = widget.dispatchId;
    print('Dispatch Doc ID: $docId');
    if (docId == null) {
      print('Dispatch Doc ID is null');
      setState(() => _loading = false);
      return;
    }

    try {
      final dispatchRef = FirebaseFirestore.instance.collection('dispatches').doc(docId);
      final snap = await FirebaseFirestore.instance
          .collection('ert_members')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      print('ERT member docs found: ${snap.docs.length}');
      if (newStatus == 'Dispatched') {
        // Add to responders array (create if missing), set status to Dispatched
        await dispatchRef.update({
          'responders': FieldValue.arrayUnion([userId]),
          'status': 'Dispatched',
        });
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update({'status': 'Dispatched'});
        }
        setState(() {
          _ertStatus = 'Dispatched';
          _resolved = false;
        });
        print('Added to responders and set status to Dispatched');
      } else if (newStatus == 'Unable to Respond') {
        // Add to declined array (create if missing), remove from responders, DO NOT update ert_members status
        await dispatchRef.update({
          'declined': FieldValue.arrayUnion([userId]),
          'responders': FieldValue.arrayRemove([userId]),
        });
        setState(() {
          _ertStatus = null;
          _resolved = true;
        });
        print('Added to declined and removed from responders');
      } else if (newStatus == 'Resolved') {
        // Add to resolved array, remove from responders, set ert_members status to Active
        await dispatchRef.update({
          'resolved': FieldValue.arrayUnion([userId]),
          'responders': FieldValue.arrayRemove([userId]),
        });
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update({'status': 'Active'});
        }
        // Check if there are any remaining responders
        final dispatchDoc = await dispatchRef.get();
        final responders = List<String>.from(dispatchDoc.data()?['responders'] ?? []);
        if (responders.isEmpty) {
          await dispatchRef.update({'status': 'Resolved'});
          print('Dispatch status updated to Resolved');
        }
        setState(() {
          _ertStatus = 'Active';
          _resolved = true;
        });
        print('Added to resolved, removed from responders, set status to Active');
      } else if (newStatus == 'Arrived') {
        // Only update dispatch status to Arrived, and ert_members status to Arrived
        await dispatchRef.update({'status': 'Arrived'});
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update({'status': 'Arrived'});
        }
        setState(() {
          _ertStatus = 'Arrived';
        });
        print('Dispatch and ERT member status updated to Arrived');
      }
    } catch (e, st) {
      print('Firestore update error: $e');
      print(st);
    }
    setState(() => _loading = false);
  }

  Future<void> _refreshDispatch() async {
    final doc = await FirebaseFirestore.instance.collection('dispatches').doc(widget.dispatchId).get();
    if (doc.exists) {
      setState(() {
        widget.dispatch.clear();
        widget.dispatch.addAll(doc.data()!);
      });
    }
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update Status'),
        children: [
          SimpleDialogOption(
            child: const Text('Arrived at Scene'),
            onPressed: () async {
              Navigator.pop(context);
              await _updateERTStatus('Arrived');
              await _refreshDispatch();
            },
          ),
          SimpleDialogOption(
            child: const Text('Incident Resolved'),
            onPressed: () async {
              Navigator.pop(context);
              await _updateERTStatus('Resolved');
              await _refreshDispatch();
              Navigator.pop(context); // Go back to dashboard
            },
          ),
        ],
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp is DateTime ? timestamp : (timestamp.toDate?.call() ?? DateTime.tryParse(timestamp.toString()));
    if (dt == null) return '';
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = widget.dispatch;
    final attachments = dispatch['attachments'] is List
        ? List<String>.from(dispatch['attachments'])
        : (dispatch['attachments'] is String && dispatch['attachments'].isNotEmpty)
            ? [dispatch['attachments']]
            : <String>[];
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final responders = List<String>.from(dispatch['responders'] ?? []);
    final declined = List<String>.from(dispatch['declined'] ?? []);
    final resolved = List<String>.from(dispatch['resolved'] ?? []);
    final isResponder = userId != null && responders.contains(userId);
    final isDeclined = userId != null && declined.contains(userId);
    final isResolved = userId != null && resolved.contains(userId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Dispatch Details',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFEC00F)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    // Status Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 1),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Current Status',
                                    style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(dispatch['status'] ?? ''),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      dispatch['status'] ?? 'Unknown',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dispatched At: ${formatTimestamp(dispatch['timestamp'])}',
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Incident Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 1),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Incident Type Header
                            if (dispatch['incident_type'] != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dispatch['incident_type'],
                                  style: const TextStyle(
                                    color: Color(0xFFFEC00F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),

                            // Location Section
                            _buildInfoSection(
                              'Location',
                              dispatch['location'] ?? '',
                              Icons.location_on,
                              Colors.red,
                            ),
                            const SizedBox(height: 16),

                            // Description Section
                            _buildInfoSection(
                              'Description',
                              dispatch['description'] ?? '',
                              Icons.description,
                              Colors.blue,
                            ),
                            const SizedBox(height: 20),

                            // Attachments Section
                            if (attachments.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Media Attachments',
                                  style: TextStyle(
                                    color: Color(0xFFFEC00F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: attachments.map((url) {
                                  final isImage = url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png');
                                  final isPdf = url.endsWith('.pdf');
                                  if (isImage) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  } else if (isPdf) {
                                    return InkWell(
                                      onTap: () => launchUrl(Uri.parse(url)),
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                                            const SizedBox(height: 8),
                                            Text(
                                              'PDF Document',
                                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return InkWell(
                                      onTap: () => launchUrl(Uri.parse(url)),
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.attach_file, size: 40, color: Colors.blue),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Attachment',
                                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    if (!_resolved) ...[
                      if (isResponder) ...[
                        _buildActionButton(
                          "UPDATE STATUS",
                          Colors.black,
                          _loading ? null : _showUpdateStatusDialog,
                          Icons.update,
                        ),
                      ] else if (!isDeclined && !isResolved) ...[
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width > 400
                                  ? (MediaQuery.of(context).size.width - 56) / 2
                                  : double.infinity,
                              child: _buildActionButton(
                                "I'M ON THE WAY",
                                Colors.black,
                                _loading ? null : () async {
                                  await _updateERTStatus('Dispatched');
                                  await _refreshDispatch();
                                },
                                Icons.directions_run,
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width > 400
                                  ? (MediaQuery.of(context).size.width - 56) / 2
                                  : double.infinity,
                              child: _buildActionButton(
                                "Unable to Respond",
                                Colors.red,
                                _loading ? null : () async {
                                  await _updateERTStatus('Unable to Respond');
                                  await _refreshDispatch();
                                },
                                Icons.cancel,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Text(
                              isDeclined
                                  ? 'You have declined this dispatch.'
                                  : 'You have resolved this dispatch.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback? onPressed, IconData icon) {
    // Determine icon color based on button text
    Color iconColor;
    if (text == "I'M ON THE WAY") {
      iconColor = Colors.blue;
    } else if (text == "Unable to Respond") {
      iconColor = Colors.white;
    } else {
      iconColor = color == Colors.red ? Colors.white : Color(0xFFFEC00F);
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == Colors.red ? Colors.white : Color(0xFFFEC00F),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 1.5),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'dispatched':
        return Colors.blue;
      case 'arrived':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 