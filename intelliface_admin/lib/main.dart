// ─────────────────────────────────────────────────────────────────────────────
// File    : main.dart
// Purpose : Entry point of the Flutter admin dashboard application.
//           Initializes theme management with Provider.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/employee/employee_list_screen.dart';

// Providers & Styles
import 'providers/theme_provider.dart';
import 'utils/app_styles.dart';

void main() {
  runApp(
    // Wrap the entire app in a ChangeNotifierProvider.
    // This makes the ThemeProvider available to all widgets in the tree.
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const AdminApp(),
    ),
  );
}

/// Root widget for the admin dashboard application
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the ThemeProvider for changes.
    // When the theme changes, this widget will rebuild.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'IntelliFace Admin',
      debugShowCheckedModeBanner: false,

      // Use the pre-defined themes from your app_styles.dart
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,

      // The current theme mode is controlled by our provider state.
      themeMode: themeProvider.themeMode,

      // Initial screen on app launch
      initialRoute: '/login',

      // Application route definitions
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/employees': (context) => const EmployeeListScreen(),
        // Add other routes here as you create them
        // '/departments': (context) => const DepartmentScreen(),
        // '/locations': (context) => const LocationScreen(),
        // '/attendance': (context) => const AttendanceScreen(),
      },
    );
  }
}