// ─────────────────────────────────────────────────────────────────────────────
// File    : auth_service.dart
// Purpose : Manages admin authentication, token storage, and user sessions.
// Used by : Login screen and secure requests requiring JWT.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart'; // Ensure this path is correct

class AuthService {
  static String get _baseUrl => '${ApiConstants.baseUrl}/auth';

  static String? _token;
  static Map<String, dynamic>? _currentUser;

  /// Save token and user data in memory and SharedPreferences.
  static Future<void> saveTokenAndUser(
      String token,
      Map<String, dynamic> userData, {
        String appType = "employee",
      }) async {
    _token = token;
    _currentUser = userData;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminAuthToken', token);
      await prefs.setString('adminUser', jsonEncode(userData));

      print("✅ Token and user saved.");
      print("AuthService ($appType): Token saved. Role: ${userData['role']}");
    } catch (e) {
      print("⚠️ Failed to save token/user: $e");
    }
  }

  /// Retrieve token from memory or SharedPreferences.
  static Future<String?> getToken({String appType = "employee"}) async {
    if (_token != null) return _token;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('adminAuthToken');
      return _token;
    } catch (e) {
      print("⚠️ Failed to load token: $e");
      return null;
    }
  }

  /// Retrieve user data from memory or SharedPreferences.
  static Future<Map<String, dynamic>?> getCurrentUser({String appType = "employee"}) async {
    if (_currentUser != null) return _currentUser;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('adminUser');
      if (savedUser != null) {
        _currentUser = jsonDecode(savedUser);
        return _currentUser;
      }
    } catch (e) {
      print("⚠️ Failed to load user: $e");
    }

    return null;
  }

  /// Clear token and user data from memory and storage.
  static Future<void> logout({String appType = "employee"}) async {
    _token = null;
    _currentUser = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('adminAuthToken');
      await prefs.remove('adminUser');
      print("🚪 AuthService ($appType): Logged out.");
    } catch (e) {
      print("⚠️ Failed to clear data on logout: $e");
    }
  }

  /// Check if a valid token is stored.
  static Future<bool> isAuthenticated({String appType = "employee"}) async {
    return await getToken(appType: appType) != null;
  }

  /// Send login request to API.
  ///
  /// Returns response data (token + user) on success, or throws error.
  static Future<Map<String, dynamic>> login(
      String username,
      String password, {
        String appType = "employee",
      }) async {
    print('🔐 Logging in as $username ($appType)');

    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      if (responseData.containsKey('token') && responseData.containsKey('user')) {
        await saveTokenAndUser(
          responseData['token'],
          responseData['user'],
          appType: appType,
        );
        return responseData;
      } else {
        throw Exception('Login succeeded but response is missing token/user.');
      }
    } else {
      final errorMessage = responseData['message'] ??
          responseData['error'] ??
          'Login failed. Please check your credentials.';
      throw Exception(errorMessage);
    }
  }
}
