import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/professional_case_card.dart';
import '../../shared/localization/app_localizations.dart';


import 'citizen_case_details_screen.dart';
import 'widgets/resolution_dialogs.dart';

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

  Future<void> _confirmResolution(CaseModel c) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: l10n.resolved,
        content: l10n.confirmResolutionContent,
        confirmText: l10n.confirm,
        cancelText: l10n.cancel,
        confirmColor: ImboniColors.success,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await CaseService.instance.confirmResolution(c.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).caseResolved), backgroundColor: Colors.green),
          );
          _loadCases();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Error'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _disputeResolution(CaseModel c) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const DisputeResolutionDialog(),
    );
    
    if (reason == null || reason.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await CaseService.instance.disputeResolution(c.id, reason);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case escalated'), backgroundColor: Colors.orange),
          );
          _loadCases();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Error'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<CaseModel> get _openCases => _allCases.where((c) => c.status == 'OPEN').toList();
  List<CaseModel> get _inProgressCases => _allCases.where((c) => c.status == 'IN_PROGRESS' || c.status == 'ESCALATED').toList();
  List<CaseModel> get _resolvedCases => _allCases.where((c) => c.status == 'RESOLVED' || c.status == 'CLOSED' || c.status == 'PENDING_CONFIRMATION').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.myCasesTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Center(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: ImboniColors.primary,
              labelColor: ImboniColors.primary,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[600],
              padding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTab(l10n.allCases, _allCases.length, ImboniColors.primary),
                _buildTab(l10n.openCases, _openCases.length, ImboniColors.statusOpen),
                _buildTab(l10n.inProgressCases, _inProgressCases.length, ImboniColors.statusInProgress),
                _buildTab(l10n.resolvedCases, _resolvedCases.length, ImboniColors.statusResolved),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(theme, l10n)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCasesList(_allCases, theme, l10n, isDark),
                          _buildCasesList(_openCases, theme, l10n, isDark),
                          _buildCasesList(_inProgressCases, theme, l10n, isDark),
                          _buildCasesList(_resolvedCases, theme, l10n, isDark),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTab(String label, int count, Color color) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ]),
    );
  }

  Widget _buildCasesList(List<CaseModel> cases, ThemeData theme, AppLocalizations l10n, bool isDark) {
    if (cases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noCasesFound,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ProfessionalCaseCard(
             caseData: c,
             onTap: () => _openCaseDetails(c),
             actions: c.status == 'PENDING_CONFIRMATION' 
               ? Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _disputeResolution(c),
                      icon: const Icon(Icons.close, size: 16, color: Colors.orange),
                      label: Text(l10n.dispute, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmResolution(c),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(l10n.confirm, style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
               )
               : null,
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ImboniColors.error.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 48, color: ImboniColors.error),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.errorOccurred,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCases,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: ImboniColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }

  void _openCaseDetails(CaseModel caseModel) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CitizenCaseDetailsScreen(caseModel: caseModel)));
  }
}



