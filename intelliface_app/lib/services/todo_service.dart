// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/services/todo_service.dart
// Purpose : Handles all API interactions for the To-Do list feature.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io'; // For HttpHeaders
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting dates for the API query
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intelliface/core/constants/api_constants.dart'; // Adjust path
import 'package:intelliface/models/todo_item_model.dart';      // Adjust path

/// A service class responsible for all To-Do item related API calls,
/// including creating, reading, updating, and deleting tasks for the user.
class TodoService {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// The base URL for the API, retrieved from a central constants file.
  final String _apiBaseUrl = ApiConstants.baseUrl; // e.g., http://localhost:5100/api

  /// The key used to retrieve the token from SharedPreferences.
  /// This MUST exactly match the key used in AuthService to save the token to ensure consistency.
  static const String _tokenStorageKey = 'employeeAuthToken';

  /* ============================================================================
   * 2. Private Helper Methods
   * ========================================================================== */

  /// Retrieves the stored authentication token from local storage.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenStorageKey);
    print("TodoService _getToken(): Retrieved from SharedPreferences with key '$_tokenStorageKey': $token"); // DEBUG
    return token;
  }

  /// Constructs the necessary HTTP headers for an API request.
  Future<Map<String, String>> _getAuthHeaders({bool isJsonContent = true, bool requiresAuth = true}) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (isJsonContent) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json; charset=UTF-8';
    }

    // If the endpoint requires authentication, retrieve and add the Bearer token.
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
        print("TodoService _getAuthHeaders(): Setting Auth Header: Bearer $token"); // DEBUG
      } else {
        print("TodoService _getAuthHeaders(): Auth token is NULL or EMPTY. Request might fail if auth is required."); // DEBUG
      }
    }
    return headers;
  }

  /// A centralized handler for processing HTTP responses.
  /// It decodes the JSON, checks status codes, and throws a custom ApiException on errors.
  Map<String, dynamic> _handleResponse(http.Response response, String operation) {
    print("TodoService $operation: Response Status Code: ${response.statusCode}");
    print("TodoService $operation: Response Body: ${response.body}");

    dynamic decodedBody;
    try {
      decodedBody = json.decode(response.body);
    } catch (e) {
      print("TodoService $operation: Failed to decode JSON response body: ${response.body}");
      throw ApiException('Invalid server response format.', response.statusCode);
    }

    // Handle successful responses (status code 200-299).
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        // The backend typically sends a wrapper object: { success: true, data: ..., ... }
        return decodedBody; // Return the full map for further processing.
      } else {
        print("TodoService $operation ERROR: Decoded success response body is not a Map. Type: ${decodedBody.runtimeType}");
        throw ApiException('Unexpected server response structure after success.', response.statusCode);
      }
    } else {
      // Handle error responses.
      String errorMessage = 'API request failed for $operation. Status: ${response.statusCode}';
      if (decodedBody is Map<String, dynamic>) {
        // Attempt to extract a specific error message from the response body.
        errorMessage = decodedBody['message'] ?? decodedBody['error'] ?? errorMessage;
      } else if (decodedBody is String && decodedBody.isNotEmpty) {
        errorMessage = decodedBody;
      }
      print("TodoService $operation ERROR: $errorMessage");
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  /* ============================================================================
   * 3. Public API Methods
   * ========================================================================== */

  /// Creates a new to-do item for the authenticated user.
  Future<TodoItem> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    final Map<String, dynamic> todoData = {'title': title};
    if (description != null && description.isNotEmpty) {
      todoData['description'] = description;
    }
    if (dueDate != null) {
      // Convert DateTime to ISO 8601 string format for the API.
      todoData['dueDate'] = dueDate.toIso8601String();
    }

    print("TodoService createTodo: Sending request to $_apiBaseUrl/todos");
    print("TodoService createTodo: Request body: ${json.encode(todoData)}");

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/todos'),
      headers: await _getAuthHeaders(),
      body: json.encode(todoData),
    );

    final decodedResponse = _handleResponse(response, "createTodo");
    // After handling the response, parse the 'data' field into a TodoItem model.
    if (decodedResponse['success'] == true && decodedResponse['data'] != null && decodedResponse['data'] is Map<String, dynamic>) {
      return TodoItem.fromJson(decodedResponse['data'] as Map<String, dynamic>);
    } else {
      throw ApiException(decodedResponse['message'] ?? 'Failed to create to-do or data missing.', response.statusCode);
    }
  }

  /// Fetches a paginated and filterable list of to-do items for the authenticated user.
  Future<Map<String, dynamic>> getUserTodos({
    DateTime? date,
    bool? completed,
    int page = 1,
    int limit = 20,
  }) async {
    // Build the query parameters for filtering and pagination.
    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (date != null) {
      queryParameters['date'] = DateFormat('yyyy-MM-dd').format(date);
    }
    if (completed != null) {
      queryParameters['completed'] = completed.toString();
    }

    final uri = Uri.parse('$_apiBaseUrl/todos').replace(queryParameters: queryParameters);
    print("TodoService getUserTodos: Calling GET $uri");

    final response = await http.get(
        uri,
        headers: await _getAuthHeaders(isJsonContent: false) // GET requests don't have a JSON body.
    );
    // Returns the full response map {success, count, pagination, data}.
    // The UI layer is responsible for extracting the list from the 'data' key.
    return _handleResponse(response, "getUserTodos");
  }

  /// Fetches a single to-do item by its unique ID.
  Future<TodoItem> getTodoById(String todoId) async {
    print("TodoService getTodoById: Calling GET $_apiBaseUrl/todos/$todoId");
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/todos/$todoId'),
      headers: await _getAuthHeaders(isJsonContent: false),
    );
    final decodedResponse = _handleResponse(response, "getTodoById");
    if (decodedResponse['success'] == true && decodedResponse['data'] != null && decodedResponse['data'] is Map<String, dynamic>) {
      return TodoItem.fromJson(decodedResponse['data'] as Map<String, dynamic>);
    } else {
      throw ApiException(decodedResponse['message'] ?? 'Failed to fetch to-do by ID or data missing.', response.statusCode);
    }
  }

  /// Updates an existing to-do item.
  Future<TodoItem> updateTodo(String todoId, Map<String, dynamic> updateData) async {
    // If a dueDate is being updated, ensure it's in the correct string format.
    if (updateData.containsKey('dueDate') && updateData['dueDate'] is DateTime) {
      updateData['dueDate'] = (updateData['dueDate'] as DateTime).toIso8601String();
    } else if (updateData.containsKey('dueDate') && updateData['dueDate'] == null) {
      updateData['dueDate'] = null; // Handle setting dueDate to null.
    }
    print("TodoService updateTodo: Calling PUT $_apiBaseUrl/todos/$todoId with body ${json.encode(updateData)}");

    final response = await http.put(
      Uri.parse('$_apiBaseUrl/todos/$todoId'),
      headers: await _getAuthHeaders(),
      body: json.encode(updateData),
    );
    final decodedResponse = _handleResponse(response, "updateTodo");
    if (decodedResponse['success'] == true && decodedResponse['data'] != null && decodedResponse['data'] is Map<String, dynamic>) {
      return TodoItem.fromJson(decodedResponse['data'] as Map<String, dynamic>);
    } else {
      throw ApiException(decodedResponse['message'] ?? 'Failed to update to-do or data missing.', response.statusCode);
    }
  }

  /// Deletes a to-do item by its unique ID.
  Future<bool> deleteTodo(String todoId) async {
    print("TodoService deleteTodo: Calling DELETE $_apiBaseUrl/todos/$todoId");
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/todos/$todoId'),
      headers: await _getAuthHeaders(isJsonContent: false), // DELETE requests usually have no body.
    );
    final decodedResponse = _handleResponse(response, "deleteTodo");
    // On successful deletion, the 'success' flag should be true.
    return decodedResponse['success'] == true;
  }
}

/* ============================================================================
 * 4. Custom Exception Class
 * ========================================================================== */

/// A custom exception class for handling API-related errors.
/// It includes the error message and the HTTP status code for better context.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => "ApiException: $message (Status Code: $statusCode)";
}
/* ───────────────────────────────────────────────────────────────────────────── */