// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/employee/widgets/employee_list_header.dart
// Purpose: A professional and responsive header for the Employee screen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmployeeListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onSearchChanged;

  const EmployeeListHeader({
    super.key,
    required this.searchController,
    required this.onAddEmployee,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 850;

    return Row(
      children: [
        // --- Title with Icon ---
        Icon(LucideIcons.users, color: theme.textTheme.titleLarge?.color, size: 22),
        const SizedBox(width: 12),
        Text(
          "All Employees",
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
              hintText: 'Search employees...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              // Use a slightly different fill color to stand out
              fillColor: theme.scaffoldBackgroundColor,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),

        const SizedBox(width: 12),

        // --- Secondary Action Button (Example: Export) ---
        // This is an example of how to add more actions gracefully.
        // It uses an outlined style to be less prominent than the primary action.
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

        // --- Primary Action Button (Add Employee) ---
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.plus, size: 16),
          // On narrow screens, hide the text to save space
          label: isNarrow ? const SizedBox.shrink() : const Text("Add Employee"),
          onPressed: onAddEmployee,
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