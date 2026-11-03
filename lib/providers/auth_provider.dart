import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_session');
      final token = prefs.getString('auth_token');

      if (userDataStr != null && token != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userDataStr));
        ApiService.instance.configure(token: token);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user session: $e');
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.instance.login(identifier, password);
    _isLoading = false;

    if (result['success'] == true) {
      _currentUser = result['user'] as UserModel;
      final token = result['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('auth_token', token);

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String phone,
    required String fullName,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.instance.register(
      username: username,
      phone: phone,
      fullName: fullName,
      password: password,
    );
    _isLoading = false;

    if (result['success'] == true) {
      _currentUser = result['user'] as UserModel;
      final token = result['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('auth_token', token);

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.remove('auth_token');
    ApiService.instance.configure(token: null);
    notifyListeners();
  }
}
