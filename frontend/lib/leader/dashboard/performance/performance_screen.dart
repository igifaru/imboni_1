import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add fl_chart dependency
import '../../../shared/theme/colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/case_service.dart';

/// Performance Screen - Professional Analytics Dashboard
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  DateTimeRange? _selectedDateRange;
  PerformanceMetrics? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final response = await caseService.getPerformanceMetrics();
      if (mounted) {
        setState(() {
          _metrics = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = _metrics ?? PerformanceMetrics.empty();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Performance Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {},
            tooltip: 'Export Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedDateRange != null)
              _buildDateFilterChip(theme),

            // Top Key Metrics Row
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isWide ? (width - 16) / 2 : width,
                    child: _buildMetricCard(
                      theme, 
                      'Resolution Rate', 
                      '${metrics.resolutionRate.toInt()}%', 
                      metrics.resolutionRate >= 80 ? Icons.trending_up : Icons.trending_down,
                      metrics.resolutionRate >= 80 ? ImboniColors.success : ImboniColors.warning,
                      isDark
                    )
                  ),
                  SizedBox(
                    width: isWide ? (width - 16) / 2 : width,
                    child: _buildMetricCard(
                      theme, 
                      'Avg Response Time', 
                      '${metrics.avgResponseTimeHours}h', 
                      Icons.timer_outlined,
                      ImboniColors.info,
                      isDark
                    )
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // Charts Section
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width > 900;
              
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie Chart: Cases by Category
                  SizedBox(
                    width: isWide ? (width * 0.4) : width,
                    child: _buildCategoryChart(theme, metrics, isDark),
                  ),
                  if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                  
                  // Bar Chart: Weekly Comparison (Mocked for visual)
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: SizedBox(
                      width: isWide ? null : width,
                      child: _buildTrendsChart(theme, metrics, isDark),
                    ),
                  ),
                ],
              );
            }),
            
             const SizedBox(height: 24),
             _buildDetailedStatsTable(theme, metrics, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(ThemeData theme) {
    return Padding(
       padding: const EdgeInsets.only(bottom: 16),
       child: FilterChip(
         label: Text(
           '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
           style: TextStyle(color: theme.colorScheme.primary),
         ),
         onSelected: (_) => setState(() => _selectedDateRange = null),
         selected: true,
         showCheckmark: false,
         avatar: Icon(Icons.close, size: 16, color: theme.colorScheme.primary),
         backgroundColor: theme.colorScheme.primaryContainer.withAlpha(50),
         selectedColor: theme.colorScheme.primaryContainer.withAlpha(50),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(20),
           side: BorderSide(color: theme.colorScheme.primary.withAlpha(50)),
         ),
       ),
    );
  }

  Widget _buildMetricCard(ThemeData theme, String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.dividerColor.withAlpha(isDark ? 20 : 50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface
                )
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCategoryChart(ThemeData theme, PerformanceMetrics m, bool isDark) {
    if (m.totalCases == 0) return const SizedBox();

    final categoryColors = {
      'Infrastructure': ImboniColors.categoryInfrastructure,
      'Health': ImboniColors.categoryHealth,
      'Land': ImboniColors.categoryLand,
      'Justice': ImboniColors.categoryJustice,
      'Security': ImboniColors.categorySecurity,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(isDark ? 20 : 50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cases by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: m.casesByCategory.entries.map((e) {
                  final color = categoryColors[e.key] ?? ImboniColors.categoryOther;
                  final value = e.value.toDouble();
                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: '${(value / m.totalCases * 100).round()}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: m.casesByCategory.entries.map((e) {
              final color = categoryColors[e.key] ?? ImboniColors.categoryOther;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.key, style: theme.textTheme.bodySmall),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildTrendsChart(ThemeData theme, PerformanceMetrics m, bool isDark) {
    if (m.weeklyTrends.isEmpty) {
        return const Center(child: Text("No trend data available"));
    }

    // Calculate trend percentage (vs previous period would require more data, but we can just show total new cases for week)
    final totalNewLastWeek = m.weeklyTrends.fold(0, (sum, item) => sum + item.newCases);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(isDark ? 20 : 50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity Trends (Last 7 Days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Text('$totalNewLastWeek New Cases', style: const TextStyle(color: ImboniColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                    if (v.toInt() >= 0 && v.toInt() < m.weeklyTrends.length) {
                        return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(m.weeklyTrends[v.toInt()].day, style: const TextStyle(fontSize: 10)),
                        );
                    }
                    return const Text('');
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: m.weeklyTrends.asMap().entries.map((entry) {
                    return _makeBarGroup(entry.key, entry.value.newCases.toDouble(), entry.value.resolvedCases.toDouble(), isDark);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               _buildLegendItem('New', isDark ? Colors.white30 : Colors.grey.shade300),
               const SizedBox(width: 16),
               _buildLegendItem('Resolved', ImboniColors.primary),
             ],
           )
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double total, double resolved, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          color: isDark ? Colors.white30 : Colors.grey.shade300,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
             BarChartRodStackItem(0, resolved, ImboniColors.primary),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailedStatsTable(ThemeData theme, PerformanceMetrics m, bool isDark) {
     return Container(
       decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(isDark ? 20 : 50)),
       ),
       child: Column(
         children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                 Text('Detailed Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(height: 1),
            _buildStatRow(theme, 'Total Cases', '${m.totalCases}'),
            _buildStatRow(theme, 'Resolved Cases', '${(m.totalCases * m.resolutionRate / 100).round()}'),
            _buildStatRow(theme, 'Pending', '${m.pendingCases}'),
            _buildStatRow(theme, 'Escalated', '${m.escalatedCases}'),
         ],
       ),
     );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
