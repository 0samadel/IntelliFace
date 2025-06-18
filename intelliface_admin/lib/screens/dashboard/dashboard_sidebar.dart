// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/dashboard_sidebar.dart
// Purpose: A professional sidebar with a text header and a branded footer logo.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class DashboardSidebar extends StatefulWidget {
  final String selected;
  final Function(String) onSelect;

  const DashboardSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> sections = [
      {'label': 'ANALYTICS', 'items': ['Dashboard', 'Attendance']},
      {'label': 'MANAGEMENT', 'items': ['Employee', 'Department', 'Location']},
      {'label': 'ACCOUNT', 'items': ['Logout']},
    ];

    final Map<String, IconData> icons = {
      'Dashboard': LucideIcons.layoutDashboard, 'Attendance': LucideIcons.calendarCheck,
      'Employee': LucideIcons.users, 'Department': LucideIcons.building,
      'Location': LucideIcons.map, 'Logout': LucideIcons.logOut,
    };

    return Material(
      color: theme.colorScheme.surface,
      elevation: isDarkMode ? 0 : 2.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 270,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // THE FIX IS HERE: Header with only text.
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 15, 28, 25),
                child: Text(
                  "IntelliFace",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              // THE FIX IS HERE: The ListView is now the direct child of the Column
              // It will take its natural height, and Spacer will push the footer.
              ..._buildMenuItems(sections, icons),

              const Spacer(), // Pushes the logo to the bottom

              // THE FIX IS HERE: Footer with the conditional logo.
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      isDarkMode ? 'assets/logo_face_dark.png' : 'assets/logo_face_light.png',
                      height: 90,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build the menu items without a ListView wrapper
  List<Widget> _buildMenuItems(List<Map<String, dynamic>> sections, Map<String, IconData> icons) {
    final theme = Theme.of(context);
    List<Widget> menuWidgets = [];
    for (var section in sections) {
      menuWidgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 16, bottom: 10),
          child: Text(
            section['label'],
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
      for (var item in section['items'] as List<String>) {
        menuWidgets.add(
          _SidebarItem(
            icon: icons[item]!,
            title: item,
            selected: widget.selected == item,
            onTap: () => widget.onSelect(item),
          ),
        );
      }
    }
    return menuWidgets;
  }
}

class _SidebarItem extends StatelessWidget {
  // ... (This widget remains exactly the same, no changes needed)
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon, required this.title, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLogout = title == 'Logout';

    Color itemColor;
    Color? backgroundColor;

    if (isLogout) {
      itemColor = theme.colorScheme.error;
      backgroundColor = Colors.transparent;
    } else if (selected) {
      itemColor = theme.colorScheme.primary;
      backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
    } else {
      itemColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
      backgroundColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => isLogout ? _showLogoutDialog(context) : onTap(),
          borderRadius: BorderRadius.circular(8),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          hoverColor: selected ? null : theme.colorScheme.onSurface.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: selected ? 24 : 0,
                  width: 4,
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: selected ? 12 : 16),
                Icon(icon, color: itemColor, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: itemColor,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Confirm Logout", style: theme.textTheme.titleLarge),
        content: Text("Are you sure you want to log out?", style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}