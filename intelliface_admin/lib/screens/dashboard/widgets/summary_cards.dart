// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/dashboard/widgets/summary_cards.dart
// Purpose: A professional set of summary cards with a guaranteed count-up
//          animation using TweenAnimationBuilder and shimmer loading.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/dashboard_service.dart';

class SummaryCards extends StatefulWidget {
  const SummaryCards({super.key});
  @override
  State<SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends State<SummaryCards> {
  int _totalEmployees = 0;
  int _totalPresentToday = 0;
  int _totalAbsentToday = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final dashboardData = await DashboardService.fetchDashboardStats();
      if (!mounted) return;
      final summary = dashboardData['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        _totalEmployees = summary['totalEmployees'] as int? ?? 0;
        _totalPresentToday = summary['totalPresentToday'] as int? ?? 0;
        _totalAbsentToday = summary['totalAbsentToday'] as int? ?? 0;
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Could not load stats");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cards = [
      SummaryCard(
        title: "Total Present Today", value: _totalPresentToday,
        icon: LucideIcons.userCheck, isLoading: _isLoading, error: _error,
        iconColor: Colors.green.shade400,
      ),
      SummaryCard(
        title: "Total Employees", value: _totalEmployees,
        icon: LucideIcons.users, isLoading: _isLoading, error: _error,
        iconColor: theme.colorScheme.primary,
      ),
      SummaryCard(
        title: "Total Absent Today", value: _totalAbsentToday,
        icon: LucideIcons.userX, isLoading: _isLoading, error: _error,
        iconColor: Colors.orange.shade400,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      return constraints.maxWidth < 750
          ? Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
      )
          : Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
          const SizedBox(width: 16),
          Expanded(child: cards[2]),
        ],
      );
    });
  }
}

class SummaryCard extends StatefulWidget {
  final String title;
  final int value;
  final IconData icon;
  final bool isLoading;
  final String? error;
  final Color iconColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.isLoading,
    this.error,
    required this.iconColor,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: _isHovered ? 4 : (theme.brightness == Brightness.light ? 2 : 1),
          shadowColor: _isHovered ? widget.iconColor.withOpacity(0.3) : null,
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(20),
            child: widget.isLoading ? _buildLoadingState(theme) : _buildContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.colorScheme.onSurface.withOpacity(0.1),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundColor: Colors.white.withOpacity(0.2)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 28, width: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 16, width: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    Widget valueWidget;

    if (widget.error != null) {
      valueWidget = Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error, size: 32);
    } else {
      // THE FIX IS HERE: Using TweenAnimationBuilder for a reliable count-up.
      valueWidget = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.value.toDouble()),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Text(
            value.toInt().toString(), // Display the animated value
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          );
        },
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: widget.iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(widget.icon, size: 28, color: widget.iconColor),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              valueWidget,
              const SizedBox(height: 4),
              Text(
                widget.error ?? widget.title,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}