import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/incidents_collection.dart';
import '../../models/reports_collection.dart';
import '../../models/incident_types_collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:se2_tigersafe/screens/web/report_logging.dart';
import 'package:se2_tigersafe/screens/web/report_readonly.dart';
import 'package:intl/intl.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class ReportLoggingDashboardScreen extends StatefulWidget {
  const ReportLoggingDashboardScreen({super.key});

  @override
  State<ReportLoggingDashboardScreen> createState() => _ReportLoggingDashboardScreenState();
}

class _ReportLoggingDashboardScreenState extends State<ReportLoggingDashboardScreen> {
  IncidentModel? _selectedIncident;
  final Map<String, String> _incidentTypeNameCache = {};
  
  // Add new state variables for table
  String? _selectedStatus;
  bool _isAscending = true;
  int _currentPage = 0;
  final int _rowsPerPage = 15;
  List<IncidentModel> _incidents = [];

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

  // Add helper methods for table
  String formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('MMMM d, y h:mm a');
    return formatter.format(timestamp);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'personnel dispatched':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchIncidents() async {
    final incidentsSnap = await FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('reported_at', descending: !_isAscending)
        .get();

    List<IncidentModel> incidents = incidentsSnap.docs
        .map((doc) => IncidentModel.fromJson(doc.data(), doc.id))
        .toList();

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      incidents = incidents.where((incident) => incident.status == _selectedStatus).toList();
    }

    setState(() {
      _incidents = incidents;
      _currentPage = 0;
    });
  }

  Widget _buildSortByDate() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Sort ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("by date: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          DropdownButton<bool>(
            dropdownColor: Colors.white,
            value: _isAscending,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: true,
                child: Text("Ascending", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              DropdownMenuItem(
                value: false,
                child: Text("Descending", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _isAscending = value;
                });
                _fetchIncidents();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortByStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Sorted ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("by status: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedStatus,
            hint: const Text("Select", style: TextStyle(color: Colors.white, fontSize: 16)),
            underline: const SizedBox(),
            items: ['None', 'Pending', 'Resolved', 'Dropped', 'Personnel Dispatched'].map((String status) {
              return DropdownMenuItem<String>(
                value: status == 'None' ? null : status,
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'None' ? Colors.white : getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedStatus = newValue;
                _fetchIncidents();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsTable() {
    int totalPages = (_incidents.length / _rowsPerPage).ceil();
    int start = _currentPage * _rowsPerPage;
    int end = (_currentPage + 1) * _rowsPerPage;
    List<IncidentModel> pageItems = _incidents.sublist(
      start,
      end > _incidents.length ? _incidents.length : end,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final bool showStatus = screenWidth >= 1000;
    final bool showDescription = screenWidth >= 850;
    final bool showType = screenWidth >= 700;
    final bool showTime = screenWidth >= 600;

    return Column(
      children: [
        // Header with Create Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'All ',
                        style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      TextSpan(
                        text: 'Incidents',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/incident_create'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text("Add ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Incident", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSortByDate(),
              if (showStatus) _buildSortByStatus(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Table
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('Location', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      if (showType) Expanded(flex: 2, child: Text('Type', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      if (showDescription) Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      if (showTime) Expanded(flex: 2, child: Text('Time', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                      if (showStatus) Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                // Table Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: pageItems.map((incident) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIncident = incident;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: const Border(bottom: BorderSide(color: Colors.black12)),
                              color: _selectedIncident?.incidentId == incident.incidentId ? Colors.grey[100] : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    incident.locations.isNotEmpty ? incident.locations.first : "N/A",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                if (showType)
                                  Expanded(
                                    flex: 2,
                                    child: FutureBuilder<String>(
                                      future: _getIncidentTypeName(incident.type),
                                      builder: (context, snapshot) {
                                        return Text(snapshot.data ?? incident.type);
                                      },
                                    ),
                                  ),
                                if (showDescription)
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      incident.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (showTime)
                                  Expanded(
                                    flex: 2,
                                    child: Text(formatTimestamp(incident.reportedAt.toDate())),
                                  ),
                                if (showStatus)
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      incident.status,
                                      style: TextStyle(
                                        color: getStatusColor(incident.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Pagination
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
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

    final screenWidth = MediaQuery.of(context).size.width;
    final bool hideLeft = screenWidth < 600;

    return Scaffold(
      appBar: DashboardAppBar(),
      body: Row(
        children: [
          // Incidents Table
          if (!hideLeft)
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.white,
                child: _buildIncidentsTable(),
              ),
            ),
          // Incident Details
          Expanded(
            flex: 2,
            child: _selectedIncident == null
                ? const Center(child: Text('Select an incident to view details.'))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Incident ',
                                    style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 24),
                                  ),
                                  TextSpan(
                                    text: 'Details',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Basic Info Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 1),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const SizedBox(height: 16),
                                  FutureBuilder<String>(
                                    future: _getIncidentTypeName(_selectedIncident!.type),
                                    builder: (context, typeSnap) {
                                      final typeName = typeSnap.data ?? _selectedIncident!.type;
                                      return _buildInfoRow('Type', typeName);
                                    },
                                  ),
                                  _buildInfoRow('Status', _selectedIncident!.status, valueColor: getStatusColor(_selectedIncident!.status)),
                                  _buildInfoRow('Location', _selectedIncident!.locations.isNotEmpty ? _selectedIncident!.locations.join(", ") : "N/A"),
                                  _buildInfoRow('Reported At', formatTimestamp(_selectedIncident!.reportedAt.toDate())),
                                  if (_selectedIncident!.updatedAt != null)
                                    _buildInfoRow('Updated At', formatTimestamp(_selectedIncident!.updatedAt!.toDate())),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 1),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedIncident!.description.isNotEmpty ? _selectedIncident!.description : "N/A",
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Personnel Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 1),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Personnel Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const SizedBox(height: 16),
                                  FutureBuilder<Widget>(
                                    future: _userNameWidget(_selectedIncident!.createdBy),
                                    builder: (context, snap) => _buildInfoRow('Created By', snap.hasData ? snap.data! : Text(_selectedIncident!.createdBy)),
                                  ),
                                  if (_selectedIncident!.updatedBy != null)
                                    FutureBuilder<Widget>(
                                      future: _userNameWidget(_selectedIncident!.updatedBy!),
                                      builder: (context, snap) => _buildInfoRow('Updated By', snap.hasData ? snap.data! : Text(_selectedIncident!.updatedBy!)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Attachments Card
                          if (_selectedIncident!.attachments.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black, width: 1),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: _selectedIncident!.attachments.map((a) {
                                        final url = a['url'] ?? '';
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
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.black, width: 1),
                                              ),
                                              child: const Center(child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red)),
                                            ),
                                          );
                                        } else {
                                          return InkWell(
                                            onTap: () => launchUrl(Uri.parse(url)),
                                            child: Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.black, width: 1),
                                              ),
                                              child: const Center(child: Icon(Icons.attach_file, size: 40)),
                                            ),
                                          );
                                        }
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Specializations Card
                          if (_selectedIncident!.specializations.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black, width: 1),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Specializations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedIncident!.specializations.map((spec) => Chip(
                                        label: Text(spec),
                                        backgroundColor: Colors.blue[100],
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Connected Reports Card
                          if (_selectedIncident!.connectedReports.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black, width: 1),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Connected Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 16),
                                    FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('reports')
                                          .where(FieldPath.documentId, whereIn: _selectedIncident!.connectedReports)
                                          .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                          return const Text('No connected reports.', style: TextStyle(color: Colors.black87));
                                        }
                                        final reports = snapshot.data!.docs;
                                        return Column(
                                          children: reports.map((doc) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: const BorderSide(color: Colors.black, width: 1),
                                              ),
                                              color: Colors.white,
                                              child: ListTile(
                                                title: Text(data['location'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                                subtitle: Text(data['description'] ?? 'N/A', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
                                                trailing: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: getStatusColor(data['status'] ?? '').withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.black, width: 1),
                                                  ),
                                                  child: Text(
                                                    data['status'] ?? 'N/A',
                                                    style: TextStyle(
                                                      color: getStatusColor(data['status'] ?? ''),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                onTap: () async {
                                                  String reporter = data['user_id'] ?? '';
                                                  String? profileUrl;
                                                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(data['user_id']).get();
                                                  if (userDoc.exists) {
                                                    final userData = userDoc.data() as Map<String, dynamic>;
                                                    reporter = ((userData['first_name'] ?? '') + ' ' + (userData['surname'] ?? '')).trim();
                                                    profileUrl = userData['profile_image_url'];
                                                  }
                                                  if (context.mounted) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => WebReportReadonlyScreen(
                                                          mediaUrls: List<String>.from(data['media_urls'] ?? []),
                                                          location: data['location'] ?? '',
                                                          description: data['description'] ?? '',
                                                          reporter: reporter,
                                                          timestamp: (data['timestamp'] as Timestamp).toDate(),
                                                          profileUrl: profileUrl,
                                                          reportStatus: data['status'] ?? '',
                                                          reportId: doc.id,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ERT Members Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 1),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ERT Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const SizedBox(height: 16),
                                  _selectedIncident!.dispatchedMembers.isEmpty
                                      ? const Text('No ERT members assigned to this incident.', style: TextStyle(color: Colors.black87))
                                      : FutureBuilder<List<_ERTMemberDisplayInfo>>(
                                          future: _fetchERTMembers(_selectedIncident!.dispatchedMembers),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            }
                                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                              return const Text('No ERT member details found.', style: TextStyle(color: Colors.black87));
                                            }
                                            final members = snapshot.data!;
                                            return Column(
                                              children: members.map((m) => Card(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                elevation: 1,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  side: const BorderSide(color: Colors.black, width: 1),
                                                ),
                                                color: Colors.white,
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor: Colors.blue[100],
                                                    child: const Icon(Icons.person, color: Colors.blue),
                                                  ),
                                                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                                  subtitle: Text('Specialization: ${m.specialization}', style: const TextStyle(color: Colors.black87)),
                                                  trailing: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: getStatusColor(m.status).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.black, width: 1),
                                                    ),
                                                    child: Text(
                                                      m.status,
                                                      style: TextStyle(
                                                        color: getStatusColor(m.status),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )).toList(),
                                            );
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Edit Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReportLoggingScreen(
                                        key: UniqueKey(),
                                        initialIncident: _selectedIncident,
                                      ),
                                    ),
                                  );
                                  _fetchIncidents();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.edit, color: Colors.blue, size: 16),
                                    SizedBox(width: 8),
                                    Text("Edit ", style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold, fontSize: 16)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
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

