/// Project Detail Screen with Verification
import 'package:flutter/material.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';
import 'verification_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final bool embedded;
  final VoidCallback? onBack;
  const ProjectDetailScreen({super.key, required this.projectId, this.embedded = false, this.onBack});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    try {
      final project = await pftcvService.getProjectById(widget.projectId);
      if (mounted) setState(() => _project = project);
    } catch (e) {
      debugPrint('Error loading project: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerificationScreen(project: _project!)),
    );
    if (result == true) _loadProject();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return widget.embedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    if (_project == null) {
      return widget.embedded
          ? const Center(child: Text('Umushinga ntabwo ubonetse'))
          : Scaffold(appBar: AppBar(), body: const Center(child: Text('Umushinga ntabwo ubonetse')));
    }

    final p = _project!;

    Widget body = CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          leading: widget.embedded && widget.onBack != null
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
              : null,
          automaticallyImplyLeading: !widget.embedded,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(p.name, style: const TextStyle(fontSize: 16)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colorScheme.primary, colorScheme.primaryContainer]),
              ),
              child: Stack(children: [
                Positioned(right: 16, top: 60, child: Icon(p.sector.icon, size: 120, color: Colors.white.withAlpha(40))),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Risk & Status Row
              Row(
                children: [
                  _InfoChip(label: p.status.label, color: p.status.color, icon: Icons.info),
                  const SizedBox(width: 12),
                  _InfoChip(label: p.riskLevel.label, color: p.riskLevel.color, icon: Icons.warning),
                  const Spacer(),
                  Text(p.projectCode, style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
                ],
              ),
              const SizedBox(height: 24),

              // Budget Card
              _DetailCard(
                title: 'Imari',
                icon: Icons.account_balance_wallet,
                child: Column(
                  children: [
                    _BudgetRow(label: 'Yemewe', value: p.budgetFormatted),
                    const SizedBox(height: 8),
                    _BudgetRow(label: 'Yatanzwe', value: p.releasedFormatted),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: p.releaseRatio.clamp(0.0, 1.0), minHeight: 8, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight, child: Text('${(p.releaseRatio * 100).toStringAsFixed(1)}%')),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location Card
              _DetailCard(
                title: 'Ahantu',
                icon: Icons.location_on,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.locationName != null) Text(p.locationName!, style: theme.textTheme.bodyLarge),
                    if (p.gpsLatitude != null && p.gpsLongitude != null)
                      Text('GPS: ${p.gpsLatitude!.toStringAsFixed(4)}, ${p.gpsLongitude!.toStringAsFixed(4)}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details Card
              _DetailCard(
                title: 'Amakuru',
                icon: Icons.info_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.description != null) ...[
                      Text('Ibisobanuro:', style: theme.textTheme.labelMedium),
                      Text(p.description!),
                      const SizedBox(height: 12),
                    ],
                    if (p.implementingAgency != null) _InfoRow(label: 'Ishami', value: p.implementingAgency!),
                    if (p.fundingSource != null) _InfoRow(label: "Inkomoko y'Imari", value: p.fundingSource!),
                    if (p.expectedOutputs != null) _InfoRow(label: 'Ibizakorwa', value: p.expectedOutputs!),
                    if (p.startDate != null) _InfoRow(label: 'Itariki Itangira', value: _formatDate(p.startDate!)),
                    if (p.endDate != null) _InfoRow(label: 'Itariki Irangira', value: _formatDate(p.endDate!)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Verification Stats Card
              _DetailCard(
                title: "Igenzura ry'Abaturage",
                icon: Icons.verified_user,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatTile(value: '${p.verificationCount}', label: 'Bagenzuye'),
                    _StatTile(value: '${p.verifiedPercentage}%', label: 'Igenzura'),
                    _StatTile(value: '${p.riskScore}', label: 'Imiterere'),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _openVerification,
              icon: const Icon(Icons.verified),
              label: const Text('Genzura'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVerification,
        icon: const Icon(Icons.verified),
        label: const Text('Genzura Umushinga'),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _DetailCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title, style: theme.textTheme.titleMedium)]),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _InfoChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500))]),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final String value;
  const _BudgetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text('$label:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline))),
        Expanded(child: Text(value)),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
