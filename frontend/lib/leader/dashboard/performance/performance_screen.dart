import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/case_service.dart';
import '../../../shared/localization/app_localizations.dart';

/// Performance Screen - Professional Analytics Dashboard
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  DateTimeRange? _selectedDateRange;
  PerformanceMetrics? _metrics;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String _locationFilter = 'All Locations';
  String? _locationFilterId;
  String _categoryFilter = 'All Categories';

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = _metrics ?? PerformanceMetrics.empty();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.performanceAnalytics, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {},
            tooltip: l10n.exportReport,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ExcludeSemantics(
        child: RefreshIndicator(
          onRefresh: _loadMetrics,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
                Text(l10n.performanceSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                                // Filters Row (Refined)
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                     _buildFilterChip(
                         theme, 
                         'Time Range: ${_formatDateRange()}', 
                         Icons.calendar_today, 
                         true, 
                         null, 
                         onTapDown: (details) => _showDateFilterMenu(context, details)
                     ),
                     _buildFilterChip(
                         theme, 
                         'Location: $_locationFilter', 
                         Icons.place_outlined, 
                         _locationFilterId != null, 
                         null,
                         onTapDown: (details) => _showLocationFilterMenu(context, details)
                     ),
                     _buildFilterChip(
                         theme, 
                         'Category: $_categoryFilter', 
                         Icons.category_outlined, 
                         _categoryFilter != 'All Categories', 
                         null,
                         onTapDown: (details) => _showCategoryFilterMenu(context, details)
                     ),
                  ],
                  ),
                ),
                
                if (_isRefreshing) ...[
                   const SizedBox(height: 12),
                   const LinearProgressIndicator(minHeight: 2),
                ],

                const SizedBox(height: 24),

                // Top Key Metrics Grid
                _buildMetricsGrid(theme, width, metrics, isDark, l10n),

                const SizedBox(height: 24),

                // Charts Section
                _buildChartsSection(theme, width, isWide, metrics, isDark, l10n),
                
                const SizedBox(height: 24),
                _buildRegionalBreakdownTable(theme, metrics, isDark, l10n),
                
                const SizedBox(height: 40), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, IconData icon, bool isSelected, VoidCallback? onTap, {Function(TapDownDetails)? onTapDown}) {
      final isDark = theme.brightness == Brightness.dark;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onTapDown: onTapDown,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? ImboniColors.primary.withAlpha(isDark ? 50 : 20) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? ImboniColors.primary : theme.dividerColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  label, 
                  style: TextStyle(
                    color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  )
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildMetricsGrid(ThemeData theme, double width, PerformanceMetrics metrics, bool isDark, AppLocalizations l10n) {
    final formattedAvgTime = metrics.avgResponseTimeHours.toStringAsFixed(2);
    
    if (width < 600) {
        return Column(
            children: [
                _buildMetricCard(theme, l10n.resolutionRate, '${metrics.resolutionRate.toInt()}%', '${l10n.target}: 85%', Icons.check_circle_outline, ImboniColors.success, isDark),
                const SizedBox(height: 16),
                _buildMetricCard(theme, l10n.avgResponseTime, '${formattedAvgTime}h', '${l10n.target}: < 4h', Icons.timer_outlined, ImboniColors.info, isDark),
                const SizedBox(height: 16),
                _buildMetricCard(theme, l10n.escalationRate, '${metrics.escalationRate.toStringAsFixed(1)}%', l10n.failingResolution, Icons.arrow_upward_rounded, ImboniColors.warning, isDark),
                const SizedBox(height: 16),
                _buildMetricCard(theme, l10n.overdueCases, '${metrics.overdueCases}', l10n.exceededSla, Icons.notification_important_outlined, ImboniColors.error, isDark),
            ],
        );
    }

    return Row(
      children: [
        Expanded(child: _buildMetricCard(theme, l10n.resolutionRate, '${metrics.resolutionRate.toInt()}%', '${l10n.target}: 85%', Icons.check_circle_outline, ImboniColors.success, isDark)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(theme, l10n.avgResponseTime, '${formattedAvgTime}h', '${l10n.target}: < 4h', Icons.timer_outlined, ImboniColors.info, isDark)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(theme, l10n.escalationRate, '${metrics.escalationRate.toStringAsFixed(1)}%', l10n.failingResolution, Icons.arrow_upward_rounded, ImboniColors.warning, isDark)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(theme, l10n.overdueCases, '${metrics.overdueCases}', l10n.exceededSla, Icons.notification_important_outlined, ImboniColors.error, isDark)),
      ],
    );
  }

  Widget _buildChartsSection(ThemeData theme, double width, bool isWide, PerformanceMetrics metrics, bool isDark, AppLocalizations l10n) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildTrendsChart(theme, metrics, isDark, l10n),
          ),
          const SizedBox(width: 24),
          Expanded(
             flex: 1,
             child: _buildCategoryChart(theme, metrics, isDark, l10n),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: width,
            child: _buildTrendsChart(theme, metrics, isDark, l10n),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: width,
            child: _buildCategoryChart(theme, metrics, isDark, l10n),
          ),
        ],
      );
    }
  }

  Widget _buildCategoryChart(ThemeData theme, PerformanceMetrics m, bool isDark, AppLocalizations l10n) {
    if (m.totalCases == 0 || m.casesByCategory.isEmpty) {
        return _buildEmptyChart(theme, l10n.noDataAvailable, isDark);
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(l10n.casesByCategory, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
               Icon(Icons.pie_chart_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: ExcludeSemantics( // SAFE MODE: Prevent engine crash
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(enabled: false), // SAFE MODE: No touch
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
                duration: Duration.zero, // SAFE MODE: No animation
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
                  const SizedBox(width: 4),
                  Text('(${e.value})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildTrendsChart(ThemeData theme, PerformanceMetrics m, bool isDark, AppLocalizations l10n) {
    if (m.weeklyTrends.isEmpty || m.weeklyTrends.every((t) => t.newCases == 0 && t.resolvedCases == 0)) {
        return _buildEmptyChart(theme, l10n.noActivityLastWeek, isDark);
    }

    final trendData = m.weeklyTrends;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weeklyPerformance, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(l10n.newVsResolved, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(8)),
                child: Text('${m.totalCases} ${l10n.total}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: ExcludeSemantics( // SAFE MODE
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                  barTouchData: const BarTouchData(enabled: false), // SAFE MODE
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                      if (v.toInt() >= 0 && v.toInt() < trendData.length) {
                          return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(trendData[v.toInt()].day, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                          );
                      }
                      return const Text('');
                    })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: trendData.asMap().entries.map((entry) {
                      return _makeBarGroup(entry.key, entry.value.newCases.toDouble(), entry.value.resolvedCases.toDouble(), isDark);
                  }).toList(),
                ),
                duration: Duration.zero, // SAFE MODE
              ),
            ),
          ),
          const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               _buildLegendItem(l10n.newCases, isDark ? Colors.white30 : Colors.grey.shade400),
               const SizedBox(width: 16),
               _buildLegendItem(l10n.resolvedCases, ImboniColors.primary),
             ],
           )
        ],
      ),
    );
  }
  
  Widget _buildRegionalBreakdownTable(ThemeData theme, PerformanceMetrics m, bool isDark, AppLocalizations l10n) {
    return Container(
       decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(isDark ? 20 : 50)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.regionalBreakdown, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            // Header
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
                 children: [
                    Expanded(flex: 3, child: Text(l10n.region, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text(l10n.totalCases, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text(l10n.resRate, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text(l10n.avgTime, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text(l10n.status, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                 ],
               ),
            ),
            const Divider(height: 1),
            if (m.subUnitBreakdown.isEmpty)
                Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('No breakdown data available', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                )
            else
                Column(
                  children: List.generate(m.subUnitBreakdown.length, (index) {
                      final unit = m.subUnitBreakdown[index];
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                  children: [
                                      Expanded(flex: 3, child: Text(unit.unitName, style: theme.textTheme.bodyMedium)),
                                      Expanded(flex: 2, child: Text('${unit.totalCases}', style: theme.textTheme.bodyMedium)),
                                      Expanded(flex: 2, child: _buildProgressBar(theme, unit.resolutionRate)),
                                      Expanded(flex: 2, child: Text('${unit.avgResponseTimeHours.toStringAsFixed(2)}h', style: theme.textTheme.bodyMedium)),
                                      Expanded(flex: 2, child: _buildStatusBadge(theme, unit.status)),
                                  ],
                              ),
                          ),
                        ],
                      );
                  }),
                ),
         ],
       ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, double percent) {
      return Row(
          children: [
              Expanded(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: ExcludeSemantics(
                        child: LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: theme.dividerColor.withAlpha(50),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                percent >= 80 ? ImboniColors.success : (percent >= 50 ? ImboniColors.warning : ImboniColors.error)
                            ),
                            minHeight: 6,
                        ),
                      ),
                  )
              ),
              const SizedBox(width: 8),
              Text('${percent.toInt()}%', style: const TextStyle(fontSize: 10)),
          ],
      );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
      Color color;
      switch (status) {
          case 'On Track': color = ImboniColors.success; break;
          case 'At Risk': color = ImboniColors.warning; break;
          default: color = ImboniColors.error; break;
      }
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
          ),
          child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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

  Widget _buildMetricCard(ThemeData theme, String title, String value, String subtext, IconData icon, Color color, bool isDark) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Expanded(child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                 child: Icon(icon, color: color, size: 20),
               )
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(subtext, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(ThemeData theme, String message, bool isDark) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Icon(Icons.bar_chart, size: 48, color: theme.disabledColor.withAlpha(50)),
                  const SizedBox(height: 16),
                  Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
          ),
      );
  }

  BarChartGroupData _makeBarGroup(int x, double total, double resolved, bool isDark) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: total,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
          width: 8,
          borderRadius: BorderRadius.circular(2),
        ),
        BarChartRodData(
          toY: resolved,
          color: ImboniColors.primary,
          width: 8,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Future<void> _loadMetrics() async {
    if (_metrics == null) {
      setState(() => _isInitialLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final response = await caseService.getPerformanceMetrics(
        dateRange: _selectedDateRange,
        category: _categoryFilter,
        locationId: _locationFilterId
      );
      
      if (mounted) {
        final theme = Theme.of(context);
        if (response.isSuccess) {
          setState(() {
            _metrics = response.data;
            _isInitialLoading = false;
            _isRefreshing = false;
          });
        } else {
          setState(() {
             // _isInitialLoading = false; // Moved to finally
             // _isRefreshing = false; // Moved to finally
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to load metrics'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: theme.colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _showLocationFilterMenu(BuildContext context, TapDownDetails details) async {
      final position = RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy + 30,
        details.globalPosition.dx + 200,
        details.globalPosition.dy + 400,
      );

      final breakdown = _metrics?.subUnitBreakdown ?? [];
      
      final result = await showMenu<Map<String, String?>>(
        context: context,
        position: position,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        items: [
           const PopupMenuItem(value: {'id': null, 'name': 'All Locations'},  child: Text('All Locations')),
           ...breakdown.map((u) => PopupMenuItem(
             value: {'id': u.unitId, 'name': u.unitName}, 
             child: Text(u.unitName)
           )),
        ]
      );

      if (result == null) return;

      setState(() {
        _locationFilter = result['name']!;
        _locationFilterId = result['id'];
        _loadMetrics();
      });
  }

  Future<void> _showCategoryFilterMenu(BuildContext context, TapDownDetails details) async {
      final position = RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy + 30,
        details.globalPosition.dx + 200,
        details.globalPosition.dy + 400,
      );

      // Extract categories from metrics or use defaults if empty
      final keys = _metrics?.casesByCategory.keys.toList() ?? [];
      final categories = keys.isEmpty 
          ? ['General', 'Infrastructure', 'Security', 'Health', 'Education'] 
          : keys;
      
      final result = await showMenu<String>(
        context: context,
        position: position,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        items: [
           const PopupMenuItem(value: 'All Categories', child: Text('All Categories')),
           ...categories.map((c) => PopupMenuItem(value: c, child: Text(c))),
        ]
      );

      if (result == null) return;

      setState(() {
        _categoryFilter = result;
        _loadMetrics();
      });
  }



  Future<void> _showDateFilterMenu(BuildContext context, TapDownDetails details) async {
      final position = RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy + 30, // Show slightly below
        details.globalPosition.dx + 200,
        details.globalPosition.dy + 300,
      );

      final result = await showMenu<String>(
        context: context,
        position: position,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        items: [
           const PopupMenuItem(value: '7', child: Text('Last 7 Days')),
           const PopupMenuItem(value: '30', child: Text('Last 30 Days')),
           const PopupMenuItem(value: '90', child: Text('Last 90 Days')),
           const PopupMenuItem(value: 'custom', child: Row(children: [Icon(Icons.calendar_today, size: 16), SizedBox(width: 8), Text('Custom Range')])),
        ]
      );

      if (result == null) return;

      if (result == 'custom') {
          _selectDateRange();
      } else {
          final days = int.parse(result);
          final now = DateTime.now();
          setState(() {
              _selectedDateRange = DateTimeRange(
                  start: now.subtract(Duration(days: days)),
                  end: now
              );
          });
          _loadMetrics();
      }
  }

  Future<void> _selectDateRange() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Figma-matched dark color vs Clean White for Light mode
    final dialogBg = isDark ? const Color(0xFF1E2128) : Colors.white;
    final onBg = isDark ? Colors.white : Colors.black;
    final calendarSurface = isDark ? const Color(0xFF1E2128) : Colors.white;
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Allow going back much further
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      saveText: 'Emeza',
      cancelText: 'Reka',
      helpText: 'Hitamo Itariki',
      barrierColor: Colors.black54,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
          return Center( 
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600), // Restore Dual-Month View
              child: Theme(
                data: theme.copyWith(
                  iconTheme: IconThemeData(color: onBg, size: 24), // Keep visible icons
                  platform: TargetPlatform.android, // Keep arrow navigation
                  colorScheme: theme.colorScheme.copyWith(
                    primary: ImboniColors.primary,
                    onPrimary: Colors.white,
                    surface: calendarSurface,
                    onSurface: onBg,
                    secondary: ImboniColors.primary,
                  ),
                  scaffoldBackgroundColor: dialogBg,
                  dialogTheme: DialogThemeData(
                    backgroundColor: dialogBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: dialogBg,
                    headerBackgroundColor: dialogBg,
                    headerForegroundColor: onBg,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    rangeSelectionBackgroundColor: ImboniColors.primary.withValues(alpha: 0.2), // Standard replacement for withOpacity
                    rangePickerBackgroundColor: dialogBg,
                    rangePickerHeaderBackgroundColor: dialogBg,
                    rangePickerHeaderForegroundColor: onBg,
                    rangePickerSurfaceTintColor: Colors.transparent,
                    dayStyle: TextStyle(color: onBg),
                    weekdayStyle: TextStyle(color: onBg.withValues(alpha: 0.7)),
                    yearStyle: TextStyle(color: onBg),
                    dayOverlayColor:  WidgetStateProperty.all(ImboniColors.primary.withValues(alpha: 0.1)),
                    headerHeadlineStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onBg),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: onBg, 
                    )
                  ),
                ),
                child: child!,
              ),
            ),
          );
      }
    );
    if (picked != null) {
      setState(() { 
          _selectedDateRange = picked;
      });
      _loadMetrics();
    }
  }

  String _formatDateRange() {
      if (_selectedDateRange == null) return 'Last 30 Days';
      return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}';
  }
}
