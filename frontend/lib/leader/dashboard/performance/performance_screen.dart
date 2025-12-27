import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';

/// Performance Screen - Imihigo metrics
class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Performance'), actions: [IconButton(icon: const Icon(Icons.date_range), onPressed: () {}, tooltip: 'Select period')]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildOverallScore(theme),
        const SizedBox(height: 24),
        Text('Metrics Breakdown', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildMetricsGrid(),
        const SizedBox(height: 24),
        Text('Cases by Category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildCategoriesBreakdown(theme),
      ])),
    );
  }

  Widget _buildOverallScore(ThemeData theme) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Row(children: [
    SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(value: 0.85, strokeWidth: 10, backgroundColor: ImboniColors.success.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(ImboniColors.success)),
      Text('85%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.success)),
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

  Widget _buildMetricsGrid() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.5,
    children: const [
      _MetricCard(label: 'Resolution Rate', value: '92%', icon: Icons.check_circle_outline, color: ImboniColors.success),
      _MetricCard(label: 'Avg Response Time', value: '4.2h', icon: Icons.schedule, color: ImboniColors.info),
      _MetricCard(label: 'Cases Escalated', value: '3', icon: Icons.trending_up, color: ImboniColors.warning),
      _MetricCard(label: 'Citizen Feedback', value: '4.5/5', icon: Icons.star_outline, color: ImboniColors.accent),
    ],
  );

  Widget _buildCategoriesBreakdown(ThemeData theme) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    _catRow('Infrastructure', 35, ImboniColors.categoryInfrastructure),
    _catRow('Health', 25, ImboniColors.categoryHealth),
    _catRow('Land', 20, ImboniColors.categoryLand),
    _catRow('Justice', 10, ImboniColors.categoryJustice),
    _catRow('Other', 10, ImboniColors.categoryOther),
  ])));

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
