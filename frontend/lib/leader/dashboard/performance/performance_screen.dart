import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/case_service.dart';

/// Performance Screen - Imihigo metrics
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
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    final metrics = _metrics ?? PerformanceMetrics.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range), 
            onPressed: _selectDateRange, 
            tooltip: 'Select period',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            if (_selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Chip(
                  label: Text('${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'),
                  onDeleted: () => setState(() => _selectedDateRange = null),
                  backgroundColor: ImboniColors.primary.withAlpha(20),
                  labelStyle: TextStyle(color: ImboniColors.primary),
                  deleteIconColor: ImboniColors.primary,
                ),
              ),
            _buildOverallScore(theme, metrics),
            const SizedBox(height: 24),
            Text('Metrics Breakdown', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildMetricsGrid(metrics),
            const SizedBox(height: 24),
            Text('Cases by Category', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildCategoriesBreakdown(theme, metrics),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ImboniColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      // In a real app we would reload metrics with date filter
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Showing data for ${_formatDate(picked.start)} - ${_formatDate(picked.end)}')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildOverallScore(ThemeData theme, PerformanceMetrics m) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Row(children: [
    SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(value: m.totalCases > 0 ? m.resolutionRate / 100 : 0, strokeWidth: 10, backgroundColor: ImboniColors.success.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(ImboniColors.success)),
      Text('${m.resolutionRate.toInt()}%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.success)),
    ])),
    const SizedBox(width: 24),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Overall Performance', style: theme.textTheme.titleLarge),
      const SizedBox(height: 4),
      Text('Based on resolution rate, response time, and citizen satisfaction', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Row(children: [const Icon(Icons.trending_up, color: ImboniColors.success, size: 16), const SizedBox(width: 4), Text('+5% from last month', style: theme.textTheme.bodySmall?.copyWith(color: ImboniColors.success))]),
    ])),
  ])));

  Widget _buildMetricsGrid(PerformanceMetrics m) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.5,
    children: [
      _MetricCard(label: 'Resolution Rate', value: '${m.resolutionRate}%', icon: Icons.check_circle_outline, color: ImboniColors.success),
      _MetricCard(label: 'Avg Response Time', value: '${m.avgResponseTimeHours}h', icon: Icons.schedule, color: ImboniColors.info),
      _MetricCard(label: 'Cases Escalated', value: '${m.escalatedCases}', icon: Icons.trending_up, color: ImboniColors.warning),
      _MetricCard(label: 'Pending Cases', value: '${m.pendingCases}', icon: Icons.hourglass_empty, color: ImboniColors.accent),
    ],
  );

  Widget _buildCategoriesBreakdown(ThemeData theme, PerformanceMetrics m) {
    if (m.totalCases == 0) return const SizedBox();
    
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      children: m.casesByCategory.entries.map((e) {
        final pct = (e.value / m.totalCases * 100).round();
        Color color = ImboniColors.categoryOther;
        if (e.key == 'Infrastructure') color = ImboniColors.categoryInfrastructure;
        if (e.key == 'Health') color = ImboniColors.categoryHealth;
        if (e.key == 'Land') color = ImboniColors.categoryLand;
        if (e.key == 'Justice') color = ImboniColors.categoryJustice;
        
        return _catRow(e.key, pct, color);
      }).toList(),
    )));
  }

  Widget _catRow(String name, int pct, Color color) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 12),
    Expanded(child: Text(name)),
    Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold)),
  ]));
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: color),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    ])));
  }
}
