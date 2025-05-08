import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/incidents_collection.dart';
import '../../models/reports_collection.dart';
import '../../models/incident_types_collection.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportLoggingDashboardScreen extends StatefulWidget {
  const ReportLoggingDashboardScreen({super.key});

  @override
  State<ReportLoggingDashboardScreen> createState() => _ReportLoggingDashboardScreenState();
}

class _ReportLoggingDashboardScreenState extends State<ReportLoggingDashboardScreen> {
  IncidentModel? _selectedIncident;
  final Map<String, String> _incidentTypeNameCache = {};
  // For refreshing after creation
  final GlobalKey<_IncidentListState> _incidentListKey = GlobalKey();

  Future<String> _getIncidentTypeName(String typeId) async {
    if (_incidentTypeNameCache.containsKey(typeId)) {
      return _incidentTypeNameCache[typeId]!;
    }
    final doc = await FirebaseFirestore.instance.collection('incident_types').doc(typeId).get();
    if (doc.exists) {
      final model = IncidentTypeModel.fromJson(doc.data()!, doc.id);
      _incidentTypeNameCache[typeId] = model.name;
      return model.name;
    }
    return typeId;
  }

  @override
  Widget build(BuildContext context) {
    Future<Widget> _userNameWidget(String uid) async {
      if (uid.isEmpty) return Text(uid);
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return Text(uid);
      final data = doc.data()!;
      final name = ((data['first_name'] ?? '') + ' ' + (data['surname'] ?? '')).trim();
      return Text(name.isNotEmpty ? name : uid);
    }

    Widget _connectedReportsTable(List<String> reportIds) {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('reports').where(FieldPath.documentId, whereIn: reportIds).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('No connected reports.');
          }
          final reports = snapshot.data!.docs;
          return DataTable(
            columns: const [
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Date')),
            ],
            rows: reports.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(data['location'] ?? 'N/A')),
                DataCell(Text(data['description'] ?? 'N/A')),
                DataCell(Text(data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : 'N/A')),
              ]);
            }).toList(),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Logging'),
      ),
      body: Row(
        children: [
          // Incident List with Create Button
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Incidents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Incident'),
                        onPressed: () => Navigator.pushNamed(context, '/incident_create'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: IncidentList(
                    key: _incidentListKey,
                    onSelect: (incident) {
                      setState(() {
                        _selectedIncident = incident;
                      });
                    },
                    getIncidentTypeName: _getIncidentTypeName,
                    selectedIncident: _selectedIncident,
                  ),
                ),
              ],
            ),
          ),
          // Incident Details and Connected Reports
          Expanded(
            flex: 3,
            child: _selectedIncident == null
                ? const Center(child: Text('Select an incident to view details.'))
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getIncidentTypeName(_selectedIncident!.type),
                          builder: (context, typeSnap) {
                            final typeName = typeSnap.data ?? _selectedIncident!.type;
                            return Text('Incident Details', style: Theme.of(context).textTheme.headlineSmall);
                          },
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<String>(
                          future: _getIncidentTypeName(_selectedIncident!.type),
                          builder: (context, typeSnap) {
                            final typeName = typeSnap.data ?? _selectedIncident!.type;
                            return Text('Type: $typeName');
                          },
                        ),
                        Text('Locations: ${_selectedIncident!.locations.isNotEmpty ? _selectedIncident!.locations.join(", ") : "N/A"}'),
                        Text('Status: ${_selectedIncident!.status}'),
                        Text('Reported At: ${_selectedIncident!.reportedAt.toDate()}'),
                        if (_selectedIncident!.updatedAt != null)
                          Text('Updated At: ${_selectedIncident!.updatedAt!.toDate()}'),
                        FutureBuilder<Widget>(
                          future: _userNameWidget(_selectedIncident!.createdBy),
                          builder: (context, snap) => snap.hasData ? Row(children: [const Text('Created By: '), snap.data!]) : Text('Created By: ${_selectedIncident!.createdBy}'),
                        ),
                        if (_selectedIncident!.updatedBy != null)
                          FutureBuilder<Widget>(
                            future: _userNameWidget(_selectedIncident!.updatedBy!),
                            builder: (context, snap) => snap.hasData ? Row(children: [const Text('Updated By: '), snap.data!]) : Text('Updated By: ${_selectedIncident!.updatedBy}'),
                          ),
                        Text('Description: ${_selectedIncident!.description.isNotEmpty ? _selectedIncident!.description : "N/A"}'),
                        if (_selectedIncident!.attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Attachments:'),
                          ..._selectedIncident!.attachments.map((a) => a['url'] != null ? InkWell(
                            onTap: () => launchUrl(Uri.parse(a['url'])),
                            child: Text(a['url'], style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                          ) : const SizedBox.shrink()),
                        ],
                        if (_selectedIncident!.specializations.isNotEmpty)
                          Text('Specializations: ${_selectedIncident!.specializations.join(", ")}'),
                        if (_selectedIncident!.connectedReports.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              const Text('Connected Reports:'),
                              _connectedReportsTable(_selectedIncident!.connectedReports),
                            ],
                          ),
                        const SizedBox(height: 24),
                        Text('ERT Members', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _selectedIncident!.dispatchedMembers.isEmpty
                            ? const Text('No ERT members assigned to this incident.')
                            : FutureBuilder<List<_ERTMemberDisplayInfo>>(
                                future: _fetchERTMembers(_selectedIncident!.dispatchedMembers),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return const Text('No ERT member details found.');
                                  }
                                  final members = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: members.map((m) => ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text(m.name),
                                      subtitle: Text('Specialization: ${m.specialization} | Status: ${m.status}'),
                                    )).toList(),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showReportDetailsDialog(BuildContext context, ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${report.description}'),
              Text('Location: ${report.location}'),
              Text('Status: ${report.status}'),
              Text('Reported At: ${report.reportedAt.toDate()}'),
              if (report.resolvedBy != null) Text('Resolved By: ${report.resolvedBy}'),
              if (report.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Media Attachments:'),
                ...report.mediaUrls.map((url) => Text(url)).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Helper class for ERT member display
class _ERTMemberDisplayInfo {
  final String name;
  final String specialization;
  final String status;
  _ERTMemberDisplayInfo({required this.name, required this.specialization, required this.status});
}

Future<List<_ERTMemberDisplayInfo>> _fetchERTMembers(List<String> memberIds) async {
  final List<_ERTMemberDisplayInfo> result = [];
  final firestore = FirebaseFirestore.instance;
  for (final memberId in memberIds) {
    final ertDoc = await firestore.collection('ert_members').doc(memberId).get();
    if (!ertDoc.exists) continue;
    final ertData = ertDoc.data()!;
    final userId = ertData['user_id'];
    final userDoc = await firestore.collection('users').doc(userId).get();
    String name = userId;
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      name = '${userData['first_name'] ?? ''} ${userData['surname'] ?? ''}'.trim();
    }
    result.add(_ERTMemberDisplayInfo(
      name: name.isNotEmpty ? name : userId,
      specialization: ertData['specialization'] ?? 'N/A',
      status: ertData['status'] ?? 'N/A',
    ));
  }
  return result;
}

// Incident List Widget
class IncidentList extends StatefulWidget {
  final void Function(IncidentModel) onSelect;
  final Future<String> Function(String) getIncidentTypeName;
  final IncidentModel? selectedIncident;
  const IncidentList({super.key, required this.onSelect, required this.getIncidentTypeName, this.selectedIncident});

  @override
  State<IncidentList> createState() => _IncidentListState();
}

class _IncidentListState extends State<IncidentList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('reported_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No incidents found.'));
        }
        final incidents = snapshot.data!.docs
            .map((doc) => IncidentModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        return ListView.builder(
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            return FutureBuilder<String>(
              future: widget.getIncidentTypeName(incident.type),
              builder: (context, typeSnap) {
                final typeName = typeSnap.data ?? incident.type;
                return ListTile(
                  title: Text('$typeName at ${incident.locations.isNotEmpty ? incident.locations.first : "N/A"}'),
                  subtitle: Text(incident.status),
                  selected: widget.selectedIncident?.incidentId == incident.incidentId,
                  onTap: () => widget.onSelect(incident),
                );
              },
            );
          },
        );
      },
    );
  }
} 