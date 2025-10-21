import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

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
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  bool validatePassword(String inputPassword) {
    return password == _hashPassword(inputPassword);
  }

  // Hash password menggunakan SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  // Hash password helper
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // LOGIN
  static Future<bool> login(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);

      if (usersJson == null || usersJson.isEmpty) {
        print('No users registered yet');
        return false;
      }

      final List<dynamic> usersList = json.decode(usersJson);

      // Hash password input untuk dibandingkan
      final hashedPassword = AuthService()._hashPassword(password);

      for (var userData in usersList) {
        final user = User.fromMap(userData);
        if (user.username.toLowerCase() == username.toLowerCase() &&
            user.password == hashedPassword) {
          // Simpan current user
          await prefs.setString(_currentUserKey, user.toJson());
          print('Login successful for user: ${user.username}');
          return true;
        }
      }

      print('Invalid username or password');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      print('User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
    }
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

      // Hash password sebelum disimpan
      final hashedPassword = _hashPassword(password);

      // Buat user baru
      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        phone: phone,
        password: hashedPassword, // Password sudah di-hash
        createdAt: DateTime.now(),
      );

      usersList.add(newUser.toMap());
      await prefs.setString(_usersKey, json.encode(usersList));

      print('User registered successfully: $username');
      print('Total users: ${usersList.length}');
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
      final hasCurrentUser = prefs.containsKey(_currentUserKey);
      print('User logged in: $hasCurrentUser');
      return hasCurrentUser;
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
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = json.decode(userJson);
        print('Current user: ${userData['username']}');
        return userData;
      }
      
      print('No current user found');
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
      
      print('Total registered users: ${usersList.length}');
      return usersList.map((userData) => User.fromMap(userData)).toList();
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  // CLEAR ALL DATA (untuk debugging/testing)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('All data cleared');
    } catch (e) {
      print('Clear data error: $e');
    }
  }

  // UPDATE USER PROFILE
  Future<bool> updateUserProfile({
    required String userId,
    String? email,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      List<dynamic> usersList = json.decode(usersJson);

      int userIndex = usersList.indexWhere((u) => u['id'] == userId);
      
      if (userIndex == -1) {
        print('User not found');
        return false;
      }

      // Update data
      if (email != null) usersList[userIndex]['email'] = email;
      if (phone != null) usersList[userIndex]['phone'] = phone;

      // Simpan kembali
      await prefs.setString(_usersKey, json.encode(usersList));

      // Update current user jika yang diupdate adalah user yang sedang login
      final currentUserJson = prefs.getString(_currentUserKey);
      if (currentUserJson != null) {
        final currentUser = json.decode(currentUserJson);
        if (currentUser['id'] == userId) {
          if (email != null) currentUser['email'] = email;
          if (phone != null) currentUser['phone'] = phone;
          await prefs.setString(_currentUserKey, json.encode(currentUser));
        }
      }

      print('User profile updated successfully');
      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  // CHANGE PASSWORD
  Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      List<dynamic> usersList = json.decode(usersJson);

      int userIndex = usersList.indexWhere((u) => u['id'] == userId);
      
      if (userIndex == -1) {
        print('User not found');
        return false;
      }

      final user = User.fromMap(usersList[userIndex]);
      
      // Validasi password lama
      if (!user.validatePassword(oldPassword)) {
        print('Old password is incorrect');
        return false;
      }

      // Update dengan password baru (di-hash)
      usersList[userIndex]['password'] = _hashPassword(newPassword);

      // Simpan kembali
      await prefs.setString(_usersKey, json.encode(usersList));

      print('Password changed successfully');
      return true;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }
}