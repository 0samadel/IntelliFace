// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/services/attendance_service.dart
// Purpose : Handles all API interactions related to employee attendance.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'auth_service.dart';
import '../core/constants/api_constants.dart'; // Ensure path is correct

/// A service class responsible for all attendance-related API calls,
/// including check-in, check-out, and fetching attendance records.
class AttendanceService {
  /* ============================================================================
   * 1. Properties
   * ========================================================================== */

  /// The base URL for all attendance-related API endpoints.
  static final String _baseUrl = "${ApiConstants.baseUrl}/attendance";

  /* ============================================================================
   * 2. Methods
   * ========================================================================== */

  /// Performs a check-in by sending the user's location and a face image to the server.
  /// This is a multipart request because it includes both text fields and a file.
  Future<Map<String, dynamic>> checkIn({
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    // Retrieve the authentication token. Throws an exception if not logged in.
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    var uri = Uri.parse(_baseUrl); // POST request to /api/attendance
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString();

    // Determine the MIME type of the image file (e.g., 'image/jpeg').
    final mimeType = lookupMimeType(imageFile.path);
    // Add the image file to the multipart request.
    request.files.add(
      await http.MultipartFile.fromPath(
        'face', // The field name the server expects for the face image.
        imageFile.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ),
    );

    // Send the request and wait for the response.
    final streamedResponse = await request.send();
    // Read and decode the response body.
    final responseBody = await streamedResponse.stream.bytesToString();
    final responseData = json.decode(responseBody);

    // Check if the request was successful (status code 2xx).
    if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
      return responseData; // Return the JSON response data.
    } else {
      // If the request failed, throw an exception with the error message from the server.
      throw Exception(responseData['message'] ?? 'Check-in failed.');
    }
  }

  /// Performs a check-out by sending a face image to the server.
  Future<Map<String, dynamic>> checkOut({
    required File imageFile,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Authentication required.');

    var uri = Uri.parse('$_baseUrl/checkout'); // PUT request to /api/attendance/checkout
    var request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token';
    // No extra fields are needed for checkout, just the token and image.

    final mimeType = lookupMimeType(imageFile.path);
    request.files.add(
      await http.MultipartFile.fromPath(
        'face',
        imageFile.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    final responseData = json.decode(responseBody);

    if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Check-out failed.');
    }
  }

  /// Fetches the authenticated user's attendance record for the current day.
  static Future<Map<String, dynamic>?> getTodaysAttendance() async {
    final token = await AuthService.getToken();
    if (token == null) return null; // Can't fetch if not logged in.

    final uri = Uri.parse('$_baseUrl/me/today');
    try {
      // Send a standard GET request with the auth token.
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        // A successful response might still have an empty or "null" body.
        // This indicates that no attendance record exists for today yet.
        if (response.body.isNotEmpty && response.body != "null") {
          return jsonDecode(response.body);
        }
        return null; // No record found for today.
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch attendance status.');
      }
    } catch (e) {
      print("Error in getTodaysAttendance: $e");
      rethrow; // Re-throw the exception to be handled by the calling UI.
    }
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */