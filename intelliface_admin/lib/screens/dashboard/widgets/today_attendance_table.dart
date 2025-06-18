// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/dashboard/widgets/today_attendance_table.dart
// Purpose: A professional, theme-aware snapshot of today's attendance with
//          perfect column alignment and spacing.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/attendance_service.dart';

class TodayAttendanceTable extends StatefulWidget {
  final VoidCallback onViewAllPressed;
  const TodayAttendanceTable({super.key, required this.onViewAllPressed});
  @override
  State<TodayAttendanceTable> createState() => _TodayAttendanceTableState();
}

class _TodayAttendanceTableState extends State<TodayAttendanceTable> {
  List<Map<String, dynamic>> _todayAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayAttendance();
  }

  Future<void> _fetchTodayAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final allAttendance = await AttendanceService.fetchAllAttendanceRecords();
      if (!mounted) return;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
      _todayAttendance = allAttendance.where((att) {
        final checkInTime = DateTime.tryParse(att['checkInTime'] ?? '')?.toLocal();
        return checkInTime != null && checkInTime.isAfter(todayStart) && checkInTime.isBefore(todayEnd);
      }).toList();
      _todayAttendance.sort((a, b) {
        final timeA = DateTime.tryParse(a['checkInTime'] ?? '')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = DateTime.tryParse(b['checkInTime'] ?? '')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeA.compareTo(timeB);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading today's attendance: $e"), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '–';
    return DateFormat.jm().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.brightness == Brightness.light ? 2 : 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Attendance Snapshot", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (!_isLoading && _todayAttendance.length > 5)
                  OutlinedButton.icon(
                    onPressed: widget.onViewAllPressed,
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading ? _buildLoadingShimmer(theme) : _buildContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_todayAttendance.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Column(
            children: [
              Icon(LucideIcons.calendarX, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text("No attendance records for today yet.", style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Table(
      // THE FIX IS HERE: Using a Table widget for precise column control
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(2.5), // Employee column takes up the most space
        1: FlexColumnWidth(1),   // Check-in
        2: FlexColumnWidth(1),   // Check-out
        3: FlexColumnWidth(1),   // Status
      },
      children: [
        // --- Table Header ---
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0)),
          ),
          children: [
            _buildHeaderCell("EMPLOYEE"),
            _buildHeaderCell("CHECK-IN", alignment: TextAlign.center),
            _buildHeaderCell("CHECK-OUT", alignment: TextAlign.center),
            _buildHeaderCell("STATUS", alignment: TextAlign.center),
          ],
        ),
        // --- Table Rows ---
        ..._todayAttendance.take(5).map((entry) {
          final user = entry['userId'] as Map<String, dynamic>?;
          final checkInDateTime = DateTime.tryParse(entry['checkInTime'] ?? '')?.toLocal();
          final checkOutDateTime = DateTime.tryParse(entry['checkOutTime'] ?? '')?.toLocal();
          String statusText = entry["status"]?.toString() ?? 'N/A';

          Color statusColor;
          if (statusText == "Present") statusColor = Colors.green;
          else if (statusText == "Late") statusColor = Colors.orange;
          else statusColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

          return TableRow(
            children: [
              _buildEmployeeCell(theme, user),
              _buildTimeCell(theme, _formatTime(checkInDateTime)),
              _buildTimeCell(theme, _formatTime(checkOutDateTime)),
              _buildStatusCell(theme, statusText, statusColor),
            ],
          );
        }),
      ],
    );
  }

  // --- Helper methods for building table cells for cleaner code ---
  TableCell _buildHeaderCell(String text, {TextAlign alignment = TextAlign.left}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          text,
          textAlign: alignment,
          style: Theme.of(context).dataTableTheme.headingTextStyle,
        ),
      ),
    );
  }

  TableCell _buildEmployeeCell(ThemeData theme, Map<String, dynamic>? user) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/profile_photo.jpg')),
            const SizedBox(width: 12),
            Expanded(child: Text(user?['fullName']?.toString() ?? 'N/A', style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  TableCell _buildTimeCell(ThemeData theme, String time) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(child: Text(time, style: theme.textTheme.bodyMedium)),
    );
  }

  TableCell _buildStatusCell(ThemeData theme, String text, Color color) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Text(text, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.colorScheme.onSurface.withOpacity(0.1),
      child: Column(
        children: List.generate(5, (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Container(height: 16, width: 120, color: Colors.white),
              const Spacer(),
              Container(height: 16, width: 60, color: Colors.white),
              const Spacer(),
              Container(height: 16, width: 60, color: Colors.white),
              const Spacer(),
              Container(height: 24, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ],
          ),
        )),
      ),
    );
  }
}