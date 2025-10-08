import 'package:flutter/material.dart';

abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Execute function with loading state
  Future<T> executeWithLoading<T>(Future<T> Function() function) async {
    try {
      setLoading(true);
      clearError();
      final result = await function();
      return result;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Execute function without loading state (silent)
  Future<T?> executeSilently<T>(Future<T> Function() function) async {
    try {
      return await function();
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}