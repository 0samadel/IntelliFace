// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/department/widgets/department_data_table.dart
// Purpose: A professional, theme-aware data table for departments with an
//          open design and enhanced UI/UX.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DepartmentDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> paginatedDepartments;
  final int currentPage;
  final int rowsPerPage;
  final Set<String> deletingDepartmentIds;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  const DepartmentDataTable({
    super.key,
    required this.paginatedDepartments,
    required this.currentPage,
    required this.rowsPerPage,
    required this.deletingDepartmentIds,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (paginatedDepartments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.building2, size: 48, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text("No departments found.", style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 0,
            headingTextStyle: theme.dataTableTheme.headingTextStyle,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 58,
            showBottomBorder: true,
            dividerThickness: 1.0, // Theme will provide the color
            columns: const [
              DataColumn(label: Text("#")),
              DataColumn(label: Text("DEPARTMENT NAME")),
              DataColumn(label: Text("LOCATION")),
              DataColumn(label: Center(child: Text("ACTIONS"))),
            ],
            rows: paginatedDepartments.asMap().entries.map((entry) {
              final int index = entry.key;
              final displayRowNumber = currentPage * rowsPerPage + index + 1;
              return _buildDataTableRow(entry.value, displayRowNumber, theme, index);
            }).toList(),
          ),
        );
      },
    );
  }

  DataRow _buildDataTableRow(Map<String, dynamic> dep, int displayRowNumber, ThemeData theme, int rowIndex) {
    final String departmentId = dep['_id']?.toString() ?? '';
    final bool isDeleting = deletingDepartmentIds.contains(departmentId);
    final String locationName = dep['location']?['name']?.toString() ?? 'N/A';

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

        // --- Pro Department Cell with Icon ---
        DataCell(
          Row(
            children: [
              Icon(LucideIcons.building, size: 20, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dep['name']?.toString() ?? 'N/A',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              locationName,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        DataCell(
          Center(
            child: isDeleting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.error))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  theme: theme,
                  message: "Edit Department",
                  icon: LucideIcons.edit,
                  color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  onPressed: () => onEdit(dep),
                ),
                _buildActionButton(
                  theme: theme,
                  message: "Delete Department",
                  icon: LucideIcons.trash2,
                  color: theme.colorScheme.error,
                  onPressed: () => onDelete(dep),
                ),
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