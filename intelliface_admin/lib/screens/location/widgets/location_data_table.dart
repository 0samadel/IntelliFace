// ─────────────────────────────────────────────────────────────────────────────
// File: lib/screens/location/widgets/location_data_table.dart
// Purpose: A professional, theme-aware data table for locations with an
//          open design and enhanced UI/UX.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LocationDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> paginatedLocations;
  final Set<String> deletingLocationIds;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;
  final VoidCallback onAddFirstLocation;
  final int currentPage;
  final int rowsPerPage;
  final bool isSearchActive;
  final String searchQuery;

  const LocationDataTable({
    super.key,
    required this.paginatedLocations,
    required this.deletingLocationIds,
    required this.onEdit,
    required this.onDelete,
    required this.onAddFirstLocation,
    required this.currentPage,
    required this.rowsPerPage,
    required this.isSearchActive,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (paginatedLocations.isEmpty) return _buildEmptyState(context, theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: 15,
            horizontalMargin: 0,
            headingTextStyle: theme.dataTableTheme.headingTextStyle,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 58,
            showBottomBorder: true,
            dividerThickness: 1.0,
            columns: const [
              DataColumn(label: Text("#")),
              DataColumn(label: Text("LOCATION NAME")),
              DataColumn(label: Text("LATITUDE")),
              DataColumn(label: Text("LONGITUDE")),
              DataColumn(label: Text("RADIUS (m)")),
              DataColumn(label: Center(child: Text("ACTIONS"))),
            ],
            rows: paginatedLocations.asMap().entries.map((entry) {
              final int index = entry.key;
              final int displayRowNumber = currentPage * rowsPerPage + index + 1;
              return _buildDataRow(entry.value, displayRowNumber, theme, index);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final icon = isSearchActive ? LucideIcons.searchX : LucideIcons.mapPinOff;
    final message = isSearchActive ? "No locations found for '$searchQuery'." : "No locations defined yet.";
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.titleMedium),
          if (!isSearchActive) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text("Add First Location"),
              onPressed: onAddFirstLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ]
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> location, int index, ThemeData theme, int rowIndex) {
    final String locationId = location['_id']?.toString() ?? '';
    final bool isDeleting = deletingLocationIds.contains(locationId);

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
        DataCell(Text("$index", style: theme.textTheme.bodySmall)),

        // --- Pro Location Cell with Icon ---
        DataCell(
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 18, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location['name']?.toString() ?? 'N/A',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        DataCell(Text(location['latitude']?.toStringAsFixed(6) ?? 'N/A', style: theme.textTheme.bodyMedium)),
        DataCell(Text(location['longitude']?.toStringAsFixed(6) ?? 'N/A', style: theme.textTheme.bodyMedium)),
        DataCell(Text("${location['radius'] ?? 'N/A'} m", style: theme.textTheme.bodyMedium)),
        DataCell(
          Center(
            child: isDeleting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.error))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  theme: theme,
                  message: "Edit Location",
                  icon: LucideIcons.edit,
                  color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  onPressed: () => onEdit(location),
                ),
                _buildActionButton(
                  theme: theme,
                  message: "Delete Location",
                  icon: LucideIcons.trash2,
                  color: theme.colorScheme.error,
                  onPressed: () => onDelete(location),
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