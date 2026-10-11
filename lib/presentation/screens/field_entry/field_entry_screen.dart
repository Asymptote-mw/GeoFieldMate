import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import '../../../core/constants/colors.dart';

/// Screen for entering geological field data
class FieldEntryScreen extends StatefulWidget {
  final String projectId;
  final FieldRecord? existingRecord; // For editing existing records

  const FieldEntryScreen({
    super.key,
    required this.projectId,
    this.existingRecord,
  });

  @override
  State<FieldEntryScreen> createState() => _FieldEntryScreenState();
}

class _FieldEntryScreenState extends State<FieldEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _dipController = TextEditingController();
  final _strikeController = TextEditingController();
  final _specificRockController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _elevationController = TextEditingController();

  // Form state
  String _selectedRockType = 'igneous';
  final List<String> _selectedFeatures = [];
  final List<String> _imagePaths = [];
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  double? _locationAccuracy; // GPS accuracy in meters

  // Rock types and structural features
  final List<String> _rockTypes = ['igneous', 'sedimentary', 'metamorphic'];
  final List<String> _structuralFeatures = [
    'Faults',
    'Folds',
    'Joints',
    'Veins',
    'Fractures',
    'Bedding Planes',
    'Cleavage',
    'Foliation',
    'Lineation',
    'Shear Zones',
    'Breccia',
    'Slickensides',
    'Stylolites',
    'Unconformity',
    'Cross-bedding',
    'Graded Bedding',
    'Ripple Marks',
    'Dikes',
    'Sills',
    'Intrusions',
  ];
  final TextEditingController _customFeatureController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _dipController.text = record.dip?.toString() ?? '';
      _strikeController.text = record.strike?.toString() ?? '';
      _selectedRockType = record.rockType;
      _specificRockController.text = record.specificRockName ?? '';
      _notesController.text = record.notes;
      _locationNameController.text = record.locationName ?? '';
      _latitudeController.text = record.latitude?.toString() ?? '';
      _longitudeController.text = record.longitude?.toString() ?? '';
      _elevationController.text = record.elevation?.toString() ?? '';
      _selectedFeatures.addAll(record.structuralFeatures);
      _imagePaths.addAll(record.imageUrls);
    }
  }

  @override
  void dispose() {
    _dipController.dispose();
    _strikeController.dispose();
    _specificRockController.dispose();
    _notesController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _elevationController.dispose();
    _customFeatureController.dispose();
    super.dispose();
  }

  /// Get current GPS location with high accuracy
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable GPS in your device settings.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting precise location... Please wait'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get current position with HIGH accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _elevationController.text = position.altitude.toStringAsFixed(2);
        _locationAccuracy = position.accuracy;
      });

      if (mounted) {
        // Show accuracy feedback
        Color accuracyColor;
        String accuracyText;

        if (position.accuracy <= 5) {
          accuracyColor = Colors.green;
          accuracyText =
              'Excellent (±${position.accuracy.toStringAsFixed(1)}m)';
        } else if (position.accuracy <= 10) {
          accuracyColor = Colors.lightGreen;
          accuracyText = 'Good (±${position.accuracy.toStringAsFixed(1)}m)';
        } else if (position.accuracy <= 20) {
          accuracyColor = Colors.orange;
          accuracyText = 'Fair (±${position.accuracy.toStringAsFixed(1)}m)';
        } else {
          accuracyColor = Colors.red;
          accuracyText =
              'Poor (±${position.accuracy.toStringAsFixed(1)}m) - Try again';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location captured!'),
                      Text(
                        'GPS Accuracy: $accuracyText',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: accuracyColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Pick image from camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imagePaths.add(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePaths.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove image from list
  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  /// Save field record
  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final record = FieldRecord(
        id: widget.existingRecord?.id ?? const Uuid().v4(),
        projectId: widget.projectId,
        timestamp: widget.existingRecord?.timestamp ?? DateTime.now(),
        latitude: _latitudeController.text.isNotEmpty
            ? double.parse(_latitudeController.text)
            : null,
        longitude: _longitudeController.text.isNotEmpty
            ? double.parse(_longitudeController.text)
            : null,
        elevation: _elevationController.text.isNotEmpty
            ? double.parse(_elevationController.text)
            : null,
        locationName: _locationNameController.text.isNotEmpty
            ? _locationNameController.text
            : null,
        dip: _dipController.text.isNotEmpty
            ? int.parse(_dipController.text)
            : null,
        strike: _strikeController.text.isNotEmpty
            ? int.parse(_strikeController.text)
            : null,
        rockType: _selectedRockType,
        specificRockName: _specificRockController.text.isNotEmpty
            ? _specificRockController.text
            : null,
        structuralFeatures: _selectedFeatures,
        notes: _notesController.text,
        imageUrls: _imagePaths,
        lastModified: DateTime.now(),
      );

      // Validate measurements
      if (!record.isValidMeasurement()) {
        throw Exception('Invalid dip or strike values');
      }

      // Save to database
      if (widget.existingRecord != null) {
        await _dbHelper.updateFieldRecord(record);
      } else {
        await _dbHelper.insertFieldRecord(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null
                ? 'Record updated successfully!'
                : 'Record saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingRecord != null ? 'Edit Record' : 'New Field Record'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveRecord,
              tooltip: 'Save Record',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location Section
            _buildSectionHeader('Location', Icons.location_on),
            const SizedBox(height: 12),
            _buildLocationCard(),
            const SizedBox(height: 24),

            // Measurements Section
            _buildSectionHeader('Geological Measurements', Icons.architecture),
            const SizedBox(height: 12),
            _buildMeasurementsCard(),
            const SizedBox(height: 24),

            // Rock Type Section
            _buildSectionHeader('Rock Classification', Icons.layers),
            const SizedBox(height: 12),
            _buildRockTypeCard(),
            const SizedBox(height: 24),

            // Structural Features Section
            _buildSectionHeader('Structural Features', Icons.texture),
            const SizedBox(height: 12),
            _buildStructuralFeaturesCard(),
            const SizedBox(height: 24),

            // Notes Section
            _buildSectionHeader('Field Notes', Icons.notes),
            const SizedBox(height: 12),
            _buildNotesCard(),
            const SizedBox(height: 24),

            // Photos Section
            _buildSectionHeader('Photos', Icons.photo_camera),
            const SizedBox(height: 12),
            _buildPhotosCard(),
            const SizedBox(height: 100), // Extra space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveRecord,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Record'),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _locationNameController,
              decoration: const InputDecoration(
                labelText: 'Location Name (Optional)',
                hintText: 'e.g., Outcrop near river bend',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.compass_calibration),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lat = double.tryParse(value);
                        if (lat == null || lat < -90 || lat > 90) {
                          return 'Invalid latitude';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.explore),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lon = double.tryParse(value);
                        if (lon == null || lon < -180 || lon > 180) {
                          return 'Invalid longitude';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _elevationController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Elevation (m)',
                prefixIcon: Icon(Icons.terrain),
              ),
            ),

            // GPS Accuracy indicator
            if (_locationAccuracy != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _locationAccuracy! <= 10
                      ? Colors.green.withOpacity(0.1)
                      : _locationAccuracy! <= 20
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _locationAccuracy! <= 10
                        ? Colors.green
                        : _locationAccuracy! <= 20
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _locationAccuracy! <= 10
                          ? Icons.gps_fixed
                          : _locationAccuracy! <= 20
                              ? Icons.gps_not_fixed
                              : Icons.gps_off,
                      size: 16,
                      color: _locationAccuracy! <= 10
                          ? Colors.green
                          : _locationAccuracy! <= 20
                              ? Colors.orange
                              : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GPS Accuracy: ±${_locationAccuracy!.toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontSize: 12,
                        color: _locationAccuracy! <= 10
                            ? Colors.green
                            : _locationAccuracy! <= 20
                                ? Colors.orange
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_locationAccuracy! > 10) ...[
                      const SizedBox(width: 8),
                      Text(
                        _locationAccuracy! > 20 ? '(Poor - Retry?)' : '(Fair)',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_isLoadingLocation
                        ? 'Getting GPS...'
                        : 'Get GPS Location'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                if (_latitudeController.text.isNotEmpty &&
                    !_isLoadingLocation) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Refresh Location',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ],
            ),

            // GPS Tips
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: For best accuracy, wait a few seconds after opening. Clear sky view improves GPS.',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dipController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Dip (°)',
                      hintText: '0-90',
                      prefixIcon: Icon(Icons.arrow_downward),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final dip = int.tryParse(value);
                        if (dip == null || dip < 0 || dip > 90) {
                          return 'Dip must be 0-90°';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _strikeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Strike (°)',
                      hintText: '0-360',
                      prefixIcon: Icon(Icons.arrow_forward),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final strike = int.tryParse(value);
                        if (strike == null || strike < 0 || strike > 360) {
                          return 'Strike must be 0-360°';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dip: Angle of inclination (0-90°)\nStrike: Compass direction (0-360°)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRockTypeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Primary Rock Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _rockTypes.map((type) {
                final isSelected = _selectedRockType == type;
                Color chipColor;
                switch (type) {
                  case 'igneous':
                    chipColor = AppColors.igneous;
                    break;
                  case 'sedimentary':
                    chipColor = AppColors.sedimentary;
                    break;
                  case 'metamorphic':
                    chipColor = AppColors.metamorphic;
                    break;
                  default:
                    chipColor = Colors.grey;
                }

                return ChoiceChip(
                  label: Text(type.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRockType = type;
                    });
                  },
                  selectedColor: chipColor.withOpacity(0.3),
                  backgroundColor: chipColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? chipColor : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specificRockController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Specific Rock Name',
                hintText: 'e.g., Granite, Sandstone, Schist',
                prefixIcon: Icon(Icons.category),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuralFeaturesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Structural Features',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select all observed features',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown for quick selection
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    const Icon(Icons.arrow_drop_down_circle, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedFeatures.isEmpty
                          ? 'Select from common features'
                          : '${_selectedFeatures.length} selected',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _structuralFeatures.map((feature) {
                        final isSelected = _selectedFeatures.contains(feature);
                        return FilterChip(
                          label: Text(feature),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFeatures.add(feature);
                              } else {
                                _selectedFeatures.remove(feature);
                              }
                            });
                          },
                          selectedColor:
                              AppColors.primaryGreen.withOpacity(0.3),
                          checkmarkColor: AppColors.primaryGreen,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Add custom feature
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customFeatureController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Add custom feature',
                      hintText: 'e.g., Boudinage, Mullions',
                      prefixIcon: const Icon(Icons.add_circle_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final customFeature = _customFeatureController.text.trim();
                    if (customFeature.isNotEmpty &&
                        !_selectedFeatures.contains(customFeature)) {
                      setState(() {
                        _selectedFeatures.add(customFeature);
                        _customFeatureController.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added: $customFeature'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),

            // Selected features display
            if (_selectedFeatures.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Selected Features:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFeatures.map((feature) {
                  return Chip(
                    label: Text(
                      feature,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedFeatures.remove(feature);
                      });
                    },
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    side: BorderSide(color: AppColors.primaryGreen),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _notesController,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Field Observations',
            hintText: 'Describe what you observe in the field...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (_imagePaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imagePaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
