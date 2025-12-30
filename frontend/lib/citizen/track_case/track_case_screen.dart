import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../my_cases/my_cases_screen.dart';

/// Track Case Screen - Search and view case by reference
class TrackCaseScreen extends StatefulWidget {
  const TrackCaseScreen({super.key});

  @override
  State<TrackCaseScreen> createState() => _TrackCaseScreenState();
}

class _TrackCaseScreenState extends State<TrackCaseScreen> {
  final _referenceController = TextEditingController();
  bool _isLoading = false;
  CaseModel? _foundCase;
  String? _error;

  @override
  void dispose() { _referenceController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: l10n.search,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.trackCase)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [ImboniColors.secondary.withAlpha(50), ImboniColors.secondary.withAlpha(100)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: ImboniColors.secondary.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.search, color: ImboniColors.secondary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.trackCaseTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(l10n.trackCaseHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ])),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        hintText: 'IMB-XXXXXX-XX',
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: _referenceController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _referenceController.clear(); setState(() { _foundCase = null; _error = null; }); })
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _searchCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _referenceController.text.isNotEmpty ? _searchCase : null,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
                    child: Text(l10n.search),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            if (_error != null) _buildErrorCard(theme),
            if (_foundCase != null) _buildCaseResult(theme),
          ]),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ImboniColors.error.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: ImboniColors.error.withAlpha(75))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: ImboniColors.error.withAlpha(50), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.error_outline, color: ImboniColors.error)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.caseNotFound, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.error)),
          const SizedBox(height: 4),
          Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }

  Widget _buildCaseResult(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final c = _foundCase!;
    final statusColor = ImboniColors.getStatusColor(c.status);
    final categoryColor = ImboniColors.getCategoryColor(c.category);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.caseFound, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      
      // Main case card
      Container(
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outline.withAlpha(75))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor.withAlpha(25), statusColor.withAlpha(50)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.caseReference, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_formatDate(c.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(c.status.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              
              // Category & Urgency chips
              Wrap(spacing: 8, runSpacing: 8, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: categoryColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_getCategoryIcon(c.category), size: 16, color: categoryColor),
                    const SizedBox(width: 6),
                    Text(c.category, style: TextStyle(color: categoryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
                if (c.urgency != 'NORMAL') Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: ImboniColors.getUrgencyColor(c.urgency).withAlpha(25), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.priority_high, size: 16, color: ImboniColors.getUrgencyColor(c.urgency)),
                    const SizedBox(width: 4),
                    Text(c.urgency, style: TextStyle(color: ImboniColors.getUrgencyColor(c.urgency), fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              
              // Current level
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.location_on_outlined, size: 18, color: ImboniColors.primary),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.currentLevel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(c.currentLevel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text('${l10n.description}:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(c.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              
              // View details button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CitizenCaseDetailsScreen(caseModel: c))),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.viewDetails),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

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

  Future<void> _searchCase() async {
    final ref = _referenceController.text.trim().toUpperCase();
    if (ref.isEmpty) return;
    
    setState(() { _isLoading = true; _error = null; _foundCase = null; });
    try {
      final response = await caseService.trackCase(ref);
      if (!mounted) return;
      if (response.isSuccess && response.data != null) {
        setState(() => _foundCase = response.data);
      } else {
        setState(() => _error = response.error ?? 'Ikibazo ntikiboneka. Reba neza nimero wanditse.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
