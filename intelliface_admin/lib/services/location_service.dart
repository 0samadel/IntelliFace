// ─────────────────────────────────────────────────────────────────────────────
// File    : location_service.dart
// Purpose : Handles CRUD operations for location entities.
// Used by : Admin panel for managing work locations or offices.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // Base API URL for location endpoints
  static const String baseUrl = 'https://intelliface-api.onrender.com/api/locations';

  /// Fetch all registered locations from the server.
  ///
  /// Returns a list of location objects.
  /// Throws [Exception] if the request fails.
  static Future<List<Map<String, dynamic>>> fetchLocations() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      print('❌ Failed to fetch locations: ${response.statusCode} ${response.body}');
      throw Exception('Failed to fetch locations');
    }
  }

  /// Create a new location on the server.
  ///
  /// - [location]: a map containing fields like `name`, `coordinates`, etc.
  /// Returns the created location document or null if it fails.
  static Future<Map<String, dynamic>?> createLocation(Map<String, dynamic> location) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(location),
    );

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      print('❌ Failed to create location: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  /// Update an existing location by ID.
  ///
  /// - [id]: location's unique MongoDB ID
  /// - [location]: map of updated location fields
  /// Returns the updated location or null on failure.
  static Future<Map<String, dynamic>?> updateLocation(String id, Map<String, dynamic> location) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(location),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      print('❌ Failed to update location: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  /// Delete a location by ID.
  ///
  /// Returns true if deletion was successful, false otherwise.
  static Future<bool> deleteLocation(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      print('❌ Failed to delete location: ${response.statusCode} ${response.body}');
      return false;
    }
  }
}
