// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/attendance/widgets/attendance_data_table.dart
// Purpose: A professional, theme-aware data table for attendance records with
//          perfect column alignment using the Table widget.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AttendanceDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final Set<String> deletingRecordIds;
  final Function(Map<String, dynamic>) onDelete;
  final DateTime selectedDate;
  final String selectedStatusFilter;
  final int currentPage;
  final int rowsPerPage;

  const AttendanceDataTable({
    super.key,
    required this.records,
    required this.deletingRecordIds,
    required this.onDelete,
    required this.selectedDate,
    required this.selectedStatusFilter,
    required this.currentPage,
    required this.rowsPerPage,
  });

  DateTime? _parseApiDateTime(String? dateString) {
    if (dateString == null) return null;
    return DateTime.tryParse(dateString)?.toLocal();
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '–';
    return DateFormat.jm().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.calendarSearch, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text(
                "No records found for ${DateFormat.yMMMMd().format(selectedDate)}\nwith status: '$selectedStatusFilter'.",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // --- Custom Table Header ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.dataTableTheme.headingRowColor?.resolve({}),
            border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0)),
          ),
          child: Table(
            columnWidths: _columnWidths,
            children: [
              TableRow(
                children: [
                  _buildHeaderCell(context, "EMPLOYEE"),
                  _buildHeaderCell(context, "CHECK-IN", alignment: TextAlign.center),
                  _buildHeaderCell(context, "CHECK-OUT", alignment: TextAlign.center),
                  _buildHeaderCell(context, "STATUS", alignment: TextAlign.center),
                  _buildHeaderCell(context, "ACTION", alignment: TextAlign.center),
                ],
              ),
            ],
          ),
        ),

        // --- Table Rows ---
        ...records.asMap().entries.map((entry) {
          return _buildDataTableRow(entry.value, theme, entry.key);
        }),
      ],
    );
  }

  // Define column widths in one place for consistency
  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FlexColumnWidth(2.5), // Employee
    1: FlexColumnWidth(1),   // Check-in
    2: FlexColumnWidth(1),   // Check-out
    3: FlexColumnWidth(1.2), // Status
    4: FlexColumnWidth(0.8), // Action
  };

  // --- Helper to build header cells ---
  Widget _buildHeaderCell(BuildContext context, String text, {TextAlign alignment = TextAlign.left}) {
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

  // --- Helper to build data rows ---
  Widget _buildDataTableRow(Map<String, dynamic> record, ThemeData theme, int rowIndex) {
    final user = record['userId'] as Map<String, dynamic>?;
    final employeeName = user?['fullName']?.toString() ?? 'N/A';
    final checkInTime = _formatTime(_parseApiDateTime(record['checkInTime'] as String?));
    final checkOutTime = _formatTime(_parseApiDateTime(record['checkOutTime'] as String?));
    final status = record['status']?.toString() ?? 'N/A';
    final recordApiId = record['_id']?.toString() ?? '';
    final isDeleting = deletingRecordIds.contains(recordApiId);

    Color statusColor;
    if (status == 'Present') statusColor = Colors.green;
    else if (status == 'Late') statusColor = Colors.orange;
    else statusColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: rowIndex.isOdd ? theme.colorScheme.onSurface.withOpacity(0.02) : Colors.transparent,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Table(
        columnWidths: _columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              // Employee Cell
              Row(
                children: [
                  const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/profile_photo.jpg')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(employeeName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              // Check-in Cell
              Center(child: Text(checkInTime, style: theme.textTheme.bodyMedium)),
              // Check-out Cell
              Center(child: Text(checkOutTime, style: theme.textTheme.bodyMedium)),
              // Status Cell
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ),
              // Action Cell
              Center(
                child: isDeleting
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.error))
                    : Tooltip(
                  message: "Delete Record",
                  child: IconButton(
                    icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error, size: 20),
                    onPressed: recordApiId.isEmpty ? null : () => onDelete(record),
                    splashRadius: 20,
                    padding: const EdgeInsets.all(8),
                    hoverColor: theme.colorScheme.error.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}