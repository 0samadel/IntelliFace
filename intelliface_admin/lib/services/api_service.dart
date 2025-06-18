// ─────────────────────────────────────────────────────────────────────────────
// File    : api_service.dart
// Purpose : Generic API service for department CRUD operations
// Endpoint: http://localhost:5100/api/departments
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5100/api/departments';

  /// GET /departments
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final response = await http.get(Uri.parse(baseUrl));
    print('[GET] Fetching departments → ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('❌ Failed to load departments: ${response.body}');
    }
  }

  /// POST /departments
  static Future<void> addDepartment(Map<String, dynamic> department) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(department),
    );
    print('[POST] Adding department → ${response.statusCode}');
    if (response.statusCode != 201) {
      throw Exception('❌ Failed to add department: ${response.body}');
    }
  }

  /// PUT /departments/:id
  static Future<void> updateDepartment(String id, Map<String, dynamic> updatedData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );
    print('[PUT] Updating department ($id) → ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('❌ Failed to update department: ${response.body}');
    }
  }

  /// DELETE /departments/:id
  static Future<void> deleteDepartment(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    print('[DELETE] Deleting department ($id) → ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('❌ Failed to delete department: ${response.body}');
    }
  }
}
