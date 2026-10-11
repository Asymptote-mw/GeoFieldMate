import 'package:flutter/material.dart';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import '../../../data/models/project.dart';
import 'stereonet_view.dart';
import 'rose_diagram_view.dart';

/// Main visualization screen with tabs for different analysis tools
class VisualizationScreen extends StatefulWidget {
  final String? projectId; // Optional: visualize specific project or all data

  const VisualizationScreen({super.key, this.projectId});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  List<FieldRecord> _records = [];
  Project? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.projectId != null) {
        // Load specific project and its records
        _project = await _dbHelper.getProject(widget.projectId!);
        _records = await _dbHelper.getFieldRecordsByProject(widget.projectId!);
      } else {
        // Load all records from all projects
        final projects = await _dbHelper.getAllProjects();
        final List<FieldRecord> allRecords = [];
        for (final project in projects) {
          final records = await _dbHelper.getFieldRecordsByProject(project.id);
          allRecords.addAll(records);
        }
        _records = allRecords;
      }

      // Filter records that have dip and strike data
      _records =
          _records.where((r) => r.dip != null && r.strike != null).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project?.name ?? 'Data Visualization'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.scatter_plot), text: 'Stereonet'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Rose Diagram'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    StereonetView(records: _records),
                    RoseDiagramView(records: _records),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No measurement data available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add field records with dip and strike measurements',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
