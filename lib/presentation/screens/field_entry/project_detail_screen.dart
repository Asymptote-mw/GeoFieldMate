import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/project.dart';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import 'field_entry_screen.dart';
import 'record_detail_screen.dart';
import '../visualization/visualization_screen.dart';
import '../export/export_screen.dart';
import '../interpretation/interpretation_screen.dart';

/// Screen showing details of a specific project and its records
class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<FieldRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _dbHelper.getFieldRecordsByProject(widget.project.id);
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _createFieldRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FieldEntryScreen(projectId: widget.project.id),
      ),
    );

    if (result == true) {
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      InterpretationScreen(projectId: widget.project.id),
                ),
              );
            },
            tooltip: 'AI Interpretation',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VisualizationScreen(projectId: widget.project.id),
                ),
              );
            },
            tooltip: 'Visualize Data',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExportScreen(project: widget.project),
                ),
              );
            },
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Project info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.project.location != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.project.location!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Started: ${dateFormat.format(widget.project.startDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (widget.project.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.project.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Records section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Field Records (${_records.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Records list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No records yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first record',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            return _RecordListItem(
                              record: record,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecordDetailScreen(record: record),
                                  ),
                                );
                                if (result == true) {
                                  _loadRecords(); // Reload if record was deleted
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFieldRecord,
        icon: const Icon(Icons.add),
        label: const Text('New Record'),
      ),
    );
  }
}

class _RecordListItem extends StatelessWidget {
  final FieldRecord record;
  final VoidCallback onTap;

  const _RecordListItem({required this.record, required this.onTap});

  Color _getRockTypeColor() {
    switch (record.rockType.toLowerCase()) {
      case 'igneous':
        return const Color(0xFFD32F2F);
      case 'sedimentary':
        return const Color(0xFFFFB74D);
      case 'metamorphic':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRockTypeColor(),
          child: Text(
            record.rockType.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          record.specificRockName ?? record.rockType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.dip != null || record.strike != null)
              Text(
                  'Dip: ${record.dip ?? 'N/A'}° | Strike: ${record.strike ?? 'N/A'}°'),
            Text(timeFormat.format(record.timestamp)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
