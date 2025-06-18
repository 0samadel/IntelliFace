// ─────────────────────────────────────────────────────────────────────────────
// File    : user_service.dart
// Purpose : Handles CRUD operations for employee users.
// Depends : auth_service.dart (for token-based authentication if needed)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // Base URL for user-related API endpoints
  static const String _baseUrl = 'https://intelliface-api.onrender.com/api/users';

  /// Fetch all employee users from the backend.
  ///
  /// Returns a list of maps where each map is an employee document.
  /// Throws [Exception] if the request fails.
  static Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load employees: ${response.body}');
    }
  }

  /// Create a new employee in the database.
  ///
  /// - [employeeData]: a map containing employee fields like fullName, department, etc.
  /// Returns the created employee document if successful.
  /// Throws [Exception] if creation fails.
  static Future<Map<String, dynamic>?> createEmployee(Map<String, dynamic> employeeData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/employee'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(employeeData),
    );

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to create employee: ${json.decode(response.body)['error'] ?? 'Unknown error'}',
      );
    }
  }

  /// Update an existing employee by ID.
  ///
  /// - [id]: the employee's MongoDB ID
  /// - [employeeData]: updated fields as a map
  /// Returns the updated document if successful.
  /// Throws [Exception] if update fails.
  static Future<Map<String, dynamic>?> updateEmployee(String id, Map<String, dynamic> employeeData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(employeeData),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to update employee: ${json.decode(response.body)['message'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete an employee by ID.
  ///
  /// Returns `true` if the employee was successfully deleted.
  /// Throws [Exception] if deletion fails.
  static Future<bool> deleteEmployee(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to delete employee: ${json.decode(response.body)['message'] ?? 'Unknown error'}',
      );
    }
  }
}
