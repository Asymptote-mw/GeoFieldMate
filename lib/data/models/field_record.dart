/// Model representing a single field geological record
class FieldRecord {
  final String id; // Unique identifier
  final String projectId; // Associated project
  final DateTime timestamp; // When the record was created

  // Location data
  final double? latitude;
  final double? longitude;
  final double? elevation;
  final String? locationName;

  // Geological measurements
  final int? dip; // Dip angle (0-90 degrees)
  final int? strike; // Strike direction (0-360 degrees)

  // Rock classification
  final String rockType; // igneous, sedimentary, metamorphic
  final String? specificRockName; // e.g., "granite", "sandstone"

  // Structural features
  final List<String> structuralFeatures; // faults, folds, joints, veins

  // Observations
  final String notes; // Field observations

  // Media
  final List<String> imageUrls; // Paths to attached images

  // Metadata
  final bool isSynced; // Whether data is synced to cloud
  final DateTime? lastModified;

  FieldRecord({
    required this.id,
    required this.projectId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.elevation,
    this.locationName,
    this.dip,
    this.strike,
    required this.rockType,
    this.specificRockName,
    this.structuralFeatures = const [],
    this.notes = '',
    this.imageUrls = const [],
    this.isSynced = false,
    this.lastModified,
  });

  /// Convert FieldRecord to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'locationName': locationName,
      'dip': dip,
      'strike': strike,
      'rockType': rockType,
      'specificRockName': specificRockName,
      'structuralFeatures': structuralFeatures.join(
        ',',
      ), // Store as comma-separated
      'notes': notes,
      'imageUrls': imageUrls.join(','), // Store as comma-separated
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  /// Create FieldRecord from Map (database retrieval)
  factory FieldRecord.fromMap(Map<String, dynamic> map) {
    return FieldRecord(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      elevation: map['elevation'] as double?,
      locationName: map['locationName'] as String?,
      dip: map['dip'] as int?,
      strike: map['strike'] as int?,
      rockType: map['rockType'] as String,
      specificRockName: map['specificRockName'] as String?,
      structuralFeatures:
          map['structuralFeatures'] != null && map['structuralFeatures'] != ''
          ? (map['structuralFeatures'] as String).split(',')
          : [],
      notes: map['notes'] as String? ?? '',
      imageUrls: map['imageUrls'] != null && map['imageUrls'] != ''
          ? (map['imageUrls'] as String).split(',')
          : [],
      isSynced: map['isSynced'] == 1,
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'] as String)
          : null,
    );
  }

  /// Create a copy of FieldRecord with updated fields
  FieldRecord copyWith({
    String? id,
    String? projectId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? elevation,
    String? locationName,
    int? dip,
    int? strike,
    String? rockType,
    String? specificRockName,
    List<String>? structuralFeatures,
    String? notes,
    List<String>? imageUrls,
    bool? isSynced,
    DateTime? lastModified,
  }) {
    return FieldRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      locationName: locationName ?? this.locationName,
      dip: dip ?? this.dip,
      strike: strike ?? this.strike,
      rockType: rockType ?? this.rockType,
      specificRockName: specificRockName ?? this.specificRockName,
      structuralFeatures: structuralFeatures ?? this.structuralFeatures,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      isSynced: isSynced ?? this.isSynced,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Validate dip and strike values
  bool isValidMeasurement() {
    if (dip != null && (dip! < 0 || dip! > 90)) return false;
    if (strike != null && (strike! < 0 || strike! > 360)) return false;
    return true;
  }
}
