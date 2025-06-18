// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/dashboard_layout.dart
// Purpose: A professional, theme-aware layout with a functional top bar.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _TopBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isCurrentlyDark = theme.brightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1)),
      ),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 320,
            height: 40,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search anything...',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 16),
          _ThemeSwitcher(themeProvider: themeProvider, isCurrentlyDark: isCurrentlyDark),
          const SizedBox(width: 8),
          Tooltip(
            message: "Notifications",
            child: IconButton(
              icon: Icon(LucideIcons.bell, color: theme.textTheme.bodySmall?.color, size: 22),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          VerticalDivider(indent: 16, endIndent: 16, color: theme.dividerColor.withOpacity(0.2)),
          const SizedBox(width: 8),
          _ProfileDropdown(),
        ],
      ),
    );
  }
}

class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher({
    required this.themeProvider,
    required this.isCurrentlyDark,
  });

  final ThemeProvider themeProvider;
  final bool isCurrentlyDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change Theme',
      child: PopupMenuButton<ThemePreference>(
        onSelected: (preference) => themeProvider.setTheme(preference),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        icon: Icon(isCurrentlyDark ? LucideIcons.moon : LucideIcons.sun, color: Theme.of(context).textTheme.bodySmall?.color, size: 22),
        itemBuilder: (context) => <PopupMenuEntry<ThemePreference>>[
          _buildThemeMenuItem(context, themeProvider.themePreference, ThemePreference.light, LucideIcons.sun, 'Light'),
          _buildThemeMenuItem(context, themeProvider.themePreference, ThemePreference.dark, LucideIcons.moon, 'Dark'),
          const PopupMenuDivider(),
          _buildThemeMenuItem(context, themeProvider.themePreference, ThemePreference.system, LucideIcons.laptop, 'System Default'),
        ],
      ),
    );
  }

  PopupMenuItem<ThemePreference> _buildThemeMenuItem(BuildContext context, ThemePreference current, ThemePreference value, IconData icon, String text) {
    final theme = Theme.of(context);
    final isSelected = current == value;
    return PopupMenuItem<ThemePreference>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? theme.colorScheme.primary : null)),
        ],
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: "Profile Options",
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 10),
      onSelected: (String value) {
        // Handle 'profile' or 'settings' actions here if needed
        if (value == 'profile') {
          // Navigate to profile screen, etc.
        } else if (value == 'settings') {
          // Navigate to settings screen, etc.
        }
      },
      // THE FIX IS HERE: Removed the divider and the logout item
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(leading: Icon(LucideIcons.user), title: Text("My Profile")),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(leading: Icon(LucideIcons.settings), title: Text("Settings")),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/profile.png')),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Osama Adel', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text('Administrator', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 18, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}