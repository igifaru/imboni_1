import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/case_card.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';

/// My Cases Screen - List of user's submitted cases
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CaseModel> _allCases = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCases();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadCases() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await caseService.getUserCases(limit: 50);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allCases = response.data ?? [];
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  List<CaseModel> get _openCases => _allCases.where((c) => c.status == 'OPEN').toList();
  List<CaseModel> get _inProgressCases => _allCases.where((c) => c.status == 'IN_PROGRESS' || c.status == 'ESCALATED').toList();
  List<CaseModel> get _resolvedCases => _allCases.where((c) => c.status == 'RESOLVED' || c.status == 'CLOSED').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ibibazo byanjye'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            _buildTab('Byose', _allCases.length, null),
            _buildTab('Bifunguwe', _openCases.length, ImboniColors.statusOpen),
            _buildTab('Bikorwaho', _inProgressCases.length, ImboniColors.statusInProgress),
            _buildTab('Byakemutse', _resolvedCases.length, ImboniColors.statusResolved),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(theme)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCasesList(_allCases, theme),
                      _buildCasesList(_openCases, theme),
                      _buildCasesList(_inProgressCases, theme),
                      _buildCasesList(_resolvedCases, theme),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTab(String label, int count, Color? color) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: (color ?? ImboniColors.primary).withAlpha(50), borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? ImboniColors.primary)),
        ),
      ]),
    );
  }

  Widget _buildCasesList(List<CaseModel> cases, ThemeData theme) {
    if (cases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.folder_open_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
            const SizedBox(height: 16),
            Text('Nta kibazo kiraboneka', style: theme.textTheme.titleMedium),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        return CaseCard(
          caseReference: c.caseReference,
          title: c.title,
          category: c.category,
          status: c.status,
          urgency: c.urgency,
          currentLevel: c.currentLevel,
          createdAt: c.createdAt,
          onTap: () => _openCaseDetails(c),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 64, color: ImboniColors.error),
          const SizedBox(height: 16),
          Text('Habaye ikosa', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error ?? '', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: _loadCases, icon: const Icon(Icons.refresh), label: const Text('Gerageza nanone')),
        ]),
      ),
    );
  }

  void _openCaseDetails(CaseModel caseModel) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailsScreen(caseModel: caseModel)));
  }
}

/// Case Details Screen
class CaseDetailsScreen extends StatelessWidget {
  final CaseModel caseModel;

  const CaseDetailsScreen({super.key, required this.caseModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = ImboniColors.getStatusColor(caseModel.status);
    final categoryColor = ImboniColors.getCategoryColor(caseModel.category);

    return Scaffold(
      appBar: AppBar(title: Text(caseModel.caseReference)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor.withAlpha(25), statusColor.withAlpha(75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withAlpha(100)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(caseModel.status.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: categoryColor.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_getCategoryIcon(caseModel.category), size: 16, color: categoryColor),
                    const SizedBox(width: 6),
                    Text(caseModel.category, style: TextStyle(color: categoryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Text(caseModel.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 24),

          // Info cards
          _buildInfoCard(theme, 'Urwego ruri kugikoraho', caseModel.currentLevel, Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildInfoCard(theme, 'Ubukana', caseModel.urgency, Icons.priority_high, color: ImboniColors.getUrgencyColor(caseModel.urgency)),
          const SizedBox(height: 12),
          _buildInfoCard(theme, 'Itariki yatanzweho', _formatDate(caseModel.createdAt), Icons.calendar_today_outlined),
          const SizedBox(height: 24),

          // Description
          Text('Ibisobanuro', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Text(caseModel.description, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 32),

          // Timeline placeholder - would show real case actions
          Text('Aho kigeze', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTimeline(theme),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withAlpha(128), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outline.withAlpha(50))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (color ?? ImboniColors.primary).withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color ?? ImboniColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final events = [
      ('Cyatanzwe', caseModel.createdAt, ImboniColors.primary, Icons.add_circle),
      if (caseModel.status != 'OPEN') ('Cyatangiye gukorwaho', caseModel.createdAt.add(const Duration(hours: 2)), ImboniColors.statusInProgress, Icons.pending),
    ];

    return Column(
      children: events.map((e) => _TimelineItem(title: e.$1, date: e.$2, color: e.$3, icon: e.$4, isFirst: events.indexOf(e) == 0, isLast: events.indexOf(e) == events.length - 1)).toList(),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return Icons.gavel;
      case 'HEALTH': return Icons.local_hospital;
      case 'LAND': return Icons.landscape;
      case 'INFRASTRUCTURE': return Icons.construction;
      case 'SECURITY': return Icons.security;
      case 'SOCIAL': return Icons.people;
      case 'EDUCATION': return Icons.school;
      default: return Icons.help_outline;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final DateTime date;
  final Color color;
  final IconData icon;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({required this.title, required this.date, required this.color, required this.icon, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle, border: Border.all(color: color, width: 2)), child: Icon(icon, color: color, size: 18)),
          if (!isLast) Expanded(child: Container(width: 2, color: color.withAlpha(75))),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ]),
    );
  }
}
