/// Transparency Dashboard Screen
import 'package:flutter/material.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';
import 'project_list_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class TransparencyDashboardScreen extends StatefulWidget {
  const TransparencyDashboardScreen({super.key});

  @override
  State<TransparencyDashboardScreen> createState() => _TransparencyDashboardScreenState();
}

class _TransparencyDashboardScreenState extends State<TransparencyDashboardScreen> {
  PftcvStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await pftcvService.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBudget(double amount) => 'RWF ${(amount / 1000000000).toStringAsFixed(1)}B';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubworoherane bw\'Imari'),
        actions: [
          IconButton(icon: const Icon(Icons.list), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreen()))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Amakuru ntayabonetse'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Cards
                            isWide
                                ? Row(children: [
                                    Expanded(child: _StatCard(title: 'Imishinga', value: '${_stats!.totalProjects}', icon: Icons.folder, color: colorScheme.primary)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _StatCard(title: 'Imari Yemewe', value: _formatBudget(_stats!.totalBudget), icon: Icons.account_balance, color: Colors.blue)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _StatCard(title: 'Yatanzwe', value: _formatBudget(_stats!.totalReleased), icon: Icons.payments, color: Colors.green)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _StatCard(title: 'Igenzura', value: '${_stats!.totalVerifications}', icon: Icons.verified_user, color: Colors.orange)),
                                  ])
                                : Column(children: [
                                    Row(children: [
                                      Expanded(child: _StatCard(title: 'Imishinga', value: '${_stats!.totalProjects}', icon: Icons.folder, color: colorScheme.primary)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _StatCard(title: 'Igenzura', value: '${_stats!.totalVerifications}', icon: Icons.verified_user, color: Colors.orange)),
                                    ]),
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Expanded(child: _StatCard(title: 'Imari Yemewe', value: _formatBudget(_stats!.totalBudget), icon: Icons.account_balance, color: Colors.blue)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _StatCard(title: 'Yatanzwe', value: _formatBudget(_stats!.totalReleased), icon: Icons.payments, color: Colors.green)),
                                    ]),
                                  ]),
                            const SizedBox(height: 24),

                            // Charts Row
                            isWide
                                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(child: _buildStatusChart(theme)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildRiskChart(theme)),
                                  ])
                                : Column(children: [
                                    _buildStatusChart(theme),
                                    const SizedBox(height: 16),
                                    _buildRiskChart(theme),
                                  ]),
                            const SizedBox(height: 24),

                            // View All Button
                            Center(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreen())),
                                icon: const Icon(Icons.list),
                                label: const Text('Reba Imishinga Yose'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildStatusChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imiterere y\'Imishinga', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _stats!.byStatus.isEmpty
                  ? const Center(child: Text('Nta makuru'))
                  : PieChart(
                      PieChartData(
                        sections: _stats!.byStatus.map((s) {
                          return PieChartSectionData(
                            value: s.count.toDouble(),
                            title: '${s.count}',
                            color: s.status.color,
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _stats!.byStatus.map((s) => _Legend(color: s.status.color, label: '${s.status.label}: ${s.count}')).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imiterere y\'Ubwirinzi', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _stats!.byRisk.isEmpty
                  ? const Center(child: Text('Nta makuru'))
                  : PieChart(
                      PieChartData(
                        sections: _stats!.byRisk.map((r) {
                          return PieChartSectionData(
                            value: r.count.toDouble(),
                            title: '${r.count}',
                            color: r.riskLevel.color,
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _stats!.byRisk.map((r) => _Legend(color: r.riskLevel.color, label: '${r.riskLevel.label}: ${r.count}')).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title, style: theme.textTheme.bodyMedium)]),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
