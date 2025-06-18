// ─────────────────────────────────────────────────────────────────────────────
// File    : dashboard_service.dart
// Purpose : Fetches statistics and analytics data for the admin dashboard.
// Used by : Dashboard screen to display trends, summaries, and KPIs.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  // Base API URL for dashboard-related endpoints
  static const String _baseUrl = 'https://intelliface-api.onrender.com/api/dashboard';

  /// Fetch dashboard statistics and trends from the server.
  ///
  /// - [trendDays]: number of days to show trend data for (default is 7).
  /// Returns a map containing stats such as attendance summary, counts, etc.
  /// Throws [Exception] with detailed error message if the fetch fails.
  static Future<Map<String, dynamic>> fetchDashboardStats({int trendDays = 7}) async {
    final url = Uri.parse('$_baseUrl/stats?trendDays=$trendDays');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      // Log server response for debugging
      print('❌ Failed to load dashboard stats: ${response.statusCode} ${response.body}');

      // Attempt to extract and show server-side error message
      String errorMessage = 'Failed to load dashboard stats.';
      try {
        final errorData = json.decode(response.body);
        if (errorData['error'] != null) {
          errorMessage += ' Server: ${errorData['error']}';
        }
      } catch (_) {
        // If response is not JSON, ignore
      }

      throw Exception(errorMessage);
    }
  }
}
