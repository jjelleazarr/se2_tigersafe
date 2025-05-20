import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ERTDispatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dispatch;
  const ERTDispatchDetailScreen({super.key, required this.dispatch});

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
    final snap = await FirebaseFirestore.instance.collection('ert_members').where('user_id', isEqualTo: userId).limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'status': newStatus});
      setState(() {
        _ertStatus = newStatus;
        _resolved = newStatus == 'Resolved' || newStatus == 'Unable to Respond';
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _updateDispatchStatus(String newStatus) async {
    final docId = widget.dispatch['id'] ?? widget.dispatch['doc_id'];
    if (docId != null) {
      await FirebaseFirestore.instance.collection('dispatches').doc(docId).update({'status': newStatus});
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
              await _updateDispatchStatus('Arrived');
            },
          ),
          SimpleDialogOption(
            child: const Text('Incident Resolved'),
            onPressed: () async {
              Navigator.pop(context);
              await _updateERTStatus('Resolved');
              await _updateDispatchStatus('Resolved');
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_ertStatus == null || _ertStatus == 'Active')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            onPressed: _loading
                                ? null
                                : () async {
                                    await _updateERTStatus('Dispatched');
                                    await _updateDispatchStatus('Dispatched');
                                  },
                            child: const Text("I'M ON THE WAY"),
                          )
                        else if (_ertStatus == 'Dispatched' || _ertStatus == 'Arrived')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            onPressed: _loading ? null : _showUpdateStatusDialog,
                            child: const Text("UPDATE STATUS"),
                          ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _loading
                              ? null
                              : () async {
                                  await _updateERTStatus('Unable to Respond');
                                  await _updateDispatchStatus('Unable to Respond');
                                  Navigator.pop(context); // Go back to dashboard
                                },
                          child: const Text("Unable to Respond"),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
    );
  }
} 