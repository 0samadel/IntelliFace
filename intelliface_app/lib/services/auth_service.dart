// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/services/auth_service.dart
// Purpose : Manages user authentication, session persistence, and user data.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Make sure this path is correct for your project structure
import 'package:intelliface/core/constants/api_constants.dart';


/// A service class responsible for handling user authentication logic,
/// including login, logout, and managing the user's session token and data
/// using local storage (SharedPreferences).
class AuthService {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// The base URL for all authentication-related API endpoints.
  static final String _baseUrl = '${ApiConstants.baseUrl}/auth';

  /// The key used to store the employee's authentication token in SharedPreferences.
  static const String _employeeTokenKey = 'employeeAuthToken';
  /// The key used to store the employee's user data (as a JSON string) in SharedPreferences.
  static const String _employeeUserKey = 'employeeCurrentUserData';

  /* ============================================================================
   * 2. Private Helper Methods
   * ========================================================================== */

  /// Saves the authentication token and user data to the device's local storage.
  static Future<void> _saveTokenAndUser(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employeeTokenKey, token);
    await prefs.setString(_employeeUserKey, jsonEncode(userData));
    print("AuthService: Token and user data saved. User ID: ${userData['_id']}, Role: ${userData['role']}");
  }

  /* ============================================================================
   * 3. Public Static Methods (Session Management)
   * ========================================================================== */

  /// Retrieves the stored authentication token from local storage.
  /// Returns `null` if no token is found.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeTokenKey);
  }

  /// Retrieves and decodes the current user's data from local storage.
  /// Returns a `Map<String, dynamic>` of the user data, or `null` if not found.
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_employeeUserKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        // If data is corrupted, it cannot be decoded. Clear it to prevent future errors.
        print("AuthService: Error decoding user data from SharedPreferences: $e");
        await prefs.remove(_employeeUserKey);
        await prefs.remove(_employeeTokenKey);
        return null;
      }
    }
    return null;
  }

  /// A convenience helper method to get the current user's ID directly.
  static Future<String?> getCurrentUserId() async {
    final Map<String, dynamic>? currentUserData = await getCurrentUser();
    if (currentUserData != null) {
      // IMPORTANT: The key '_id' must match what the backend sends in the user object.
      return currentUserData['_id'] as String?;
    }
    return null;
  }

  /// Clears the authentication token and user data from local storage,
  /// effectively logging the user out.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_employeeTokenKey);
    await prefs.remove(_employeeUserKey);
    print("AuthService: Logged out.");
  }

  /// Checks if a user is currently authenticated by verifying the presence of a token.
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /* ============================================================================
   * 4. Public Static Methods (API Interaction)
   * ========================================================================== */

  /// Authenticates a user with the backend using their username and password.
  static Future<Map<String, dynamic>> login(String username, String password) async {
    print('AuthService: Attempting login with username: $username at $_baseUrl/login');

    // Sends a POST request to the login endpoint.
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    print("AuthService login: Response Status Code: ${response.statusCode}");
    print("AuthService login: Response Body: ${response.body}");

    // Checks if the HTTP request was successful (e.g., status 200 OK).
    if (response.statusCode == 200) {
      // Further checks the response payload to ensure it's valid.
      if (responseData['success'] == true &&
          responseData.containsKey('token') &&
          responseData.containsKey('user') &&
          (responseData['user'] as Map<String, dynamic>).containsKey('_id')) {
        // If valid, save the token and user data for session persistence.
        await _saveTokenAndUser(
          responseData['token'] as String,
          responseData['user'] as Map<String, dynamic>,
        );
        return responseData; // Return the full response data to the caller.
      } else {
        // Handles cases where the API call was successful but the response was incomplete.
        String errorDetail = responseData['message'] ?? 'Token, user data, or user _id missing in response.';
        print("AuthService login ERROR: Login successful but server response incomplete. Detail: $errorDetail");
        throw Exception('Login successful but server response was incomplete.');
      }
    } else {
      // Handles failed API calls (e.g., 401 Unauthorized, 500 Server Error).
      // Extracts a user-friendly error message from the response body.
      String errorMessage = responseData['message'] ?? responseData['error'] ?? 'Login failed. Please check credentials.';
      print("AuthService login ERROR: API call failed. Message: $errorMessage");
      throw Exception(errorMessage);
    }
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */