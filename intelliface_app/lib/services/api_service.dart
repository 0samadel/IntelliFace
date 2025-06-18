// ─────────────────────────────────────────────────────────────────────────────
// File    : services/api_service.dart
// Purpose : A generic service for making API calls to the backend.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/employee.dart';

/// A service class responsible for handling network requests to the backend API.
/// It abstracts away the details of HTTP requests.
class ApiService {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// The base URL for all API endpoints.
  static const String baseUrl = 'https://intelliface-api.onrender.com';

  /* ============================================================================
   * 2. Methods
   * ========================================================================== */

  /// Fetches a list of all employees from the API.
  static Future<List<Employee>> getEmployees() async {
    // A try-catch block to handle potential network errors or other exceptions.
    try {
      // Sends an HTTP GET request to the '/Employee' endpoint.
      final response = await http.get(Uri.parse('$baseUrl/Employee'));

      // Checks if the request was successful (HTTP status code 200 OK).
      if (response.statusCode == 200) {
        // Decodes the JSON response body from a string into a List of dynamic objects.
        List<dynamic> jsonList = jsonDecode(response.body);
        // Maps each JSON object in the list to an Employee model instance
        // using the Employee.fromJson factory constructor.
        return jsonList.map((json) => Employee.fromJson(json)).toList();
      } else {
        // If the server returns a non-200 status code, throw an exception.
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      // Catches any errors during the process and re-throws a more specific exception.
      throw Exception('Error: $e');
    }
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */