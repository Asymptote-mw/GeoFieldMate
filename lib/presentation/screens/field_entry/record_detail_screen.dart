import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import '../../../core/constants/colors.dart';
import 'field_entry_screen.dart';

/// Screen showing detailed view of a field record
class RecordDetailScreen extends StatefulWidget {
  final FieldRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late FieldRecord _currentRecord;

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.record;
  }

  Color _getRockTypeColor() {
    switch (_currentRecord.rockType.toLowerCase()) {
      case 'igneous':
        return AppColors.igneous;
      case 'sedimentary':
        return AppColors.sedimentary;
      case 'metamorphic':
        return AppColors.metamorphic;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FieldEntryScreen(
          projectId: _currentRecord.projectId,
          existingRecord: _currentRecord,
        ),
      ),
    );

    if (result == true) {
      // Reload the record
      final updatedRecord = await _dbHelper.getFieldRecord(_currentRecord.id);
      if (updatedRecord != null && mounted) {
        setState(() {
          _currentRecord = updatedRecord;
        });
      }
    }
  }

  Future<void> _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
            'Are you sure you want to delete this field record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteFieldRecord(
          _currentRecord.id, _currentRecord.projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    }
  }

  void _viewImageFullScreen(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Record Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editRecord,
            tooltip: 'Edit Record',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRecord,
            tooltip: 'Delete Record',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rock type
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getRockTypeColor(),
                    _getRockTypeColor().withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentRecord.rockType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentRecord.specificRockName ?? _currentRecord.rockType,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(_currentRecord.timestamp),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Section
                  if (_currentRecord.latitude != null ||
                      _currentRecord.locationName != null)
                    _buildSection(
                      'Location',
                      Icons.location_on,
                      _buildLocationInfo(),
                    ),

                  // Measurements Section
                  if (_currentRecord.dip != null ||
                      _currentRecord.strike != null)
                    _buildSection(
                      'Geological Measurements',
                      Icons.architecture,
                      _buildMeasurementsInfo(),
                    ),

                  // Structural Features Section
                  if (_currentRecord.structuralFeatures.isNotEmpty)
                    _buildSection(
                      'Structural Features',
                      Icons.texture,
                      _buildStructuralFeaturesInfo(),
                    ),

                  // Notes Section
                  if (_currentRecord.notes.isNotEmpty)
                    _buildSection(
                      'Field Notes',
                      Icons.notes,
                      _buildNotesInfo(),
                    ),

                  // Photos Section
                  if (_currentRecord.imageUrls.isNotEmpty)
                    _buildSection(
                      'Photos',
                      Icons.photo_camera,
                      _buildPhotosInfo(),
                    ),

                  // Metadata Section
                  _buildSection(
                    'Record Information',
                    Icons.info_outline,
                    _buildMetadataInfo(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editRecord,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Record'),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentRecord.locationName != null) ...[
          _buildInfoRow(Icons.place, 'Name', _currentRecord.locationName!),
          const SizedBox(height: 12),
        ],
        if (_currentRecord.latitude != null &&
            _currentRecord.longitude != null) ...[
          _buildInfoRow(
            Icons.my_location,
            'Coordinates',
            '${_currentRecord.latitude!.toStringAsFixed(6)}, ${_currentRecord.longitude!.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 12),
        ],
        if (_currentRecord.elevation != null)
          _buildInfoRow(
            Icons.terrain,
            'Elevation',
            '${_currentRecord.elevation!.toStringAsFixed(2)} m',
          ),
      ],
    );
  }

  Widget _buildMeasurementsInfo() {
    return Row(
      children: [
        if (_currentRecord.dip != null)
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.arrow_downward,
                    color: AppColors.primaryGreen, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${_currentRecord.dip}°',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Dip',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        if (_currentRecord.dip != null && _currentRecord.strike != null)
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[300],
          ),
        if (_currentRecord.strike != null)
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.arrow_forward,
                    color: AppColors.primaryGreen, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${_currentRecord.strike}°',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Strike',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStructuralFeaturesInfo() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _currentRecord.structuralFeatures.map((feature) {
        return Chip(
          label: Text(
            feature.toUpperCase(),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
          labelStyle: const TextStyle(color: AppColors.primaryGreen),
        );
      }).toList(),
    );
  }

  Widget _buildNotesInfo() {
    return Text(
      _currentRecord.notes,
      style: const TextStyle(fontSize: 15, height: 1.5),
    );
  }

  Widget _buildPhotosInfo() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _currentRecord.imageUrls.length,
      itemBuilder: (context, index) {
        final imagePath = _currentRecord.imageUrls[index];
        return GestureDetector(
          onTap: () => _viewImageFullScreen(imagePath),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataInfo() {
    final createdFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Column(
      children: [
        _buildInfoRow(
          Icons.create,
          'Created',
          createdFormat.format(_currentRecord.timestamp),
        ),
        if (_currentRecord.lastModified != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            Icons.update,
            'Last Modified',
            createdFormat.format(_currentRecord.lastModified!),
          ),
        ],
        const Divider(height: 24),
        _buildInfoRow(
          Icons.fingerprint,
          'Record ID',
          _currentRecord.id,
          small: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool small = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: small ? 11 : 15,
                  fontWeight: small ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full screen image viewer
class FullScreenImage extends StatelessWidget {
  final String imagePath;

  const FullScreenImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
