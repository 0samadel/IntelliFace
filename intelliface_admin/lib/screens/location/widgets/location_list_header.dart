// ─────────────────────────────────────────────────────────────
// File: lib/screens/location/widgets/location_list_header.dart
// Purpose: A professional and responsive header for the Location screen.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LocationListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onAddLocation;
  final ValueChanged<String> onSearchChanged;

  const LocationListHeader({
    super.key,
    required this.searchController,
    required this.onAddLocation,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 850;

    return Row(
      children: [
        // --- Title with Icon ---
        Icon(LucideIcons.map, color: theme.textTheme.titleLarge?.color, size: 22),
        const SizedBox(width: 12),
        Text(
          "Registered Locations",
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
              hintText: 'Search locations...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              fillColor: theme.scaffoldBackgroundColor,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),

        const SizedBox(width: 12),

        // --- Secondary Action Button (Example) ---
        if (!isNarrow)
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement other functionality, e.g., view on map
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Future action placeholder."))
              );
            },
            icon: const Icon(LucideIcons.globe, size: 16),
            label: const Text("View Map"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
              foregroundColor: theme.textTheme.bodyMedium?.color,
              side: BorderSide(color: theme.dividerColor),
            ),
          ),

        const SizedBox(width: 12),

        // --- Primary Action Button (Add Location) ---
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.plus, size: 16),
          label: isNarrow ? const SizedBox.shrink() : const Text("Add Location"),
          onPressed: onAddLocation,
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