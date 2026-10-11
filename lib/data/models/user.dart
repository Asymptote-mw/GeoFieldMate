/// Model representing a user of the app
class User {
  final String id;
  final String email;
  final String name;
  final bool isGuest; // True if using guest mode
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.isGuest = false,
    required this.createdAt,
    this.lastLogin,
  });

  /// Convert User to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isGuest': isGuest ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// Create User from Map (database retrieval)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      isGuest: map['isGuest'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
    );
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// Create a guest user
  factory User.guest() {
    final now = DateTime.now();
    return User(
      id: 'guest_${now.millisecondsSinceEpoch}',
      email: 'guest@geofieldmate.local',
      name: 'Guest User',
      isGuest: true,
      createdAt: now,
      lastLogin: now,
    );
  }
}
