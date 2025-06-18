// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/utils/api_constants.dart
// Purpose : Define API endpoints based on environment (dev vs production)
// Access  : Global utility
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart'; // For kIsWeb and kReleaseMode

class ApiConstants {
  /* ============================================================================
   * 1. Production (Render Server)
   * ========================================================================== */

  /// Base URL of the deployed API server (used in release or web mode)
  static const String _prodServerBase = "https://intelliface-api.onrender.com";

  /// Full API base URL for the production server (with /api)
  static const String _prodApiBaseUrl = "$_prodServerBase/api";


  /* ============================================================================
   * 2. Local Development Server (localhost)
   * ========================================================================== */

  /// Base URL for the local development server
  static const String _localDevServerBase = "http://localhost:5100";

  /// Full API base URL for the local server (with /api)
  static const String _localDevApiBaseUrl = "$_localDevServerBase/api";


  /* ============================================================================
   * 3. Dynamic Environment Selector
   * ========================================================================== */

  /// Returns base server URL (without `/api`) depending on mode
  static String get serverBaseUrl {
    return (kReleaseMode || kIsWeb)
        ? _prodServerBase
        : _localDevServerBase;
  }

  /// Returns full base API URL (with `/api`) depending on mode
  static String get baseUrl {
    return (kReleaseMode || kIsWeb)
        ? _prodApiBaseUrl
        : _localDevApiBaseUrl;
  }
}
