// ─────────────────────────────────────────────────────────────────────────────
// File    : face_service.dart (Corrected and Final Version)
// Purpose : Handles all face recognition API calls such as face enrollment.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart'; // 1. ADD THIS IMPORT
import 'package:mime/mime.dart';                 // 2. ADD THIS IMPORT

import 'auth_service.dart';

class FaceService {
  // Base URL for all face recognition API routes
  static const String _baseUrl = 'https://intelliface-api.onrender.com/api/faces';

  /// Enroll an employee's face by uploading an image to the backend.
  static Future<void> enrollFace(String userId, PlatformFile faceImage) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Admin not authenticated. Please log in again.');
    }

    // 3. Determine the MIME type of the image from its filename.
    final mimeType = lookupMimeType(faceImage.name);

    final uri = Uri.parse('$_baseUrl/enroll/$userId');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'face',
          faceImage.bytes!,
          filename: faceImage.name,

          // 4. ADD THE contentType property here.
          // This tells the server what kind of file you are sending.
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      String errorMessage = 'Failed to enroll face.';
      try {
        final errorData = json.decode(responseBody);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (_) {
        // Leave default error message
      }
      throw Exception('$errorMessage (Status: ${streamedResponse.statusCode})');
    }
  }
}