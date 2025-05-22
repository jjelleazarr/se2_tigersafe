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
            },
          ),
          SimpleDialogOption(
            child: const Text('Incident Resolved'),
            onPressed: () async {
              Navigator.pop(context);
              await _updateERTStatus('Resolved');
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
      appBar: AppBar(
        title: const Text('Dispatch Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident type tag
            if (dispatch['incident_type'] != null)
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(
                    (dispatch['incident_type'] as String).split(' ').join('\n'),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: Colors.red,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            const SizedBox(height: 12),
            // Location
            Text('Location:', style: Theme.of(context).textTheme.titleMedium),
            Text(dispatch['location'] ?? '', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            // Description
            Text('Description of the Incident:', style: Theme.of(context).textTheme.titleMedium),
            Text(dispatch['description'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            // Status
            if (dispatch['status'] != null)
              Text('Status: ${dispatch['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            // Timestamp
            if (dispatch['timestamp'] != null)
              Text('Dispatched At: ${formatTimestamp(dispatch['timestamp'])}'),
            const SizedBox(height: 16),
            // Attachments
            if (attachments.isNotEmpty) ...[
              Text('Media Attachments:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: attachments.map((url) {
                  final isImage = url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png');
                  final isPdf = url.endsWith('.pdf');
                  if (isImage) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                    );
                  } else if (isPdf) {
                    return InkWell(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red)),
                      ),
                    );
                  } else {
                    return InkWell(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.attach_file, size: 40)),
                      ),
                    );
                  }
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            if (!_resolved) ...[
              if (isResponder) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        onPressed: _loading ? null : _showUpdateStatusDialog,
                        child: const Text("UPDATE STATUS"),
                      ),
                    ),
                  ],
                ),
              ] else if (!isDeclined && !isResolved) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                await _updateERTStatus('Dispatched');
                              },
                        child: const Text("I'M ON THE WAY"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                await _updateERTStatus('Unable to Respond');
                              },
                        child: const Text("Unable to Respond"),
                      ),
                    ),
                ],
              ),
              ] else ...[
                Center(
                  child: Text(
                    isDeclined
                        ? 'You have declined this dispatch.'
                        : 'You have resolved this dispatch.',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }
} 