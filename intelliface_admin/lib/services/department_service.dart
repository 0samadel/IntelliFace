// ─────────────────────────────────────────────────────────────────────────────
// File    : department_service.dart
// Purpose : Provides CRUD operations for department management in the admin panel.
// Used by : Admin dashboard for managing departments in the organization.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

class DepartmentService {
  // Base API URL for departments
  static const String baseUrl = 'https://intelliface-api.onrender.com/api/departments';

  /// Fetch all departments from the server.
  ///
  /// Returns a list of department maps.
  /// Throws [Exception] on failure.
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      print('❌ Failed to load departments: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load departments');
    }
  }

  /// Create a new department.
  ///
  /// - [department]: map containing department name, code, etc.
  /// Returns the created department or null on failure.
  static Future<Map<String, dynamic>?> createDepartment(Map<String, dynamic> department) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(department),
    );

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      print('❌ Failed to create department: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  /// Update a department by ID.
  ///
  /// - [id]: MongoDB ID of the department to update
  /// - [department]: updated values
  /// Returns the updated department or null on failure.
  static Future<Map<String, dynamic>?> updateDepartment(String id, Map<String, dynamic> department) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(department),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      print('❌ Failed to update department: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  /// Delete a department by ID.
  ///
  /// Returns true if deletion succeeded, false otherwise.
  static Future<bool> deleteDepartment(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ Failed to delete department: ${response.statusCode} ${response.body}');
      return false;
    }
  }
}
