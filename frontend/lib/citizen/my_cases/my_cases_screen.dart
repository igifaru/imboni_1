import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/colors.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/api_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emeza ko ikibazo cyakemutse'),
        content: const Text('Uremeza ko iki kibazo cyakemutse neza? Iki gikorwa ntishobora gusubirwaho.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Emeza'),
          ),
        ],
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
            const SnackBar(content: Text('Ikibazo cyafunzwe. Murakoze!'), backgroundColor: Colors.green),
          );
          _loadCases();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Byanze'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _disputeResolution(CaseModel c) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regera ikibazo'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Impamvu yo kuregera',
            hintText: 'Sobanura impamvu iki kibazo kitakemutse neza...',
          ),
          maxLines: 3,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hagarika')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'Ikibazo nticyakemutse neza'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Ohereza'),
          ),
        ],
      ),
    );
    
    if (reason == null || reason.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await CaseService.instance.disputeResolution(c.id, reason);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ikibazo cyoherejwe ku rwego rukurikira'), backgroundColor: Colors.orange),
          );
          _loadCases();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Byanze'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red),
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
        title: Text(
          l10n.myCasesTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: ImboniColors.primary,
          labelColor: ImboniColors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[600],
          tabs: [
            _buildTab(l10n.allCases, _allCases.length, ImboniColors.primary),
            _buildTab(l10n.openCases, _openCases.length, ImboniColors.statusOpen),
            _buildTab(l10n.inProgressCases, _inProgressCases.length, ImboniColors.statusInProgress),
            _buildTab(l10n.resolvedCases, _resolvedCases.length, ImboniColors.statusResolved),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(theme, l10n)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCasesList(_allCases, theme, l10n, isDark),
                      _buildCasesList(_openCases, theme, l10n, isDark),
                      _buildCasesList(_inProgressCases, theme, l10n, isDark),
                      _buildCasesList(_resolvedCases, theme, l10n, isDark),
                    ],
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        return _buildProfessionalCaseCard(c, theme, l10n, isDark);
      },
    );
  }

  Widget _buildProfessionalCaseCard(CaseModel c, ThemeData theme, AppLocalizations l10n, bool isDark) {
    final statusColor = ImboniColors.getStatusColor(c.status);
    final categoryColor = ImboniColors.getCategoryColor(c.category);
    final urgencyColor = ImboniColors.getUrgencyColor(c.urgency);
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;

    return GestureDetector(
      onTap: () => _openCaseDetails(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left colored strip + Header
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  left: BorderSide(color: statusColor, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.caseReference,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(l10n, c.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    c.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Category + Urgency chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        _getCategoryIcon(c.category),
                        _getCategoryLabel(l10n, c.category),
                        categoryColor,
                        isDark,
                      ),
                      if (c.urgency.toUpperCase() != 'NORMAL')
                        _buildChip(
                          Icons.flag,
                          _getUrgencyLabel(l10n, c.urgency),
                          urgencyColor,
                          isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer: Location + Date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(8) : Colors.grey.withAlpha(15),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.white54 : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _getLevelLabel(l10n, c.currentLevel),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // Show confirm/dispute buttons for PENDING_CONFIRMATION status
                  if (c.status == 'PENDING_CONFIRMATION')
                    Row(
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
                  else
                    Text(
                      _formatTimeAgo(c.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 50 : 25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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

  // Helper methods for labels
  String _getStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return l10n.statusOpen;
      case 'IN_PROGRESS': return l10n.statusInProgress;
      case 'RESOLVED': return l10n.statusResolved;
      case 'ESCALATED': return l10n.statusEscalated;
      default: return status;
    }
  }

  String _getCategoryLabel(AppLocalizations l10n, String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return l10n.categoryJustice;
      case 'HEALTH': return l10n.categoryHealth;
      case 'LAND': return l10n.categoryLand;
      case 'INFRASTRUCTURE': return l10n.categoryInfrastructure;
      case 'SECURITY': return l10n.categorySecurity;
      case 'SOCIAL': return l10n.categorySocial;
      case 'EDUCATION': return l10n.categoryEducation;
      default: return l10n.categoryOther;
    }
  }

  String _getUrgencyLabel(AppLocalizations l10n, String urgency) {
    switch (urgency.toUpperCase()) {
      case 'HIGH': return l10n.urgencyHigh;
      case 'EMERGENCY': return l10n.urgencyEmergency;
      default: return l10n.urgencyNormal;
    }
  }

  String _getLevelLabel(AppLocalizations l10n, String level) {
    switch (level.toUpperCase()) {
      case 'VILLAGE': return l10n.levelVillage;
      case 'CELL': return l10n.levelCell;
      case 'SECTOR': return l10n.levelSector;
      case 'DISTRICT': return l10n.levelDistrict;
      case 'PROVINCE': return l10n.levelProvince;
      case 'NATIONAL': return l10n.levelNational;
      default: return level;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return Icons.balance;
      case 'HEALTH': return Icons.health_and_safety;
      case 'LAND': return Icons.terrain;
      case 'INFRASTRUCTURE': return Icons.construction;
      case 'SECURITY': return Icons.security;
      case 'SOCIAL': return Icons.people;
      case 'EDUCATION': return Icons.school;
      default: return Icons.category;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }

  void _openCaseDetails(CaseModel caseModel) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CitizenCaseDetailsScreen(caseModel: caseModel)));
  }
}

/// Professional Citizen Case Details Screen
class CitizenCaseDetailsScreen extends StatefulWidget {
  final CaseModel caseModel;

  const CitizenCaseDetailsScreen({super.key, required this.caseModel});

  @override
  State<CitizenCaseDetailsScreen> createState() => _CitizenCaseDetailsScreenState();
}

class _CitizenCaseDetailsScreenState extends State<CitizenCaseDetailsScreen> {
  List<CaseAction> _actions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchActions();
  }

  Future<void> _fetchActions() async {
    setState(() => _isLoading = true);
    try {
      final result = await CaseService.instance.getCaseActions(widget.caseModel.id);
      if (result.isSuccess && result.data != null && mounted) {
        setState(() => _actions = result.data!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmResolution() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).resolved,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).confirmResolutionContent,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context).cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ImboniColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(AppLocalizations.of(context).confirm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await CaseService.instance.confirmResolution(widget.caseModel.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).caseResolved), backgroundColor: ImboniColors.success),
          );
          Navigator.pop(context, true); // Return true to refresh parent
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed'), backgroundColor: ImboniColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ImboniColors.error),
        );
      }
    }
  }

  Future<void> _disputeResolution() async {
    String? reason;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).dispute,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).reasonForDispute,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: ImboniColors.warning, width: 2),
                    ),
                  ),
                  maxLines: 4,
                  onChanged: (v) => reason = v,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context).cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ImboniColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(AppLocalizations.of(context).submit),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (reason == null || reason!.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await CaseService.instance.disputeResolution(widget.caseModel.id, reason!);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case escalated to next level'), backgroundColor: ImboniColors.warning),
          );
          Navigator.pop(context, true); // Refresh parent
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed'), backgroundColor: ImboniColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ImboniColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;

    final caseModel = widget.caseModel;
    final statusColor = ImboniColors.getStatusColor(caseModel.status);
    final categoryColor = ImboniColors.getCategoryColor(caseModel.category);
    final urgencyColor = ImboniColors.getUrgencyColor(caseModel.urgency);

    final bgColor = isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC);
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    final subTextColor = isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          caseModel.caseReference,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: _fetchActions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 16,
                    vertical: 16,
                  ),
                  children: [
                    // Header Card
                    _buildHeaderCard(theme, l10n, isDark, cardColor, textColor, statusColor, categoryColor, urgencyColor, caseModel),
                    const SizedBox(height: 20),

                    // Confirmation Action Card
                    if (caseModel.status == 'PENDING_CONFIRMATION') ...[
                      _buildResolutionActionCard(theme, l10n, isDark, cardColor, textColor),
                      const SizedBox(height: 20),
                    ],

                    // Two Column Layout for Wide Screens
                    if (isWideScreen)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildInfoCard(theme, l10n, isDark, cardColor, textColor, subTextColor, caseModel),
                                const SizedBox(height: 20),
                                _buildDescriptionCard(theme, l10n, isDark, cardColor, textColor, subTextColor, caseModel),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildEvidenceCard(theme, l10n, isDark, cardColor, textColor, caseModel),
                          ),
                        ],
                      )
                    else
                      // Mobile: Single column
                      Column(
                        children: [
                          _buildInfoCard(theme, l10n, isDark, cardColor, textColor, subTextColor, caseModel),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(theme, l10n, isDark, cardColor, textColor, subTextColor, caseModel),
                          const SizedBox(height: 16),
                          _buildEvidenceCard(theme, l10n, isDark, cardColor, textColor, caseModel),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Timeline - Horizontal Row Format
                    _buildTimelineSection(theme, l10n, isDark, cardColor, textColor, subTextColor, caseModel),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color statusColor, Color categoryColor, Color urgencyColor, CaseModel caseModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildBadge(_getStatusLabel(l10n, caseModel.status), statusColor, Icons.circle, isDark),
              _buildBadge(_getCategoryLabel(l10n, caseModel.category), categoryColor, _getCategoryIcon(caseModel.category), isDark),
              _buildBadge(_getUrgencyLabel(l10n, caseModel.urgency), urgencyColor, Icons.flag, isDark),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            caseModel.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          
          // Case Reference
          Row(
            children: [
              Icon(Icons.tag, size: 16, color: isDark ? Colors.white54 : Colors.grey),
              const SizedBox(width: 6),
              Text(
                caseModel.caseReference,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 65 : 30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor, CaseModel caseModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 38 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.importantInfo,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(Icons.location_on_outlined, l10n.location, caseModel.locationName ?? 'Unknown', isDark, subTextColor, textColor),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.layers_outlined, l10n.level, _getLevelLabel(l10n, caseModel.currentLevel), isDark, subTextColor, textColor),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(Icons.calendar_today_outlined, l10n.date, _formatDate(caseModel.createdAt), isDark, subTextColor, textColor),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.access_time, l10n.time, _formatTime(caseModel.createdAt), isDark, subTextColor, textColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isDark, Color subTextColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subTextColor)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor, CaseModel caseModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 38 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.description,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(125),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              caseModel.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontSize: 14,
                color: subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, CaseModel caseModel) {
    final hasEvidence = caseModel.evidence != null && caseModel.evidence!.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 38 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.evidence,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
              ),
              const Spacer(),
              if (hasEvidence)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${caseModel.evidence!.length}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasEvidence)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 40,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noEvidenceProvided,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: caseModel.evidence!.map((e) {
                final isImage = e.mimeType.startsWith('image/');
                final isAudio = e.mimeType.startsWith('audio/');
                final isVideo = e.mimeType.startsWith('video/');
                
                IconData icon;
                Color iconColor;
                if (isImage) {
                  icon = Icons.image;
                  iconColor = ImboniColors.primary;
                } else if (isAudio) {
                  icon = Icons.audiotrack;
                  iconColor = ImboniColors.secondary;
                } else if (isVideo) {
                  icon = Icons.play_circle_outline;
                  iconColor = Colors.red;
                } else {
                  icon = Icons.description;
                  iconColor = isDark ? Colors.white54 : Colors.grey[600]!;
                }

                return GestureDetector(
                  onTap: () => _handleEvidenceTap(context, e),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(50)),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: iconColor, size: 28),
                        if (!isImage) ...[
                          const SizedBox(height: 4),
                          Text(
                            e.fileName.split('.').last.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Horizontal Timeline Section
  Widget _buildResolutionActionCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ImboniColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ImboniColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: ImboniColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resolution Confirmation Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The leader has marked this case as resolved. Please confirm if you are satisfied with the resolution, or dispute it if the issue persists.',
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _disputeResolution,
                  icon: const Icon(Icons.thumb_down_outlined, size: 18),
                  label: Text(l10n.dispute),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ImboniColors.warning,
                    side: const BorderSide(color: ImboniColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmResolution,
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: Text(l10n.confirm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ImboniColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Horizontal Timeline Section
  Widget _buildTimelineSection(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor, CaseModel caseModel) {
    // 1. Start with Creation
    final List<_TimelineData> timelineItems = [
      _TimelineData(
        title: l10n.caseCreated,
        date: caseModel.createdAt,
        color: ImboniColors.primary,
        icon: Icons.add_circle_outline,
      )
    ];

    // 2. Add Actions (Oldest to Newest)
    // Assuming _actions is fetched newest-first, we reverse it.
    // If _actions is empty, we rely on status synthesis below.
    if (_actions.isNotEmpty) {
      final sortedActions = List<CaseAction>.from(_actions);
      sortedActions.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Ensure ascending

      for (final action in sortedActions) {
        // Skip CREATED action if it duplicates the base item (within 1 min)
        if (action.actionType == 'CREATED' && 
            action.createdAt.difference(caseModel.createdAt).inMinutes.abs() < 1) {
          continue;
        }
        
        timelineItems.add(_TimelineData(
          title: _getActionTitle(l10n, action.actionType),
          date: action.createdAt,
          color: _getActionColor(action.actionType),
          icon: _getActionIcon(action.actionType),
          notes: action.notes,
        ));
      }
    } else {
       // If no history but status is advanced, synthesize intermediate steps
       if (caseModel.status != 'OPEN') {
          // Add "Accepted" synthetic step if missing
          timelineItems.add(_TimelineData(
             title: l10n.caseAccepted,
             date: caseModel.createdAt.add(const Duration(minutes: 5)), // Synthetic time
             color: ImboniColors.statusInProgress,
             icon: Icons.assignment_ind, 
          ));
       }
    }

    // 3. Synthesize Current Status Node if not represented by last action
    // This ensures the timeline always reflects the *current* state at the end
    final lastItem = timelineItems.last;
    final status = caseModel.status;
    
    bool needsStatusNode = true;
    
    // Check if last action title roughly matches status (simple heuristc)
    // E.g. last action "Resolved" matches status "RESOLVED"
    if (_getActionTitle(l10n, status).toLowerCase() == lastItem.title.toLowerCase()) {
      needsStatusNode = false;
    }
    
    // Specifically handle PENDING_CONFIRMATION
    if (status == 'PENDING_CONFIRMATION') {
       // Even if last action was "Resolved", we might want to show "Pending Confirmation" as a distinct step?
       // Let's add it as a new node to be clear.
       needsStatusNode = true;
    }

    if (needsStatusNode) {
       Color statusColor = ImboniColors.primary;
       IconData statusIcon = Icons.circle;
       String statusTitle = _getStatusLabel(l10n, status);
       
       switch(status) {
         case 'PENDING_CONFIRMATION':
           statusColor = ImboniColors.warning;
           statusIcon = Icons.hourglass_bottom;
           statusTitle = l10n.pendingConfirmation;
           break;
         case 'RESOLVED':
           statusColor = ImboniColors.success;
           statusIcon = Icons.check_circle;
           break;
         case 'ESCALATED':
           statusColor = Colors.red;
           statusIcon = Icons.trending_up;
           break;
         case 'IN_PROGRESS':
           statusColor = ImboniColors.statusInProgress;
           statusIcon = Icons.pending;
           break;
       }
       
       // Only add if it's not effectively the same as last item
       if (statusTitle != lastItem.title && status != 'OPEN') {
          timelineItems.add(_TimelineData(
            title: statusTitle,
            date: DateTime.now(), // Represents "Now"
            color: statusColor,
            icon: statusIcon,
            isCurrent: true,
          ));
       } else {
         // Mark the existing last item as current
         timelineItems[timelineItems.length - 1] = _TimelineData(
            title: lastItem.title,
            date: lastItem.date,
            color: lastItem.color,
            icon: lastItem.icon,
            notes: lastItem.notes,
            isCurrent: true,
         );
       }
    } else {
       // Mark the existing last item as current
       timelineItems[timelineItems.length - 1] = _TimelineData(
          title: lastItem.title,
          date: lastItem.date,
          color: lastItem.color,
          icon: lastItem.icon,
          notes: lastItem.notes,
          isCurrent: true,
       );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 38 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.timeline,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Timeline List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: timelineItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == timelineItems.length - 1;
              
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Item Card
                      Column(
                        children: [
                          Container(
                            width: 180,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.isCurrent 
                                  ? item.color.withValues(alpha: 0.1) 
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isCurrent 
                                    ? item.color 
                                    : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
                                width: item.isCurrent ? 2 : 1,
                              ),
                              boxShadow: item.isCurrent ? [
                                BoxShadow(
                                  color: item.color.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: item.color.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(item.icon, size: 18, color: item.color),
                                    ),
                                    const SizedBox(width: 12),
                                    if (item.isCurrent)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: item.color.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: item.isCurrent ? item.color : textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today, size: 12, color: subTextColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(item.date),
                                          style: TextStyle(fontSize: 11, color: subTextColor),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: subTextColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTime(item.date),
                                          style: TextStyle(fontSize: 11, color: subTextColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.notes!,
                                      style: TextStyle(
                                        fontSize: 11, 
                                        color: textColor.withValues(alpha: 0.8), 
                                        fontStyle: FontStyle.italic
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Dot/Connector below logic if vertical layout desired, 
                          // but here we are horizontal.
                        ],
                      ),
                      
                      // Horizontal Connector
                      if (!isLast)
                         Container(
                           height: 2,
                           width: 40,
                           margin: const EdgeInsets.only(top: 40, left: 4, right: 4), // Optimize alignment
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [
                                 item.color.withValues(alpha: 0.5), 
                                 timelineItems[index+1].color.withValues(alpha: 0.5)
                               ],
                             ),
                           ),
                         ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return l10n.statusOpen;
      case 'IN_PROGRESS': return l10n.statusInProgress;
      case 'RESOLVED': return l10n.statusResolved;
      case 'ESCALATED': return l10n.statusEscalated;
      default: return status;
    }
  }

  String _getCategoryLabel(AppLocalizations l10n, String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return l10n.categoryJustice;
      case 'HEALTH': return l10n.categoryHealth;
      case 'LAND': return l10n.categoryLand;
      case 'INFRASTRUCTURE': return l10n.categoryInfrastructure;
      case 'SECURITY': return l10n.categorySecurity;
      case 'SOCIAL': return l10n.categorySocial;
      case 'EDUCATION': return l10n.categoryEducation;
      default: return l10n.categoryOther;
    }
  }

  String _getUrgencyLabel(AppLocalizations l10n, String urgency) {
    switch (urgency.toUpperCase()) {
      case 'HIGH': return l10n.urgencyHigh;
      case 'EMERGENCY': return l10n.urgencyEmergency;
      default: return l10n.urgencyNormal;
    }
  }

  String _getLevelLabel(AppLocalizations l10n, String level) {
    switch (level.toUpperCase()) {
      case 'VILLAGE': return l10n.levelVillage;
      case 'CELL': return l10n.levelCell;
      case 'SECTOR': return l10n.levelSector;
      case 'DISTRICT': return l10n.levelDistrict;
      case 'PROVINCE': return l10n.levelProvince;
      case 'NATIONAL': return l10n.levelNational;
      default: return level;
    }
  }

  String _getActionTitle(AppLocalizations l10n, String type) {
    switch (type) {
      case 'CREATED': return l10n.caseCreated;
      case 'ESCALATED': return l10n.caseEscalated;
      case 'RESOLVED': return l10n.caseResolved;
      case 'VIEWED': return l10n.caseViewed;
      case 'ASSIGNED': return l10n.caseAssigned;
      case 'ACCEPTED': return l10n.caseAccepted;
      case 'STATUS_UPDATE': return l10n.statusUpdate;
      case 'RESOLUTION': return l10n.resolution;
      case 'PENDING_CONFIRMATION': return l10n.pendingConfirmation;
      default: return type.replaceAll('_', ' ').toLowerCase().split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }
  }

  Color _getActionColor(String type) {
    switch (type) {
      case 'CREATED': return ImboniColors.info;
      case 'ESCALATED': return ImboniColors.categoryJustice;
      case 'RESOLVED': return ImboniColors.success;
      case 'VIEWED': return Colors.grey;
      case 'ASSIGNED': return ImboniColors.secondary;
      case 'ACCEPTED': return ImboniColors.primary;
      case 'STATUS_UPDATE': return ImboniColors.statusInProgress;
      case 'RESOLUTION': return ImboniColors.success;
      case 'PENDING_CONFIRMATION': return ImboniColors.warning;
      default: return Colors.grey;
    }
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'CREATED': return Icons.add_circle_outline;
      case 'ESCALATED': return Icons.arrow_upward;
      case 'RESOLVED': return Icons.check_circle_outline;
      case 'VIEWED': return Icons.visibility;
      case 'ASSIGNED': return Icons.person_add;
      case 'ACCEPTED': return Icons.thumb_up_alt_outlined;
      case 'STATUS_UPDATE': return Icons.update;
      case 'RESOLUTION': return Icons.task_alt;
      case 'PENDING_CONFIRMATION': return Icons.hourglass_bottom;
      default: return Icons.info_outline;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return Icons.balance;
      case 'HEALTH': return Icons.health_and_safety;
      case 'LAND': return Icons.terrain;
      case 'INFRASTRUCTURE': return Icons.construction;
      case 'SECURITY': return Icons.security;
      case 'SOCIAL': return Icons.people;
      case 'EDUCATION': return Icons.school;
      default: return Icons.category;
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  void _handleEvidenceTap(BuildContext context, EvidenceModel e) {
    // Construct full URL
    final fullUrl = e.url.startsWith('http') 
        ? e.url 
        : '${ApiClient.storageUrl}${e.url.startsWith('/') ? '' : '/'}${e.url}';
        
    debugPrint('Opening evidence: $fullUrl');

    if (e.mimeType.startsWith('image/')) {
        _showImagePreview(context, fullUrl, e.fileName);
    } else if (e.mimeType.startsWith('audio/')) {
        showDialog(
          context: context,
          builder: (_) => _AudioPlayerDialog(url: fullUrl, fileName: e.fileName),
        );
    } else {
        // Video or Document -> Open externally
        _launchUrl(fullUrl);
    }
  }
  
  void _showImagePreview(BuildContext context, String url, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                loadingBuilder: (_, child, prog) => prog == null ? child : const CircularProgressIndicator(color: Colors.white),
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.broken_image, color: Colors.white, size: 48), Text('Failed to load image', style: TextStyle(color: Colors.white))],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $url')),
        );
      }
    }
  }
}

class _AudioPlayerDialog extends StatefulWidget {
  final String url;
  final String fileName;

  const _AudioPlayerDialog({required this.url, required this.fileName});

  @override
  State<_AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<_AudioPlayerDialog> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }
  
  Future<void> _initPlayer() async {
    try {
      await _player.setSourceUrl(widget.url);
      _duration = await _player.getDuration() ?? Duration.zero;
      
      _player.onDurationChanged.listen((d) => setState(() => _duration = d));
      _player.onPositionChanged.listen((p) => setState(() => _position = p));
      _player.onPlayerComplete.listen((_) => setState(() { _isPlaying = false; _position = Duration.zero; }));
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Audio init error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.audiotrack, size: 48, color: theme.colorScheme.secondary),
             const SizedBox(height: 16),
             Text(
               widget.fileName,
               style: theme.textTheme.titleMedium,
               textAlign: TextAlign.center,
               maxLines: 2,
             ),
             const SizedBox(height: 24),
             if (_isLoading)
               const CircularProgressIndicator()
             else ...[
               Slider(
                 value: _position.inSeconds.toDouble(),
                 max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                 onChanged: (v) async {
                   final pos = Duration(seconds: v.toInt());
                   await _player.seek(pos);
                 },
               ),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(_formatDuration(_position), style: theme.textTheme.bodySmall),
                   Text(_formatDuration(_duration), style: theme.textTheme.bodySmall),
                 ],
               ),
               const SizedBox(height: 16),
               IconButton.filled(
                 onPressed: _togglePlay,
                 icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                 iconSize: 32,
                 style: IconButton.styleFrom(
                   backgroundColor: theme.colorScheme.secondary,
                   foregroundColor: Colors.white,
                 ),
               ),
             ],
             const SizedBox(height: 16),
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text('Close'),
             ),
          ],
        ),
      ),
    );
  }
}

/// Timeline data helper class
class _TimelineData {
  final String title;
  final DateTime date;
  final Color color;
  final IconData icon;
  final String? notes;
  final bool isCurrent;

  _TimelineData({
    required this.title,
    required this.date,
    required this.color,
    required this.icon,
    this.notes,
    this.isCurrent = false,
  });
}
