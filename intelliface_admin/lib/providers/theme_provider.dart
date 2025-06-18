// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/providers/theme_provider.dart
// Purpose : Advanced theme state management with persistence.
//           Handles three modes: Light, Dark, and System.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Use a clear enum for the three theme options.
enum ThemePreference { system, light, dark }

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'themePreference';

  // Default to following the system theme.
  ThemeMode _themeMode = ThemeMode.system;
  ThemePreference _themePreference = ThemePreference.system;

  ThemeMode get themeMode => _themeMode;
  ThemePreference get themePreference => _themePreference;

  ThemeProvider() {
    _loadThemePreference(); // Load the saved preference on app start
  }

  // --- Persistence Logic ---

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved preference as a string, default to 'system'.
    final savedTheme = prefs.getString(_themePrefKey) ?? 'system';

    switch (savedTheme) {
      case 'light':
        _themePreference = ThemePreference.light;
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themePreference = ThemePreference.dark;
        _themeMode = ThemeMode.dark;
        break;
      default: // 'system'
        _themePreference = ThemePreference.system;
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  Future<void> _saveThemePreference(ThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    // Save the preference as a simple string.
    await prefs.setString(_themePrefKey, preference.name);
  }

  // --- UI-facing Logic ---

  // This is the new function the UI will call.
  void setTheme(ThemePreference preference) {
    if (_themePreference == preference) return; // No change needed

    _themePreference = preference;

    switch (preference) {
      case ThemePreference.light:
        _themeMode = ThemeMode.light;
        break;
      case ThemePreference.dark:
        _themeMode = ThemeMode.dark;
        break;
      case ThemePreference.system:
        _themeMode = ThemeMode.system;
        break;
    }

    _saveThemePreference(preference); // Save the new choice
    notifyListeners(); // Notify the app to rebuild
  }
}