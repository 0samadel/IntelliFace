// ─────────────────────────────────────────────────────────────────────────────
// File    : attendance_service.dart
// Purpose : Admin-side service for managing attendance records via API
// API     : https://intelliface-api.onrender.com/api/attendance
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class AttendanceService {
  static final String _baseUrl = '${ApiConstants.baseUrl}/attendance';
  static const String _adminAuthTokenKey = 'adminAuthToken';

  // ─────────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get admin token from shared storage.
  static Future<String?> _getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_adminAuthTokenKey);
    print("🟢 Retrieved admin token: $token");
    return token;
  }

  /// Construct headers with Authorization if token exists.
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAdminToken();
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      print("✅ Authorization header set.");
    } else {
      print("❌ No token found for Authorization header.");
    }
    return headers;
  }

  /// Common handler for parsing API responses.
  static Map<String, dynamic> _handleResponse(http.Response response, String operation) {
    print("📥 [$operation] Status: ${response.statusCode}");
    print("📥 [$operation] Body: ${response.body}");

    try {
      final body = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body is List ? {'data': body} : body;
      } else {
        final error = body['message'] ?? body['error'] ?? 'Unknown error';
        throw Exception("❌ [$operation] $error (Status: ${response.statusCode})");
      }
    } catch (_) {
      throw Exception("❌ [$operation] Failed to parse response: ${response.body}");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Public API Methods
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch all attendance records.
  static Future<List<Map<String, dynamic>>> fetchAllAttendanceRecords() async {
    final response = await http.get(Uri.parse(_baseUrl), headers: await _getAuthHeaders());
    final result = _handleResponse(response, "fetchAllAttendanceRecords");
    return List<Map<String, dynamic>>.from(result['data']);
  }

  /// Fetch attendance records filtered by date.
  static Future<List<Map<String, dynamic>>> fetchAttendanceByDate(String date) async {
    final response = await http.get(Uri.parse('$_baseUrl?date=$date'), headers: await _getAuthHeaders());
    final result = _handleResponse(response, "fetchAttendanceByDate");
    return List<Map<String, dynamic>>.from(result['data']);
  }

  /// Create a new attendance record.
  static Future<Map<String, dynamic>?> createAttendanceRecord(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: await _getAuthHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response, "createAttendanceRecord");
  }

  /// Update an existing attendance record.
  static Future<Map<String, dynamic>?> updateAttendanceRecord(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: await _getAuthHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response, "updateAttendanceRecord");
  }

  /// Delete an attendance record by ID.
  static Future<bool> deleteAttendanceRecord(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: await _getAuthHeaders(),
    );
    final result = _handleResponse(response, "deleteAttendanceRecord");
    return response.statusCode == 200 || response.statusCode == 204 || result['success'] == true;
  }
}
