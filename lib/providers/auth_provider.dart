import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user.dart';
import '../data/repositories/database_helper.dart';

/// Provider to manage user authentication
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _userIdKey = 'currentUserId';

  /// Initialize and check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      if (userId != null) {
        _currentUser = await _dbHelper.getUser(userId);
        if (_currentUser != null) {
          // Update last login
          _currentUser = _currentUser!.copyWith(lastLogin: DateTime.now());
          await _dbHelper.updateUser(_currentUser!);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        _errorMessage = 'Email already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new user
      final user = User(
        id: const Uuid().v4(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // In a real app, you'd hash and store the password securely
      // For this demo, we'll just store user info
      await _dbHelper.insertUser(user);

      // Save user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, user.id);

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign up failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log in existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get user by email
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        _errorMessage = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // In a real app, verify password hash here
      // For demo purposes, we'll just accept any password

      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _dbHelper.updateUser(updatedUser);

      // Save user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, updatedUser.id);

      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Continue as guest
  Future<void> continueAsGuest() async {
    _isLoading = true;
    notifyListeners();

    try {
      final guestUser = User.guest();
      await _dbHelper.insertUser(guestUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, guestUser.id);

      _currentUser = guestUser;
    } catch (e) {
      _errorMessage = 'Failed to create guest session: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Log out current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
