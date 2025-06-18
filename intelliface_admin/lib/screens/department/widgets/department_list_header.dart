// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/department/widgets/department_list_header.dart
// Purpose: A professional and responsive header for the Department screen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DepartmentListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onAddDepartment;
  final ValueChanged<String> onSearchChanged;

  const DepartmentListHeader({
    super.key,
    required this.searchController,
    required this.onAddDepartment,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A simple check for screen width to make the UI responsive
    final isNarrow = MediaQuery.of(context).size.width < 850;

    return Row(
      children: [
        // --- Title with Icon ---
        Icon(LucideIcons.building2, color: theme.textTheme.titleLarge?.color, size: 22),
        const SizedBox(width: 12),
        Text(
          "All Departments",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),

        const Spacer(), // Pushes all actions to the right

        // --- Search Box ---
        SizedBox(
          width: 280,
          height: 42,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search departments...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              // Use a slightly different fill color to stand out
              fillColor: theme.scaffoldBackgroundColor,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),

        const SizedBox(width: 12),

        // --- Secondary Action Button (Example: Export) ---
        if (!isNarrow) // Hide on narrow screens to save space
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Export action not implemented yet."))
              );
            },
            icon: const Icon(LucideIcons.fileDown, size: 16),
            label: const Text("Export"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
              foregroundColor: theme.textTheme.bodyMedium?.color,
              side: BorderSide(color: theme.dividerColor),
            ),
          ),

        const SizedBox(width: 12),

        // --- Primary Action Button (Add Department) ---
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.plus, size: 16),
          // On narrow screens, hide the text to save space
          label: isNarrow ? const SizedBox.shrink() : const Text("Add Department"),
          onPressed: onAddDepartment,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 18,
                vertical: 21
            ),
          ),
        ),
      ],
    );
  }
}