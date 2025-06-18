// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/dashboard/dashboard_screen.dart
// Purpose: Main dashboard shell, now fully theme-aware.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../attendance/attendance_screen.dart';
import '../employee/employee_list_screen.dart';
import '../department/department_screen.dart';
import '../location/location_screen.dart';
import 'widgets/dashboard_view.dart';
import 'dashboard_sidebar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedMenu = 'Dashboard';

  void _navigateTo(String menu) {
    if (mounted) {
      setState(() => _selectedMenu = menu);
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedMenu) {
      case 'Dashboard':
        return DashboardView(onNavigateToAttendance: () => _navigateTo('Attendance'));
      case 'Attendance':
        return const AttendanceScreen();
      case 'Employee':
        return const EmployeeListScreen();
      case 'Department':
        return const DepartmentScreen();
      case 'Location':
        return const LocationScreen();
      default:
      // A fallback screen that respects the current theme
        return Center(
          child: Text(
            "Page not found",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color is now automatically handled by the theme
      // set in main.dart. No need to specify it here.
      body: Row(
        children: [
          DashboardSidebar(
            selected: _selectedMenu,
            onSelect: _navigateTo,
          ),
          Expanded(child: _getSelectedScreen()),
        ],
      ),
    );
  }
}