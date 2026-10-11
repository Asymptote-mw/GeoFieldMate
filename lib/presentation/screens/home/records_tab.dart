import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import '../field_entry/record_detail_screen.dart';

/// Tab displaying all field records across all projects
class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
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

    // Get all projects and their records
    final projects = await _dbHelper.getAllProjects();
    final List<FieldRecord> allRecords = [];

    for (final project in projects) {
      final records = await _dbHelper.getFieldRecordsByProject(project.id);
      allRecords.addAll(records);
    }

    // Sort by timestamp (newest first)
    allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _records = allRecords;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No field records yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start recording geological data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return RecordCard(
            record: record,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordDetailScreen(record: record),
                ),
              );
              if (result == true) {
                _loadRecords(); // Reload if record was deleted
              }
            },
          );
        },
      ),
    );
  }
}

/// Record card widget
class RecordCard extends StatelessWidget {
  final FieldRecord record;
  final VoidCallback onTap;

  const RecordCard({super.key, required this.record, required this.onTap});

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
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRockTypeColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.rockType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRockTypeColor(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(record.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (record.specificRockName != null) ...[
                Text(
                  record.specificRockName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (record.dip != null || record.strike != null) ...[
                Row(
                  children: [
                    const Icon(Icons.architecture, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Dip: ${record.dip ?? 'N/A'}° | Strike: ${record.strike ?? 'N/A'}°',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (record.locationName != null ||
                  (record.latitude != null && record.longitude != null)) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.locationName ??
                            '${record.latitude!.toStringAsFixed(4)}, ${record.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (record.notes.isNotEmpty) ...[
                Text(
                  record.notes,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
