// ────────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/dashboard/widgets/line_chart_card.dart
// Purpose: A professional, interactive, and theme-aware line chart.
// ────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/dashboard_service.dart';

class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});
  @override
  State<LineChartCard> createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  List<FlSpot> _attendanceSpots = [];
  List<String> _dateLabels = [];
  double _maxY = 10; // Default max Y value to prevent chart from looking empty
  bool _isLoading = true;
  String _selectedTrendPeriod = 'Last 7 Days';
  final Map<String, int> _periodDays = {'Last 7 Days': 7, 'Last 15 Days': 15, 'Last 30 Days': 30};

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final int daysToConsider = _periodDays[_selectedTrendPeriod] ?? 7;
      final dashboardData = await DashboardService.fetchDashboardStats(trendDays: daysToConsider);
      if (!mounted) return;

      final trendDataFromApi = dashboardData['attendanceTrend'] as List<dynamic>?;
      List<FlSpot> spots = [];
      List<String> labels = [];
      double tempMaxY = 10; // Start with a minimum height

      if (trendDataFromApi != null && trendDataFromApi.isNotEmpty) {
        for (var i = 0; i < trendDataFromApi.length; i++) {
          final dayData = trendDataFromApi[i] as Map<String, dynamic>;
          final dateStr = dayData['date'] as String? ?? '';
          final presentCount = dayData['presentCount'] as int? ?? 0;

          spots.add(FlSpot(i.toDouble(), presentCount.toDouble()));
          DateTime? parsedDate = DateTime.tryParse(dateStr);
          labels.add(parsedDate != null ? DateFormat('dd MMM').format(parsedDate) : '');

          if (presentCount > tempMaxY) {
            tempMaxY = presentCount.toDouble();
          }
        }
      }

      // Add a little padding to the top of the chart
      _maxY = tempMaxY * 1.2;

      if (mounted) setState(() { _attendanceSpots = spots; _dateLabels = labels; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chart data: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Pro Axis Title Builders ---
  Widget _bottomTitleWidgets(double value, TitleMeta meta, ThemeData theme) {
    final style = theme.textTheme.bodySmall;
    int index = value.toInt();

    // Smarter logic to prevent label crowding
    int interval = (_dateLabels.length / 7).ceil();
    if (index >= _dateLabels.length || index % interval != 0) {
      return SideTitleWidget(axisSide: meta.axisSide, child: const Text(''));
    }

    return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: Text(_dateLabels[index], style: style));
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, ThemeData theme) {
    if (value == 0 || value == meta.max) return Container(); // Hide min and max labels
    final style = theme.textTheme.bodySmall;
    return Text(value.toInt().toString(), style: style, textAlign: TextAlign.left);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Card(
      elevation: theme.brightness == Brightness.light ? 2 : 0,
      child: Container(
        height: 350,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Attendance Trends", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTrendPeriod,
                      icon: Icon(Icons.arrow_drop_down, color: theme.textTheme.bodySmall?.color),
                      style: theme.textTheme.bodyMedium,
                      dropdownColor: theme.colorScheme.surface,
                      items: _periodDays.keys.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() { _selectedTrendPeriod = newValue; _fetchChartData(); });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _attendanceSpots.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildChart(theme, accentColor),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pro Chart Widget ---
  Widget _buildChart(ThemeData theme, Color accentColor) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: _maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (_maxY / 5).floorToDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: theme.dividerColor.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _attendanceSpots,
            isCurved: true,
            gradient: LinearGradient(colors: [accentColor.withOpacity(0.8), accentColor]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false), // Dots are shown on touch
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.3), accentColor.withOpacity(0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (v, m) => _bottomTitleWidgets(v, m, theme))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => _leftTitleWidgets(v, m, theme))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),

        // Pro Interactive Tooltip
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: theme.colorScheme.surface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                if (flSpot.spotIndex >= _dateLabels.length) return null;

                return LineTooltipItem(
                  '${flSpot.y.toInt()} Present on\n',
                  theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: _dateLabels[flSpot.spotIndex],
                      style: theme.textTheme.bodyMedium!.copyWith(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(color: accentColor, strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(radius: 8, color: accentColor, strokeColor: theme.cardColor, strokeWidth: 4);
                  },
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // --- Pro Empty State Widget ---
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.barChart3, size: 48, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 16),
          Text("No data for this period.", style: theme.textTheme.titleMedium),
          Text("Try selecting a different date range.", style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}