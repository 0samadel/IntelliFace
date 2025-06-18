// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/employee/widgets/employee_data_table.dart
// Purpose: A professional, theme-aware data table for employees with rich cells,
//          soft row colors, and an open design.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmployeeDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> paginatedEmployees;
  final int currentPage;
  final int rowsPerPage;
  final Set<String> deletingEmployeeIds;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onEnrollFace;

  const EmployeeDataTable({
    super.key,
    required this.paginatedEmployees,
    required this.currentPage,
    required this.rowsPerPage,
    required this.deletingEmployeeIds,
    required this.onEdit,
    required this.onDelete,
    required this.onEnrollFace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (paginatedEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.userX, size: 48, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text("No employees found.", style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 0,
            headingTextStyle: theme.dataTableTheme.headingTextStyle,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 68,
            showBottomBorder: true,
            dividerThickness: 1.0,
            columns: const [
              DataColumn(label: Text("#")),
              DataColumn(label: Text("EMPLOYEE ID")),
              DataColumn(label: Text("EMPLOYEE")),
              DataColumn(label: Text("EMAIL")),
              DataColumn(label: Text("DEPARTMENT")),
              DataColumn(label: Center(child: Text("ACTIONS"))),
            ],
            rows: paginatedEmployees.asMap().entries.map((entry) {
              final int index = entry.key;
              final int displayRowNumber = currentPage * rowsPerPage + index + 1;
              return _buildDataTableRow(entry.value, displayRowNumber, theme, index);
            }).toList(),
          ),
        );
      },
    );
  }

  DataRow _buildDataTableRow(Map<String, dynamic> emp, int displayRowNumber, ThemeData theme, int rowIndex) {
    final String employeeDbApiId = emp['_id']?.toString() ?? '';
    final bool isDeleting = deletingEmployeeIds.contains(employeeDbApiId);
    final String departmentName = emp['department']?['name']?.toString() ?? 'N/A';
    final bool hasFaceEnrolled = emp['faceDescriptor'] != null && (emp['faceDescriptor'] as List).isNotEmpty;

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.hovered)) {
          return theme.colorScheme.primary.withOpacity(0.04);
        }
        if (rowIndex.isOdd) {
          return theme.colorScheme.onSurface.withOpacity(0.02);
        }
        return null;
      }),
      cells: [
        DataCell(Text("$displayRowNumber", style: theme.textTheme.bodySmall)),
        DataCell(Text(emp["employeeId"]?.toString() ?? 'N/A', style: theme.textTheme.bodyMedium)),
        DataCell(
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/profile_photo.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp["fullName"]?.toString() ?? 'N/A', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(emp["username"]?.toString() ?? 'N/A', style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(emp["email"]?.toString() ?? 'N/A', style: theme.textTheme.bodyMedium)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(departmentName, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
          ),
        ),
        DataCell(
          Center(
            child: isDeleting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.error))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(theme: theme, message: hasFaceEnrolled ? "Face Already Enrolled" : "Enroll Face Photo", icon: LucideIcons.scanFace, color: hasFaceEnrolled ? Colors.green : theme.colorScheme.primary, onPressed: () => onEnrollFace(emp)),
                _buildActionButton(theme: theme, message: "Edit Employee", icon: LucideIcons.edit, color: theme.textTheme.bodySmall?.color ?? Colors.grey, onPressed: () => onEdit(emp)),
                _buildActionButton(theme: theme, message: "Delete Employee", icon: LucideIcons.trash2, color: theme.colorScheme.error, onPressed: () => onDelete(emp)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required String message,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: message,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        splashRadius: 20,
        padding: const EdgeInsets.all(8),
        visualDensity: VisualDensity.compact,
        hoverColor: color.withOpacity(0.1),
      ),
    );
  }
}