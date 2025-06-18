// ─────────────────────────────────────────────────────────────────────────────
// File    : utils/api_constants.dart
// Purpose : Centralized repository for all API and server-related constants.
// Notes   : To switch environments, modify the public getters in section #2.
// ─────────────────────────────────────────────────────────────────────────────

class ApiConstants {
  ApiConstants._(); // Prevents class instantiation.

  /* ============================================================================
   * 1. Environment Definitions
   * ========================================================================== */

  // --- Production ---
  static const String _prodServerBase = "https://intelliface-api.onrender.com";
  static const String _prodApiBaseUrl = "$_prodServerBase/api";

  // --- Local Development (Inactive) ---
  static const String _localDevServerBase = "http://localhost:5100";
  static const String _androidEmulatorServerBase = "http://10.0.2.2:5100";
  static const String _wifiDevServerBase = 'http://192.168.1.113:5100'; // NOTE: Update with your local IP

  static const String _localDevAndroidEmulatorApiBaseUrl = "$_androidEmulatorServerBase/api";
  static const String _localDevIOSEmulatorOrWebApiBaseUrl = "$_localDevServerBase/api";
  static const String _wifiDevApiBaseUrl = "$_wifiDevServerBase/api";


  /* ============================================================================
   * 2. Public URL Accessors
   * ========================================================================== */

  // Currently configured to use: PRODUCTION
  static String get serverBaseUrl {
    return _prodServerBase; // → https://intelliface-api.onrender.com
  }

  // Currently configured to use: PRODUCTION
  static String get baseUrl {
    return _prodApiBaseUrl; // → https://intelliface-api.onrender.com/api
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */