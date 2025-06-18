// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/utils/app_styles.dart
// Purpose : The SINGLE SOURCE OF TRUTH for all application theming.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// LOGIN SCREEN STYLES (Special Case for Dark Mode)
// =============================================================================
class LoginColors {
  static const Color primaryAccent = Color(0xFF00B2FF);
  static const Color primaryAccentDark = Color(0xFF008FCC);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B3B8);
  static const Color textHint = Color(0xFF8A8D91);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassFill = Color(0x1AFFFFFF);
}

class LoginTextStyles {
  static TextStyle get screenTitle => GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w900, color: LoginColors.textPrimary, height: 1.2);
  static TextStyle get screenSubtitle => GoogleFonts.inter(fontSize: 18, color: LoginColors.textSecondary, height: 1.7);
  static TextStyle get cardTitle => GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: LoginColors.textPrimary);
}

// =============================================================================
// GLOBAL THEME DATA
// =============================================================================

class AppThemes {

  // --- LIGHT THEME DEFINITION ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF4154F1),
    scaffoldBackgroundColor: const Color(0xFFF4F6F8),
    fontFamily: GoogleFonts.inter().fontFamily,

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4154F1),
      secondary: Color(0xFF17A2B8),
      background: Color(0xFFF4F6F8),
      surface: Colors.white,
      onSurface: Color(0xFF012970),
      error: Color(0xFFDC3545),
      onError: Colors.white,
    ),

    // THE FIX IS HERE: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.05),
    ),

    inputDecorationTheme: _inputDecorationTheme(isDark: false),
    elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
    dataTableTheme: _dataTableTheme(isDark: false),
  );

  // --- DARK THEME DEFINITION ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00B2FF),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: GoogleFonts.inter().fontFamily,

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00B2FF),
      secondary: Color(0xFF00B2FF),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFEAEAEA),
      error: Color(0xFFE57373),
      onError: Colors.black,
    ),

    // THE FIX IS HERE: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),

    inputDecorationTheme: _inputDecorationTheme(isDark: true),
    elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
    dataTableTheme: _dataTableTheme(isDark: true),
  );

  // --- SHARED THEMED COMPONENT HELPERS ---

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    final colors = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8);
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFE0E0E0);
    final focusedColor = isDark ? const Color(0xFF00B2FF) : const Color(0xFF4154F1);

    return InputDecorationTheme(
      filled: true,
      fillColor: colors,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: focusedColor, width: 1.5)),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isDark}) {
    final primaryColor = isDark ? const Color(0xFF00B2FF) : const Color(0xFF4154F1);
    final onPrimaryColor = isDark ? Colors.black : Colors.white;

    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static DataTableThemeData _dataTableTheme({required bool isDark}) {
    final headerColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;
    final onHeaderColor = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF576A7C);

    return DataTableThemeData(
      headingRowColor: MaterialStateProperty.all(headerColor),
      dividerThickness: isDark ? 0.1 : 1.0,
      headingTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: onHeaderColor),
    );
  }
}