import 'package:flutter/material.dart';
import 'dart:io';
import '../../../data/models/project.dart';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import '../../../data/services/export_service.dart';
import '../../../core/constants/colors.dart';

/// Screen for exporting project data
class ExportScreen extends StatefulWidget {
  final Project project;

  const ExportScreen({super.key, required this.project});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<FieldRecord> _records = [];
  bool _isLoading = true;
  bool _isExporting = false;

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

  Future<void> _exportPDF() async {
    if (_records.isEmpty) {
      _showEmptyDataDialog();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final pdfFile = await ExportService.exportProjectToPDF(
        widget.project,
        _records,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        _showExportSuccessDialog(pdfFile, 'PDF');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showErrorDialog('Failed to export PDF: $e');
      }
    }
  }

  Future<void> _exportCSV() async {
    if (_records.isEmpty) {
      _showEmptyDataDialog();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final csvFile = await ExportService.exportRecordsToCSV(
        _records,
        '${widget.project.name}_data',
      );

      if (mounted) {
        setState(() => _isExporting = false);
        _showExportSuccessDialog(csvFile, 'CSV');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showErrorDialog('Failed to export CSV: $e');
      }
    }
  }

  void _showEmptyDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Data'),
        content: const Text('This project has no field records to export.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportSuccessDialog(File file, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$format file created successfully!'),
            const SizedBox(height: 16),
            Text(
              'File: ${file.path.split('/').last}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (format == 'PDF')
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ExportService.printPDF(file);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print'),
            ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              if (format == 'PDF') {
                await ExportService.sharePDF(file);
              } else {
                await ExportService.shareCSV(file);
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.description,
                            'Records',
                            '${_records.length} field records',
                          ),
                          if (widget.project.location != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.location_on,
                              'Location',
                              widget.project.location!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Export options
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PDF Export
                  _buildExportCard(
                    icon: Icons.picture_as_pdf,
                    title: 'Export to PDF',
                    description:
                        'Generate a detailed field report with all records, measurements, and notes',
                    color: AppColors.error,
                    onTap: _isExporting ? null : _exportPDF,
                  ),
                  const SizedBox(height: 12),

                  // CSV Export
                  _buildExportCard(
                    icon: Icons.table_chart,
                    title: 'Export to CSV',
                    description:
                        'Export raw data for analysis in Excel, R, Python, or other tools',
                    color: AppColors.success,
                    onTap: _isExporting ? null : _exportCSV,
                  ),
                  const SizedBox(height: 24),

                  // Export info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(
                              'Export Information',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• PDF: Best for reports, presentations, and printing\n'
                          '• CSV: Best for data analysis and further processing\n'
                          '• Files are saved temporarily and can be shared via WhatsApp, Email, or Drive\n'
                          '• Photos are not included in exports (only photo counts)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  if (_isExporting) ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating export file...'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
