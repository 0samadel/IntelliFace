// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/dashboard/widgets/dashboard_view.dart
// Purpose: A professional and responsive content view for the dashboard screen.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../dashboard_layout.dart';
import 'summary_cards.dart';
import 'line_chart_card.dart';
import 'today_attendance_table.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback onNavigateToAttendance;
  const DashboardView({super.key, required this.onNavigateToAttendance});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Check for a wide screen to determine the layout
          final bool isWideScreen = constraints.maxWidth > 1200;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards are always at the top
                const SummaryCards(),
                const SizedBox(height: 24),

                // Conditionally build the next section based on screen width
                isWideScreen
                    ? _buildWideLayout(context)
                    : _buildNarrowLayout(context),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Layout for wide screens: Chart and Table are side-by-side.
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line chart takes up a larger portion of the space
        const Expanded(
          flex: 5, // e.g., 5 parts of the available space
          child: LineChartCard(),
        ),
        const SizedBox(width: 24),
        // Attendance table takes the remaining space
        Expanded(
          flex: 3, // e.g., 3 parts of the available space
          child: TodayAttendanceTable(onViewAllPressed: onNavigateToAttendance),
        ),
      ],
    );
  }

  /// Layout for narrow screens: All widgets are in a single column.
  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        const LineChartCard(),
        const SizedBox(height: 24),
        TodayAttendanceTable(onViewAllPressed: onNavigateToAttendance),
      ],
    );
  }
}