import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

import '../../controllers/incidents_controller.dart';
import '../../controllers/incident_types_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../models/incidents_collection.dart';
import '../../models/incident_types_collection.dart';
import '../../models/reports_collection.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/mobile/incident_reporting/location_input.dart';

/// ReportLoggingScreen  –  classic two‑column form
///
/// 1. Pick or create an Incident  →  unlocks the form.
/// 2. "Manage types" lets admin/operator CRUD incident‑types inline.
/// 3. Save Incident   /   Save & Export PDF  (placeholder link).
class ReportLoggingScreen extends StatefulWidget {
  final IncidentModel? initialIncident;
  const ReportLoggingScreen({super.key, this.initialIncident});
  @override
  State<ReportLoggingScreen> createState() => _ReportLoggingScreenState();
}

class _ReportLoggingScreenState extends State<ReportLoggingScreen> {
  // ═══ controllers ══════════════════════════════════════════════
  final _incidentsCtrl = IncidentsController();
  final _reportsCtrl   = ReportsController();
  final _typeCtrl      = IncidentTypeController();

  // ═══ pick‑lists ═══════════════════════════════════════════════
  IncidentModel?      _incident;      // selected / newly created incident
  IncidentTypeModel?  _type;          // dropdown value
  List<IncidentTypeModel> _types = [];

  // ═══ form state ═══════════════════════════════════════════════
  final _formKey      = GlobalKey<FormState>();
  final _location     = TextEditingController();
  final _description  = TextEditingController();
  final _resolvedBy   = TextEditingController();
  final _status       = ValueNotifier<String>('Pending');
  DateTime? _when;                    // date/time field
  List<Uint8List> _files = [];
  bool _saving = false;

  // New fields for advanced incident creation
  final _title = TextEditingController();
  List<String> _selectedErtMembers = [];
  List<String> _selectedSpecializations = [];
  List<String> _selectedReportIds = [];
  List<String> _pickedLocations = [];
  List<IncidentTypeModel> _incidentTypes = [];
  List<Map<String, dynamic>> _ertMembers = [];
  List<Map<String, dynamic>> _allReports = [];
  // Add for dynamic dispatch types
  List<String> _dispatchTypes = [];
  // Attachments for new schema
  List<Map<String, dynamic>> _attachments = [];

  // ══ lifecycle ═════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _refreshTypes();
    _fetchIncidentTypes();
    _fetchErtMembers();
    _fetchReports();
    _fetchDispatchTypes();
    // If editing, pre-fill fields
    if (widget.initialIncident != null) {
      final inc = widget.initialIncident!;
      _title.text = inc.title;
      _description.text = inc.description;
      _selectedErtMembers = List<String>.from(inc.dispatchedMembers);
      _selectedSpecializations = List<String>.from(inc.specializations);
      _selectedReportIds = List<String>.from(inc.connectedReports);
      _pickedLocations = List<String>.from(inc.locations);
      _attachments = List<Map<String, dynamic>>.from(inc.attachments);
      _status.value = inc.status;
      // Set _type if possible
      final type = _incidentTypes.where((t) => t.typeId == inc.type).toList();
      if (type.isNotEmpty) _type = type.first;
    }
  }

  Future<void> _refreshTypes() async {
  try {
    final list = await _typeCtrl.getAllIncidentTypes();   // ⚑ async work first
    if (!mounted) return;
    setState(() => _types = list);                        // ⚑ sync state update
  } catch (e) {
    debugPrint('Error fetching incident types: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot load incident types')),
      );
    }
  }
}

  Future<void> _fetchIncidentTypes() async {
    final snap = await FirebaseFirestore.instance.collection('incident_types').get();
    setState(() {
      _incidentTypes = snap.docs.map((d) => IncidentTypeModel.fromJson(d.data(), d.id)).toList();
    });
  }

  Future<void> _fetchErtMembers() async {
    final snap = await FirebaseFirestore.instance.collection('ert_members').get();
    setState(() {
      _ertMembers = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Future<void> _fetchReports() async {
    final snap = await FirebaseFirestore.instance.collection('reports').get();
    setState(() {
      _allReports = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  // Fetch all unique dispatch type fields from dispatches collection
  Future<void> _fetchDispatchTypes() async {
    final snap = await FirebaseFirestore.instance.collection('dispatches').get();
    final Set<String> types = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      data.forEach((key, value) {
        // Only consider boolean fields that are true/false and not known non-type fields
        if (value is bool &&
            !['resolved', 'active', 'pending', 'false', 'true'].contains(key) &&
            !['description', 'incident_type', 'location', 'media_urls', 'timestamp', 'severity'].contains(key)) {
          types.add(key);
        }
      });
    }
      setState(() {
      _dispatchTypes = types.toList()..sort();
    });
  }

  // Fetch dispatches for selected reports and auto-check types
  Future<void> _autoCheckDispatchTypes() async {
    if (_selectedReportIds.isEmpty) return;
    final snap = await FirebaseFirestore.instance.collection('dispatches').get();
    final Set<String> autoTypes = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      // If this dispatch is related to a selected report (by incident_type or other field)
      if (_selectedReportIds.any((id) => data['report_id'] == id || data['incident_id'] == id)) {
        data.forEach((key, value) {
          if (value == true && _dispatchTypes.contains(key)) {
            autoTypes.add(key);
          }
        });
      }
    }
    setState(() {
      _selectedSpecializations = autoTypes.toList();
    });
  }

  // ══ INCIDENT SELECT / CREATE  DIALOG ══════════════════════════
  /// Opens a mini‑form to create a new incident, returns the saved doc.
  Future<IncidentModel?> _quickCreateIncident() async {
    final formKey   = GlobalKey<FormState>();
    final locCtl    = TextEditingController();
    IncidentTypeModel? t;

    final created   = await showDialog<IncidentModel>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Incident'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<IncidentTypeModel>(
                decoration: const InputDecoration(labelText: 'Incident Type'),
                items: _types
                    .map((tp) => DropdownMenuItem(value: tp, child: Text(tp.name)))
                    .toList(),
                onChanged: (v) => t = v,
                validator: (v) => v == null ? 'Select a type' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: locCtl,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              // ⚑ save incident
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final now = Timestamp.now();
              final model = IncidentModel(
                incidentId: '',
                title: t?.name ?? '',
                type: t!.typeId,
                locations: [locCtl.text.trim()],
                status: 'Pending',
                reportedAt: now,
                updatedAt: now,
                createdBy: user.uid,
                updatedBy: user.uid,
                connectedReports: [],
                dispatchedMembers: [],
                specializations: [],
                description: '',
                attachments: [],
              );
              final id = await _incidentsCtrl.createIncident(model);
              Navigator.pop(context,
                IncidentModel(
                  incidentId: id,
                  title: t?.name ?? '',
                  type: model.type,
                  locations: model.locations,
                  status: model.status,
                  reportedAt: model.reportedAt,
                  updatedAt: model.updatedAt,
                  createdBy: model.createdBy,
                  updatedBy: model.updatedBy,
                  connectedReports: model.connectedReports,
                  dispatchedMembers: model.dispatchedMembers,
                  specializations: model.specializations,
                  description: model.description,
                  attachments: model.attachments,
                ),
              );             // return new doc
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    return created;
  }

  Future<void> _pickIncident() async {
    final snap = await FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('reported_at', descending: true)
        .limit(50)
        .get();

    final incidents = snap.docs
        .map((d) => IncidentModel.fromJson(d.data(), d.id))
        .toList(growable: false);

    final picked = await showDialog<IncidentModel>(
      context: context,
      builder: (_) => _IncidentChooserDialog(
        incidents: incidents,
        onCreate: _quickCreateIncident,
      ),
    );

    if (picked != null) {
      setState(() {
        _incident = picked;
        _location.text = picked.locations.first;
      });
    }
  }

  // ══ MANAGE  INCIDENT TYPES  DIALOG ════════════════════════════
  Future<void> _openTypeManager() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TypeManagerDialog(controller: _typeCtrl),
    );
    _refreshTypes();     // reload dropdown list
  }

  // ══ FILE PICKER ═══════════════════════════════════════════════
  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (res == null) return;
    setState(() => _files =
        res.files.where((f) => f.bytes != null).map((f) => f.bytes!).toList());
  }

  // ══ SAVE  (Incident = primary report) ═════════════════════════
  Future<void> _save({bool export = false}) async {
    if (_incident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick or create an Incident first')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

    // upload files
    final urls = <String>[];
    for (int i = 0; i < _files.length; i++) {
        try {
      final url = await _reportsCtrl.uploadAttachment(
          _files[i], 'report_${_incident!.incidentId}_${DateTime.now().millisecondsSinceEpoch}_$i');
      urls.add(url);
        } catch (e) {
          debugPrint('Error uploading file $i: $e');
          // Continue with other files even if one fails
        }
    }

    // build model
    final model = ReportModel(
      reportId: '',
      incidentId: _incident!.incidentId,
        userId: user.uid,
      typeId: _type?.typeId ?? '',
      description: _description.text.trim(),
      location: _location.text.trim(),
      status: _status.value,
      resolvedBy: _resolvedBy.text.trim().isEmpty ? null : _resolvedBy.text.trim(),
      reportedAt: Timestamp.fromDate(_when ?? DateTime.now()),
      mediaUrls: urls,
      exportUrl: null,
    );

    final reportId = await _reportsCtrl.createReport(model);

    String? pdfUrl;
    if (export) {
        try {
          pdfUrl = await _reportsCtrl.generatePdf(reportId);
      await _reportsCtrl.updateReport(reportId, {'export_url': pdfUrl});
        } catch (e) {
          debugPrint('Error generating PDF: $e');
          // Continue even if PDF generation fails
        }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(export ? 'Incident saved & exported' : 'Incident saved'),
        action: pdfUrl != null
            ? SnackBarAction(label: 'Download', onPressed: () => launchUrl(Uri.parse(pdfUrl!)))
            : null,
      ));
    }

    // clear only per‑report fields
    setState(() {
      _saving = false;
      _description.clear();
      _files.clear();
      _when = null;
      _status.value = 'Pending';
      _resolvedBy.clear();
    });
    } catch (e) {
      debugPrint('Error saving report: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => ErrorDialog(
            message: 'Failed to save report: ${e.toString()}',
            onRetry: () => _save(export: export),
          ),
        );
      }
      setState(() => _saving = false);
    }
  }

  // ══ UI helper ═════════════════════════════════════════════════
  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  // ══ BUILD  ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Get available locations from selected reports
    List<String> availableLocations = _allReports
        .where((r) => _selectedReportIds.contains(r['id']))
        .map((r) => r['location'] as String)
        .toSet()
        .toList();
    return Scaffold(
      appBar: const DashboardAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text.rich(
                    TextSpan(
              children: [
                        TextSpan(
                          text: 'Create/Edit ',
                          style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                        TextSpan(
                          text: 'Incident',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                      ],
                    ),
                  ),
                ),
                      ),
                      const SizedBox(height: 24),
              // Title field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),
              // Description field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),
              // Attachments upload
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: _saving ? null : () async {
                    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
                    if (res == null) return;
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    setState(() => _saving = true);
                    for (final file in res.files) {
                      if (file.bytes != null) {
                        final url = await _reportsCtrl.uploadAttachment(
                          file.bytes!,
                          'incident_attachment_${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
                        );
                        _attachments.add({
                          'type': file.extension ?? 'file',
                          'url': url,
                        });
                      }
                    }
                    setState(() => _saving = false);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.attach_file, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text("Add ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Attachments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              if (_attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: _attachments.map((a) => a['url'] != null
                        ? InkWell(
                            onTap: () => launchUrl(Uri.parse(a['url'])),
                            child: Chip(label: Text(a['url'].toString().split('/').last)))
                        : const SizedBox.shrink()).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              // Incident Type dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<IncidentTypeModel>(
                                      value: _type,
                                      items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                                          .toList(),
                  onChanged: (v) => setState(() => _type = v),
                  decoration: const InputDecoration(
                    labelText: 'Incident Type',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (v) => v == null ? 'Select a type' : null,
                ),
                                    ),
                                    const SizedBox(height: 12),
              // Connect Reports (table)
              ConnectedReportsTable(
                allReports: _allReports,
                selectedReportIds: _selectedReportIds,
                onSelectionChanged: (ids) {
                  setState(() {
                    _selectedReportIds = ids;
                  });
                },
                incidentTypes: _incidentTypes,
                                    ),
                                    const SizedBox(height: 12),
              // Multi-select Location
              if (_selectedReportIds.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Incident Location(s)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Column(
                      children: availableLocations.map((loc) {
                        final selected = _pickedLocations.contains(loc);
                        return CheckboxListTile(
                          value: selected,
                          title: Text(loc),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _pickedLocations.add(loc);
                              } else {
                                _pickedLocations.remove(loc);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (_selectedReportIds.isNotEmpty) const SizedBox(height: 12),
              // Status dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  value: _status.value,
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Personnel Dispatched', child: Text('Personnel Dispatched')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'Dropped', child: Text('Dropped')),
                  ],
                  onChanged: (v) => setState(() => _status.value = v!),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                                    ),
                                    const SizedBox(height: 12),
              // ERT Members Multi-select
              Container(
                                            decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'ERT Members',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Column(
                    children: _ertMembers.map((m) {
                      final selected = _selectedErtMembers.contains(m['id']);
                      return CheckboxListTile(
                        value: selected,
                        title: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(m['user_id']).get(),
                          builder: (context, userSnap) {
                            String name = m['user_id'];
                            if (userSnap.hasData && userSnap.data!.exists) {
                              final userData = userSnap.data!.data() as Map<String, dynamic>;
                              name = '${userData['first_name'] ?? ''} ${userData['surname'] ?? ''}'.trim();
                            }
                            return Text('$name (${m['specialization'] ?? 'N/A'}) - ${m['status'] ?? ''}');
                          },
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedErtMembers.add(m['id']);
                            } else {
                              _selectedErtMembers.remove(m['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Specializations
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Specializations/Dispatch Types',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Column(
                    children: _dispatchTypes.map((spec) {
                      final selected = _selectedSpecializations.contains(spec);
                      return CheckboxListTile(
                        value: selected,
                        title: Text(spec),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedSpecializations.add(spec);
                            } else {
                              _selectedSpecializations.remove(spec);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: _saving ? null : () => _saveIncident(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.save, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text("Save ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Incident", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveIncident() async {
    if (!_formKey.currentState!.validate() || _pickedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and select at least one location.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final now = Timestamp.now();
      if (widget.initialIncident != null) {
        // Update existing
        await FirebaseFirestore.instance.collection('incidents').doc(widget.initialIncident!.incidentId).update({
          'title': _title.text.trim(),
          'type': _type?.typeId ?? '',
          'locations': _pickedLocations,
          'status': _status.value,
          'updated_at': now,
          'updated_by': user.uid,
          'dispatched_members': _selectedErtMembers,
          'specializations': _selectedSpecializations,
          'connected_reports': _selectedReportIds,
          'description': _description.text.trim(),
          'attachments': _attachments,
        });
      } else {
        // Create new
        await FirebaseFirestore.instance.collection('incidents').add({
          'title': _title.text.trim(),
          'type': _type?.typeId ?? '',
          'locations': _pickedLocations,
          'status': _status.value,
          'reported_at': now,
          'created_by': user.uid,
          'updated_at': now,
          'updated_by': user.uid,
          'dispatched_members': _selectedErtMembers,
          'specializations': _selectedSpecializations,
          'connected_reports': _selectedReportIds,
          'description': _description.text.trim(),
          'attachments': _attachments,
        });
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }
}

/// ─────────────────────────────────────────────────────────────
/// DIALOG: choose existing incident or click "New"
/// ─────────────────────────────────────────────────────────────
class _IncidentChooserDialog extends StatelessWidget {
  const _IncidentChooserDialog({
    required this.incidents,
    required this.onCreate,
  });

  final List<IncidentModel> incidents;
  final Future<IncidentModel?> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Incident'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: incidents.isEmpty
            ? const Center(child: Text('No incidents yet'))
            : ListView(
                children: incidents
                    .map((m) => ListTile(
                          title: Text(m.locations.first),
                          subtitle: Text(DateFormat.MMMd()
                              .add_Hm()
                              .format(m.reportedAt.toDate())),
                          onTap: () => Navigator.pop(context, m),
                        ))
                    .toList(),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () async {
            final newInc = await onCreate();
            if (newInc != null && context.mounted) Navigator.pop(context, newInc);
          },
          icon: const Icon(Icons.add),
          label: const Text('New Incident'),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// DIALOG: manage incident types (CRUD)
/// ─────────────────────────────────────────────────────────────
class _TypeManagerDialog extends StatefulWidget {
  const _TypeManagerDialog({required this.controller});
  final IncidentTypeController controller;

  @override
  State<_TypeManagerDialog> createState() => _TypeManagerDialogState();
}

class _TypeManagerDialogState extends State<_TypeManagerDialog> {
  late Future<List<IncidentTypeModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.getAllIncidentTypes();
  }

  Future<void> _refresh() async {
    try {
      final list = await widget.controller.getAllIncidentTypes();
      if (!mounted) return;
      setState(() {
        _future = Future.value(list);
      });
    } catch (e) {
      debugPrint('Error fetching incident types: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openEditor({IncidentTypeModel? type}) async {
    final form = GlobalKey<FormState>();
    final nameCtl = TextEditingController(text: type?.name ?? '');
    final descCtl = TextEditingController(text: type?.description ?? '');
    final prioCtl = TextEditingController(text: '${type?.priorityLevel ?? 1}');

    await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(type == null ? 'Add Type' : 'Edit Type'),
              content: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: descCtl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextFormField(
                      controller: prioCtl,
                      decoration: const InputDecoration(labelText: 'Priority (1‑5)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 1 || n > 5)
                            ? '1‑5'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                      if (!form.currentState!.validate()) return;
                      try {
                      final n = int.parse(prioCtl.text);
                      if (type == null) {
                        await widget.controller.addIncidentType(
                            nameCtl.text.trim(), descCtl.text.trim(), n);
                      } else {
                        await widget.controller.updateIncidentType(
                            type.typeId, nameCtl.text.trim(), descCtl.text.trim(), n);
                      }
                        if (context.mounted) {
                          Navigator.pop(context);
                          _refresh();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    child: const Text('Save')),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Incident Types'),
      content: SizedBox(
        width: 450,
        child: FutureBuilder(
          future: _future,
          builder: (_, snap) {
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading incident types',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snap.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            return ListView(
              children: [
                ...list.map((t) => ListTile(
                      title: Text(t.name),
                      subtitle: Text('Priority ${t.priorityLevel}'),
                      trailing: Wrap(spacing: 8, children: [
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditor(type: t)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                await widget.controller.deleteIncidentType(t.typeId);
                                _refresh();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                }
                              }
                            }),
                      ]),
                    )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New type'),
                  onTap: () => _openEditor(),
                )
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
      ],
    );
  }
}

// Add this widget inside report_logging.dart
class ConnectedReportsTable extends StatefulWidget {
  final List<Map<String, dynamic>> allReports;
  final List<String> selectedReportIds;
  final void Function(List<String>) onSelectionChanged;
  final List<IncidentTypeModel> incidentTypes;
  const ConnectedReportsTable({
    super.key,
    required this.allReports,
    required this.selectedReportIds,
    required this.onSelectionChanged,
    required this.incidentTypes,
  });

  @override
  State<ConnectedReportsTable> createState() => _ConnectedReportsTableState();
}

class _ConnectedReportsTableState extends State<ConnectedReportsTable> {
  String? _selectedStatus;
  bool _isAscending = true;
  String? _sortField = 'reported_at';
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  late List<Map<String, dynamic>> _filteredReports;
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.selectedReportIds);
    _applyFilters();
  }

  @override
  void didUpdateWidget(covariant ConnectedReportsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allReports != widget.allReports) {
      _applyFilters();
    }
    if (oldWidget.selectedReportIds != widget.selectedReportIds) {
      _selectedIds = List<String>.from(widget.selectedReportIds);
    }
  }

  void _applyFilters() {
    _filteredReports = widget.allReports
        .where((r) => (r['status'] ?? '').toString().toLowerCase() != 'pending')
        .toList();
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty && _selectedStatus != 'All') {
      _filteredReports = _filteredReports.where((r) => r['status'] == _selectedStatus).toList();
    }
    _filteredReports.sort((a, b) {
      if (_sortField == 'timestamp') {
        final ta = a['timestamp'];
        final tb = b['timestamp'];
        if (ta == null && tb == null) return 0;
        if (ta == null) return _isAscending ? 1 : -1;
        if (tb == null) return _isAscending ? -1 : 1;
        return _isAscending
            ? (ta as Timestamp).compareTo(tb as Timestamp)
            : (tb as Timestamp).compareTo(ta as Timestamp);
      } else if (_sortField == 'location') {
        return _isAscending
            ? (a['location'] ?? '').compareTo(b['location'] ?? '')
            : (b['location'] ?? '').compareTo(a['location'] ?? '');
      }
      return 0;
    });
    setState(() {});
  }

  String _getIncidentTypeName(dynamic typeId) {
    if (typeId == null) return 'N/A';
    final type = widget.incidentTypes.firstWhere(
      (t) => t.name == typeId || t.typeId == typeId || t.typeId == typeId.toString(),
      orElse: () => IncidentTypeModel(typeId: typeId.toString(), name: typeId.toString(), description: '', priorityLevel: 1),
    );
    return type.name;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showStatus = screenWidth >= 1200;
    final bool showLocation = screenWidth >= 1000;
    final bool showDate = screenWidth >= 800;
    final bool showType = screenWidth >= 600;
    final bool showDescription = screenWidth >= 400;

    int totalPages = (_filteredReports.length / _rowsPerPage).ceil();
    int start = _currentPage * _rowsPerPage;
    int end = (_currentPage + 1) * _rowsPerPage;
    List<Map<String, dynamic>> pageItems = _filteredReports.sublist(
      start,
      end > _filteredReports.length ? _filteredReports.length : end,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Filter by status: '),
            DropdownButton<String>(
              value: _selectedStatus ?? 'All',
              items: ['All', 'Resolved', 'Dropped', 'Personnel Dispatched']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedStatus = v;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 24),
            if (showDate) ...[
              const Text('Sort by: '),
              DropdownButton<String>(
                value: _sortField == 'reported_at' ? 'timestamp' : _sortField,
                items: [
                  DropdownMenuItem(value: 'timestamp', child: Text('Date')),
                  if (showLocation) DropdownMenuItem(value: 'location', child: Text('Location')),
                ],
                onChanged: (v) {
                  setState(() {
                    _sortField = v;
                    _applyFilters();
                  });
                },
              ),
              IconButton(
                icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                    _applyFilters();
                  });
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Checkbox(value: _selectedIds.length == pageItems.length && pageItems.isNotEmpty, onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIds.addAll(pageItems.map((r) => r['id']));
                          _selectedIds = _selectedIds.toSet().toList();
                        } else {
                          _selectedIds.removeWhere((id) => pageItems.any((r) => r['id'] == id));
                        }
                        widget.onSelectionChanged(_selectedIds);
                      });
                    }),
                    if (showLocation) Expanded(flex: 2, child: Text('Location', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                    if (showType) Expanded(flex: 2, child: Text('Incident Type', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                    if (showDescription) Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                    if (showStatus) Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                    if (showDate) Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              ...pageItems.map((r) {
                final selected = _selectedIds.contains(r['id']);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedIds.remove(r['id']);
                      } else {
                        _selectedIds.add(r['id']);
                      }
                      widget.onSelectionChanged(_selectedIds);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(r['id']);
                              } else {
                                _selectedIds.remove(r['id']);
                              }
                              widget.onSelectionChanged(_selectedIds);
                            });
                          },
                        ),
                        if (showLocation) Expanded(flex: 2, child: Text(r['location'] ?? '')),
                        if (showType) Expanded(flex: 2, child: Text(_getIncidentTypeName(r['incident_type']))),
                        if (showDescription) Expanded(flex: 3, child: Text(r['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis)),
                        if (showStatus) Expanded(flex: 2, child: Text(r['status'] ?? '')),
                        if (showDate) Expanded(
                          flex: 2,
                          child: Text(
                            r['timestamp'] != null
                                ? DateFormat('y-MM-dd HH:mm').format((r['timestamp'] as Timestamp).toDate())
                                : 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // Pagination
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text('Page ${_currentPage + 1} of $totalPages'),
                      IconButton(
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
