import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/incidents_controller.dart';
import '../../controllers/incident_types_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../models/incidents_collection.dart';
import '../../models/incident_types_collection.dart';
import '../../models/reports_collection.dart';

/// ReportLoggingScreen  –  classic two‑column form
///
/// 1. Pick or create an Incident  →  unlocks the form.
/// 2. “Manage types” lets admin/operator CRUD incident‑types inline.
/// 3. Save Incident   /   Save & Export PDF  (placeholder link).
class ReportLoggingScreen extends StatefulWidget {
  const ReportLoggingScreen({super.key});
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

  // ══ lifecycle ═════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _refreshTypes();
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


  // ══ INCIDENT SELECT / CREATE  DIALOG ══════════════════════════
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
        onCreate: _createIncident,
      ),
    );

    if (picked != null) {
      setState(() {
        _incident = picked;
        _location.text = picked.location;
      });
    }
  }

  /// Opens a mini‑form to create a new incident, returns the saved doc.
  Future<IncidentModel?> _createIncident() async {
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
              final model = IncidentModel(
                incidentId: '',
                typeId: t!.typeId,
                location: locCtl.text.trim(),
                status: 'Pending',
                reportedAt: Timestamp.now(),
              );
              final id = await _incidentsCtrl.createIncident(model);
              Navigator.pop(context,
                IncidentModel(
                  incidentId: id,
                  typeId: model.typeId,
                  location: model.location,
                  status: model.status,
                  reportedAt: model.reportedAt,
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

    // upload files
    final urls = <String>[];
    for (int i = 0; i < _files.length; i++) {
      final url = await _reportsCtrl.uploadAttachment(
          _files[i], 'report_${_incident!.incidentId}_${DateTime.now().millisecondsSinceEpoch}_$i');
      urls.add(url);
    }

    // build model
    final model = ReportModel(
      reportId: '',
      incidentId: _incident!.incidentId,
      userId: 'TEMP_UID',                  // replace with auth UID
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
      pdfUrl = 'https://example.com/report_exports/$reportId.pdf'; // placeholder
      await _reportsCtrl.updateReport(reportId, {'export_url': pdfUrl});
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
  }

  // ══ UI helper ═════════════════════════════════════════════════
  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  // ══ BUILD  ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Theme.of(context).colorScheme.onPrimary),
        title: const Text('Report Logging'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident picker / new‑incident
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.assignment),
                  label: Text(_incident == null
                      ? 'Pick Incident'
                      : 'Incident: ${_incident!.incidentId.substring(0, 6)}'),
                  onPressed: _saving ? null : _pickIncident,
                ),
                const SizedBox(width: 16),
                if (_incident != null) Text('(${_incident!.location})'),
              ],
            ),
            const SizedBox(height: 24),

            // ─── The Form Card ────────────────────────────────────
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Please fill out the form',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 24),

                      /// Two‑column responsive layout
                      LayoutBuilder(
                        builder: (_, c) {
                          final narrow = c.maxWidth < 900;
                          return Flex(
                            direction: narrow ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT column
                              Expanded(
                                child: Column(
                                  children: [
                                    // Incident‑type dropdown with manager link
                                    Row(
                                      children: [
                                        const Text('Incident Type',
                                            style: TextStyle(fontSize: 12)),
                                        const Spacer(),
                                        TextButton(
                                            onPressed: _openTypeManager,
                                            child: const Text('Manage types')),
                                      ],
                                    ),
                                    DropdownButtonFormField<IncidentTypeModel>(
                                      value: _type,
                                      items: _types
                                          .map((t) => DropdownMenuItem(
                                              value: t, child: Text(t.name)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _type = v),
                                      validator: (v) =>
                                          v == null ? 'Select type' : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Date & time
                                    TextFormField(
                                      readOnly: true,
                                      decoration: _dec('Date and Time'),
                                      controller: TextEditingController(
                                          text: _when == null
                                              ? ''
                                              : DateFormat.yMMMd()
                                                      .add_Hm()
                                                      .format(_when!)),
                                      onTap: () async {
                                        final now = DateTime.now();
                                        final d = await showDatePicker(
                                            context: context,
                                            initialDate: _when ?? now,
                                            firstDate: now
                                                .subtract(const Duration(days: 365)),
                                            lastDate: now);
                                        if (d == null) return;
                                        final t = await showTimePicker(
                                            context: context,
                                            initialTime:
                                                TimeOfDay.fromDateTime(now));
                                        if (t == null) return;
                                        setState(() => _when = DateTime(
                                            d.year, d.month, d.day, t.hour, t.minute));
                                      },
                                      validator: (_) =>
                                          _when == null ? 'Pick date/time' : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Location
                                    TextFormField(
                                      controller: _location,
                                      decoration: _dec('Location'),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Status dropdown
                                    ValueListenableBuilder<String>(
                                      valueListenable: _status,
                                      builder: (_, value, __) =>
                                          DropdownButtonFormField<String>(
                                        value: value,
                                        decoration: _dec('Status of Incident'),
                                        items: const [
                                          'Pending',
                                          'Personnel Dispatched',
                                          'Resolved',
                                          'Dropped'
                                        ]
                                            .map((s) => DropdownMenuItem(
                                                value: s, child: Text(s)))
                                            .toList(),
                                        onChanged: (v) => _status.value = v!,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Resolved‑by
                                    TextFormField(
                                      controller: _resolvedBy,
                                      decoration: _dec('Resolved By'),
                                    ),
                                  ],
                                ),
                              ),

                              if (!narrow) const SizedBox(width: 32),

                              // RIGHT column
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _description,
                                      maxLines: 10,
                                      decoration:
                                          _dec('Description of the Incident'),
                                      validator: (v) => v == null ||
                                              v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // File drop zone
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Upload your file:'),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: _pickFiles,
                                          child: Container(
                                            height: 110,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: _files.isEmpty
                                                  ? Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.cloud_upload_outlined),
                                                        Text('Drag & Drop'),
                                                        Text('or browse',
                                                            style:
                                                                TextStyle(color: Colors.blue)),
                                                      ],
                                                    )
                                                  : Text('${_files.length} file(s) selected'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saving ? null : () => _save(export: false),
                            icon: const Icon(Icons.save),
                            label: const Text('Save Incident'),   // ⚑ renamed
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _saving ? null : () => _save(export: true),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Save and Export'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// DIALOG: choose existing incident or click “New”
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
                          title: Text(m.location),
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
      final list = await widget.controller.getAllIncidentTypes();   // ① async work
      if (!mounted) return;
      setState(() => _future = Future.value(list));                 // ② sync update
    } catch (e) {
      debugPrint('Error fetching incident types: $e');
    }
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
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            return ListView(
              children: [
                ...list.map((t) => ListTile(
                      title: Text(t.name),
                      subtitle: Text('Priority ${t.priorityLevel}'),
                      trailing: Wrap(spacing: 8, children: [
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await _openEditor(type: t);
                              _refresh();
                            }),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await widget.controller.deleteIncidentType(t.typeId);
                              _refresh();
                            }),
                      ]),
                    )),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New type'),
                  onTap: () async {
                    await _openEditor();
                    _refresh();
                  },
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

  /// opens editor dialog (create if type == null)
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
                      final n = int.parse(prioCtl.text);
                      if (type == null) {
                        await widget.controller.addIncidentType(
                            nameCtl.text.trim(), descCtl.text.trim(), n);
                      } else {
                        await widget.controller.updateIncidentType(
                            type.typeId, nameCtl.text.trim(), descCtl.text.trim(), n);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save')),
              ],
            ));
  }
}
