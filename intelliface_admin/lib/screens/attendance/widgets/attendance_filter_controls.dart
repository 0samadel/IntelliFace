// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/attendance/widgets/attendance_filter_controls.dart
// Purpose: Fully theme-aware filter controls for the Attendance screen.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AttendanceFilterControls extends StatelessWidget {
  final DateTime selectedDate;
  final String selectedStatusFilter;
  final VoidCallback onPickDate;
  final VoidCallback onExport;
  final ValueChanged<String?> onStatusChanged;

  const AttendanceFilterControls({
    super.key,
    required this.selectedDate,
    required this.selectedStatusFilter,
    required this.onPickDate,
    required this.onExport,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            "Records for: ${DateFormat.yMMMMd().format(selectedDate)}",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 20),

        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatusFilter,
              dropdownColor: theme.colorScheme.surface,
              icon: Icon(LucideIcons.filter, color: theme.textTheme.bodySmall?.color, size: 18),
              onChanged: onStatusChanged,
              style: theme.textTheme.bodyMedium,
              items: ['All', 'Present', 'Late']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: Text(DateFormat.yMMMd().format(selectedDate)),
            onPressed: onPickDate,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.background,
              foregroundColor: theme.textTheme.bodyLarge?.color,
              elevation: 0,
              side: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.download, size: 16),
            label: const Text("Export"),
            onPressed: onExport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Keep export button consistently green
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}