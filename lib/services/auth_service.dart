import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String password;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  bool validatePassword(String inputPassword) {
    return password == inputPassword;
  }
}

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  // LOGIN
  static Future<bool> login(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      for (var userData in usersList) {
        final user = User.fromMap(userData);
        if (user.username == username && user.validatePassword(password)) {
          await prefs.setString(_currentUserKey, user.toJson());
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // REGISTER
  Future<bool> register(
    String username,
    String password,
    String email,
    String phone,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      List<dynamic> usersList = json.decode(usersJson);

      // Cek duplikasi username
      for (var userData in usersList) {
        final existingUser = User.fromMap(userData);
        if (existingUser.username.toLowerCase() == username.toLowerCase()) {
          print('Username already exists: $username');
          return false;
        }
        if (existingUser.email.toLowerCase() == email.toLowerCase()) {
          print('Email already exists: $email');
          return false;
        }
      }

      // Buat user baru
      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        phone: phone,
        password: password,
        createdAt: DateTime.now(),
      );

      usersList.add(newUser.toMap());
      await prefs.setString(_usersKey, json.encode(usersList));

      print('User registered successfully: $username');
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // CEK STATUS LOGIN
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_currentUserKey);
    } catch (e) {
      print('isLoggedIn error: $e');
      return false;
    }
  }

  // GET CURRENT USER
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        return json.decode(userJson);
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // GET ALL USERS (untuk debugging)
  Future<List<User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);
      return usersList.map((userData) => User.fromMap(userData)).toList();
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  // CLEAR ALL DATA (untuk debugging)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}