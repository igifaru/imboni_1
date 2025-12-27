import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/services/case_service.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/models/models.dart';

/// Assigned Cases Screen - Professional design matching Figma
class AssignedCasesScreen extends StatefulWidget {
  const AssignedCasesScreen({super.key});

  @override
  State<AssignedCasesScreen> createState() => _AssignedCasesScreenState();
}

class _AssignedCasesScreenState extends State<AssignedCasesScreen> {
  List<CaseModel> _cases = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      final response = await caseService.getAssignedCases(limit: 50);
      if (mounted) {
        setState(() {
          _cases = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CaseModel> get _filteredCases {
    switch (_selectedFilter) {
      case 'open': return _cases.where((c) => c.status == 'OPEN').toList();
      case 'in_progress': return _cases.where((c) => c.status == 'IN_PROGRESS').toList();
      case 'escalated': return _cases.where((c) => c.status == 'ESCALATED').toList();
      default: return _cases;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : ImboniColors.primaryDark,
        foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.white,
        elevation: 0,
        title: const Text('Assigned Cases'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        _buildFilterChips(theme, isDark),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCases,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCases.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredCases.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (context, index) => _buildCaseItem(_filteredCases[index], theme, isDark),
                      ),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    final filters = [
      ('all', 'All'),
      ('open', 'Open'),
      ('in_progress', 'In Progress'),
      ('escalated', 'Escalated'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? theme.scaffoldBackgroundColor : ImboniColors.primaryDark,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ...filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(f.$2),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f.$1),
              backgroundColor: isDark ? theme.cardColor : Colors.transparent,
              selectedColor: isDark ? ImboniColors.primary.withAlpha(50) : Colors.white,
              labelStyle: TextStyle(
                color: isSelected 
                    ? (isDark ? ImboniColors.primary : ImboniColors.primaryDark)
                    : (isDark ? theme.colorScheme.onSurface : Colors.white70),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(color: isSelected ? (isDark ? ImboniColors.primary : Colors.white) : Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildCaseItem(CaseModel c, ThemeData theme, bool isDark) {
    final categoryColor = ImboniColors.getCategoryColor(c.category);
    final statusColor = ImboniColors.getStatusColor(c.status);
    final urgencyColor = ImboniColors.getUrgencyColor(c.urgency);
    final timeAgo = _formatTimeAgo(c.createdAt);

    return Container(
      color: c.urgency == 'HIGH' || c.urgency == 'EMERGENCY' 
          ? urgencyColor.withAlpha(isDark ? 20 : 10) 
          : null,
      child: InkWell(
        onTap: () => _openCaseDetails(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                _buildChip(c.category, categoryColor, isDark),
                if (c.urgency != 'NORMAL') ...[
                  const SizedBox(width: 8),
                  _buildChip(c.urgency, urgencyColor, isDark),
                ],
              ]),
              Text(timeAgo, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.caseReference, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(c.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(c.currentLevel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  c.status.replaceAll('_', ' '),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
        const SizedBox(height: 16),
        Text('Nta kibazo kigupfundikiye', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Ibibazo bizagaragara hano', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _openCaseDetails(CaseModel c) {
    // Navigate to case details for resolution
  }
}
