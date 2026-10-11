/// Model representing a field project or field trip
class Project {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location; // General location of field work
  final int recordCount; // Number of field records in this project
  final DateTime createdAt;
  final DateTime? lastModified;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.startDate,
    this.endDate,
    this.location,
    this.recordCount = 0,
    required this.createdAt,
    this.lastModified,
  });

  /// Convert Project to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'location': location,
      'recordCount': recordCount,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  /// Create Project from Map (database retrieval)
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      location: map['location'] as String?,
      recordCount: map['recordCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'] as String)
          : null,
    );
  }

  /// Create a copy of Project with updated fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    int? recordCount,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      recordCount: recordCount ?? this.recordCount,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Check if project is currently active
  bool isActive() {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Get project duration in days
  int getDurationInDays() {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays;
  }
}
