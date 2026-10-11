import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/field_record.dart';
import '../models/project.dart';
import '../models/user.dart';

/// Database helper for local SQLite storage
/// Manages all database operations for offline-first functionality
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (create if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('geofieldmate.db');
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// Create all database tables
  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        isGuest INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        lastLogin TEXT
      )
    ''');

    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        location TEXT,
        recordCount INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        lastModified TEXT
      )
    ''');

    // Field records table
    await db.execute('''
      CREATE TABLE field_records (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        elevation REAL,
        locationName TEXT,
        dip INTEGER,
        strike INTEGER,
        rockType TEXT NOT NULL,
        specificRockName TEXT,
        structuralFeatures TEXT,
        notes TEXT,
        imageUrls TEXT,
        isSynced INTEGER DEFAULT 0,
        lastModified TEXT,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_project_id ON field_records(projectId)');
    await db.execute('CREATE INDEX idx_timestamp ON field_records(timestamp)');
  }

  // ==================== USER OPERATIONS ====================

  /// Insert a new user
  Future<User> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
    return user;
  }

  /// Get user by ID
  Future<User?> getUser(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Update user
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ==================== PROJECT OPERATIONS ====================

  /// Insert a new project
  Future<Project> insertProject(Project project) async {
    final db = await database;
    await db.insert('projects', project.toMap());
    return project;
  }

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final maps = await db.query('projects', orderBy: 'startDate DESC');
    return maps.map((map) => Project.fromMap(map)).toList();
  }

  /// Get project by ID
  Future<Project?> getProject(String id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  /// Update project
  Future<int> updateProject(Project project) async {
    final db = await database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// Delete project
  Future<int> deleteProject(String id) async {
    final db = await database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== FIELD RECORD OPERATIONS ====================

  /// Insert a new field record
  Future<FieldRecord> insertFieldRecord(FieldRecord record) async {
    final db = await database;
    await db.insert('field_records', record.toMap());

    // Update project record count
    await _updateProjectRecordCount(record.projectId);

    return record;
  }

  /// Get all field records for a project
  Future<List<FieldRecord>> getFieldRecordsByProject(String projectId) async {
    final db = await database;
    final maps = await db.query(
      'field_records',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => FieldRecord.fromMap(map)).toList();
  }

  /// Get field record by ID
  Future<FieldRecord?> getFieldRecord(String id) async {
    final db = await database;
    final maps = await db.query(
      'field_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return FieldRecord.fromMap(maps.first);
  }

  /// Update field record
  Future<int> updateFieldRecord(FieldRecord record) async {
    final db = await database;
    return await db.update(
      'field_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Delete field record
  Future<int> deleteFieldRecord(String id, String projectId) async {
    final db = await database;
    final result = await db.delete(
      'field_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Update project record count
    await _updateProjectRecordCount(projectId);

    return result;
  }

  /// Search field records by criteria
  Future<List<FieldRecord>> searchFieldRecords({
    String? rockType,
    DateTime? startDate,
    DateTime? endDate,
    String? projectId,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (projectId != null) {
      whereClause += ' AND projectId = ?';
      whereArgs.add(projectId);
    }

    if (rockType != null) {
      whereClause += ' AND rockType = ?';
      whereArgs.add(rockType);
    }

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'field_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => FieldRecord.fromMap(map)).toList();
  }

  /// Helper method to update project record count
  Future<void> _updateProjectRecordCount(String projectId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM field_records WHERE projectId = ?',
        [projectId],
      ),
    );

    await db.update(
      'projects',
      {'recordCount': count ?? 0},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
