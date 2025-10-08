import 'package:flutter/material.dart';
import 'package:aplikasitest1/services/auth_service.dart';
import 'package:aplikasitest1/models/user.dart' hide User;

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthController(this._authService);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = (await _authService.getCurrentUser()) as User?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await AuthService.login(username, password);
    if (success) {
      _currentUser = (await _authService.getCurrentUser()) as User?;
    } else {
      _error = 'Login gagal: periksa username/password';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String username, String password, String email, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _authService.register(username, password, email, phone);
    if (!success) _error = 'Registrasi gagal: username/email mungkin sudah digunakan';

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
