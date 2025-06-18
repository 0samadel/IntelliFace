// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/utils/app_styles.dart
// Purpose : Defines the application's color palette, text styles, and decorations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// A class that holds the primary color palette for the entire application.
/// Using a centralized class for colors ensures brand consistency and makes
/// theme updates easier.
class AppColors {
  // --- Core Colors ---
  /// The main brand color, used for app bars, primary buttons, and key UI elements.
  static const Color primaryBlue = Color(0xFF0047B3);
  /// A secondary accent color for highlights or specific components.
  static const Color accentTeal = Color(0xFF17A2B8);

  // --- Text Colors ---
  /// The primary color for main text content, offering high contrast.
  static const Color textPrimary = Color(0xFF012970);
  /// A lighter, secondary color for subtitles, hints, and less important text.
  static const Color textSecondary = Color(0xFF576A7C);

  // --- UI Element Colors ---
  /// The color for dividers, borders, and outlines.
  static const Color border = Color(0xFFE0E0E0);
  /// The default background color for cards and elevated components.
  static const Color cardBackground = Colors.white;
  /// The main background color for most screens.
  static const Color pageBackground = Color(0xFFF4F6F8);

  // --- Semantic Colors ---
  /// Used for success messages, valid states, and positive actions.
  static const Color success = Color(0xFF28A745);
  /// Used for warnings, alerts, and highlighting important information.
  static const Color warning = Color(0xFFFFC107);
  /// Used for error messages, invalid states, and destructive actions.
  static const Color error = Color(0xFFDC3545);
  /// A specific alias for the logout button and dialog to make its purpose clear.
  static const Color logoutColor = Color(0xFFDC3545);

  // --- Icon & Accent Colors ---
  /// The default color for general icons throughout the app.
  static const Color iconDefault = Color(0xFF576A7C);
  /// A lighter blue used for specific accents, like the profile camera icon background.
  static const Color lightBlue = Color(0xFF6BA6FF);
}

/// A class that centralizes all text styling for the application.
/// This ensures typographic consistency and simplifies style management.
class AppTextStyles {
  // --- General Text Styles ---
  /// Style for main screen titles.
  static const TextStyle screenTitle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontFamily: 'Poppins');
  /// Style for screen subtitles, typically appearing below the main title.
  static const TextStyle screenSubtitle = TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'Poppins');
  /// Style for titles within cards or other components.
  static const TextStyle cardTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins');
  /// Style for subtitles within cards.
  static const TextStyle cardSubtitle = TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'Poppins');
  /// Default style for body text.
  static const TextStyle bodyText1 = TextStyle(fontSize: 16, color: AppColors.textPrimary, fontFamily: 'Poppins');
  /// Default style for text on primary buttons.
  static const TextStyle buttonText = TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500, fontFamily: 'Poppins');
  /// Style for text within data table cells.
  static const TextStyle tableCell = TextStyle(fontSize: 14, color: AppColors.textPrimary, fontFamily: 'Poppins');
  /// Style for data table headers.
  static const TextStyle tableHeader = TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins');
  /// Style for labels on filter controls.
  static const TextStyle filterLabel = TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontFamily: 'Poppins');

  /// A helper function (factory) to create a `TextStyle` with the Poppins font family.
  /// This is useful for creating dynamic or one-off styles without boilerplate.
  static TextStyle poppins(double size, Color color, FontWeight weight, {double? letterSpacing, double? height}) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // --- Screen-Specific Styles ---
  /// A specific style for the user's name in the profile screen header.
  static TextStyle profileHeaderName = poppins(22, Colors.white, FontWeight.bold, letterSpacing: 0.5);
  /// A specific style for the greeting message ("Hello") in the profile screen header.
  static TextStyle profileHeaderGreeting = poppins(15, Colors.white70, FontWeight.normal);
  /// The style for the title of each option tile on the profile screen (e.g., "Settings", "Logout").
  static TextStyle profileOptionTitle = poppins(15, AppColors.textPrimary, FontWeight.w500);
  /// The style for labels above text fields on the profile edit screen.
  static TextStyle profileEditFieldLabel = poppins(13, AppColors.textSecondary, FontWeight.w500);
  /// The style for the text that the user inputs into fields on the profile edit screen.
  static TextStyle profileEditFieldValue = poppins(15, AppColors.textPrimary, FontWeight.w500);
}

/// A class that centralizes all component decorations, such as borders, shadows, and shapes.
class AppDecorations {
  /// The standard decoration for most cards, featuring a white background, rounded corners, and a subtle shadow.
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  /// The decoration for filter control elements, like dropdowns or date pickers.
  static final BoxDecoration filterControlDecoration = BoxDecoration(
    color: AppColors.cardBackground,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(8),
  );

  /// A specific decoration for the option tiles on the profile screen, featuring a larger radius and a different shadow.
  static BoxDecoration profileOptionTileDecoration = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade200,
        blurRadius: 8,
        offset: const Offset(0, 2),
      )
    ],
  );
}
/* ───────────────────────────────────────────────────────────────────────────── */