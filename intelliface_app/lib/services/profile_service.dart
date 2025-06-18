// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/services/profile_service.dart
// Purpose : Handles API interactions for fetching and updating user profiles.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io'; // For HttpHeaders, File
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intelliface/core/constants/api_constants.dart'; // Adjust path
import 'package:intelliface/models/user_model.dart';      // Adjust path

/// A service class responsible for all profile-related API calls,
/// such as retrieving and updating the authenticated user's profile data.
class ProfileService {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// The base URL for the API, retrieved from a central constants file.
  final String _apiBaseUrl = ApiConstants.baseUrl; // e.g., http://localhost:5100/api

  /// The key used to retrieve the token from SharedPreferences.
  /// This MUST exactly match the key used in AuthService to save the token.
  static const String _tokenStorageKey = 'employeeAuthToken';

  /* ============================================================================
   * 2. Private Helper Methods
   * ========================================================================== */

  /// Retrieves the stored authentication token from local storage.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenStorageKey);
    // Debug print to confirm which token is being retrieved.
    print("ProfileService _getToken(): Retrieved with key '$_tokenStorageKey': $token");
    return token;
  }

  /// Constructs the necessary HTTP headers for an authenticated API request.
  Future<Map<String, String>> _getAuthHeaders({bool isJsonContent = true}) async {
    final token = await _getToken();
    final headers = <String, String>{
      // All API responses are expected to be in JSON format.
      HttpHeaders.acceptHeader: 'application/json',
    };
    // For POST/PUT requests with a JSON body, set the content type.
    if (isJsonContent) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json; charset=UTF-8';
    }
    // If a token exists, add it to the Authorization header.
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      print("ProfileService _getAuthHeaders(): Setting Auth Header: Bearer $token");
    } else {
      print("ProfileService _getAuthHeaders(): Auth token is NULL for request.");
    }
    return headers;
  }

  /* ============================================================================
   * 3. Public API Methods
   * ========================================================================== */

  /// Fetches the profile data for the currently authenticated user.
  Future<User> getMyProfile() async {
    print("ProfileService: Attempting to fetch profile from $_apiBaseUrl/profile/me");
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/profile/me'),
      headers: await _getAuthHeaders(),
    );

    print("ProfileService getMyProfile: Response Status: ${response.statusCode}");
    print("ProfileService getMyProfile: Response Body: ${response.body}");

    dynamic decodedBody;
    try {
      // Attempt to decode the JSON response.
      decodedBody = json.decode(response.body);
    } catch (e) {
      // Catches errors if the response is not valid JSON.
      print("ProfileService getMyProfile: Failed to decode JSON response: ${response.body}");
      throw Exception('Failed to load profile: Invalid server response format.');
    }

    if (response.statusCode == 200) {
      // Check if the decoded body is a Map, as expected for a JSON object.
      if (decodedBody is Map<String, dynamic>) {
        final Map<String, dynamic> decodedResponse = decodedBody;
        // Check for the success flag and the presence of the 'data' field.
        if (decodedResponse['success'] == true && decodedResponse['data'] != null) {
          if (decodedResponse['data'] is Map<String, dynamic>) {
            // If everything is correct, create a User object from the data.
            return User.fromJson(decodedResponse['data'] as Map<String, dynamic>);
          } else {
            print("ProfileService getMyProfile ERROR: 'data' field is not a Map. Type: ${decodedResponse['data'].runtimeType}");
            throw Exception('Failed to parse profile data: Unexpected data structure.');
          }
        } else {
          throw Exception(decodedResponse['message'] ?? 'Failed to parse profile data.');
        }
      } else {
        print("ProfileService getMyProfile ERROR: Decoded response is not a Map. Type: ${decodedBody.runtimeType}");
        throw Exception('Failed to load profile: Unexpected server response structure.');
      }
    } else {
      // Handle non-200 status codes (e.g., 401, 404, 500).
      String errorMessage = 'Failed to load profile. Status: ${response.statusCode}';
      if (decodedBody is Map<String, dynamic> && decodedBody['message'] != null) {
        errorMessage = decodedBody['message'];
      } else if (decodedBody is String) {
        errorMessage = decodedBody;
      }
      throw Exception(errorMessage);
    }
  }

  /// Updates the authenticated user's profile with the provided data.
  /// Can handle partial updates (e.g., only updating the name or only the photo).
  Future<User> updateMyProfile({
    String? username,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    File? profileImageFile,
  }) async {
    var uri = Uri.parse('$_apiBaseUrl/profile/me');
    // A multipart request is used because it can handle both text fields and file uploads.
    var request = http.MultipartRequest('PUT', uri);

    // Add text fields to the request only if they are provided (not null).
    // This allows for partial updates without sending empty fields.
    if (username != null) request.fields['username'] = username;
    if (fullName != null) request.fields['fullName'] = fullName;
    if (phone != null) request.fields['phone'] = phone;
    if (email != null) request.fields['email'] = email;
    if (address != null) request.fields['address'] = address;

    // If a profile image file is provided, add it to the request.
    if (profileImageFile != null) {
      try {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage', // This field name MUST match the one in the backend middleware (e.g., upload.single('profileImage')).
            profileImageFile.path,
            contentType: MediaType('image', profileImageFile.path.split('.').last),
          ),
        );
        print("ProfileService updateMyProfile: Added profile image to request: ${profileImageFile.path}");
      } catch (e) {
        print("ProfileService updateMyProfile: Error adding image to request: $e");
      }
    }

    // Add authentication headers to the request.
    final token = await _getToken();
    if (token != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    } else {
      print("ProfileService updateMyProfile: Auth token is NULL. Request will likely fail.");
    }
    request.headers[HttpHeaders.acceptHeader] = 'application/json';

    print("ProfileService updateMyProfile: Sending PUT request to $uri");
    print("ProfileService updateMyProfile: Request fields: ${request.fields}");

    // Send the request and get the response.
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("ProfileService updateMyProfile: Response Status Code: ${response.statusCode}");
    print("ProfileService updateMyProfile: Response Body: ${response.body}");

    dynamic decodedBody;
    try {
      decodedBody = json.decode(response.body);
    } catch (e) {
      print("ProfileService updateMyProfile: Failed to decode JSON response body: ${response.body}");
      throw Exception('Failed to update profile: Invalid server response format.');
    }

    // Process the response similarly to getMyProfile.
    if (response.statusCode == 200) {
      if (decodedBody is Map<String, dynamic>) {
        final Map<String, dynamic> decodedResponse = decodedBody;
        if (decodedResponse['success'] == true && decodedResponse['data'] != null) {
          if (decodedResponse['data'] is Map<String, dynamic>) {
            return User.fromJson(decodedResponse['data'] as Map<String, dynamic>);
          } else {
            print("ProfileService updateMyProfile ERROR: 'data' field in success response is not a Map. Actual type: ${decodedResponse['data'].runtimeType}, Value: ${decodedResponse['data']}");
            throw Exception('Failed to parse updated profile data: Unexpected data structure.');
          }
        } else {
          throw Exception(decodedResponse['message'] ?? 'Profile update reported success, but data parsing failed.');
        }
      } else {
        print("ProfileService updateMyProfile ERROR: Decoded success response body is not a Map. Actual type: ${decodedBody.runtimeType}, Value: $decodedBody");
        throw Exception('Failed to update profile: Unexpected server response structure after success.');
      }
    } else { // Handle error status codes.
      String errorMessage = 'Failed to update profile. Status: ${response.statusCode}';
      if (decodedBody is Map<String, dynamic> && decodedBody['message'] != null) {
        errorMessage = decodedBody['message'];
      } else if (decodedBody is Map<String, dynamic> && decodedBody['error'] != null) {
        errorMessage = decodedBody['error'];
      } else if (decodedBody is String) {
        errorMessage = decodedBody;
      } else {
        // Fallback for unknown error structures.
        errorMessage += ". Server response: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}";
      }
      print("ProfileService updateMyProfile ERROR: $errorMessage");
      throw Exception(errorMessage);
    }
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */