import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/countdown_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:imboni/shared/services/api_client.dart';
import 'resolution_dialog.dart';
import 'package:intl/intl.dart';
import 'widgets/case_detail_card.dart';

class LeaderCaseDetailsScreen extends StatefulWidget {
  final CaseModel caseData;

  const LeaderCaseDetailsScreen({super.key, required this.caseData});

  @override
  State<LeaderCaseDetailsScreen> createState() => _LeaderCaseDetailsScreenState();
}

class _LeaderCaseDetailsScreenState extends State<LeaderCaseDetailsScreen> {
  late CaseModel _case;
  bool _isLoading = false;
  final _player = AudioPlayer();
  List<CaseAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _case = widget.caseData;
    _refreshCaseDetails();
    _fetchActions();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _refreshCaseDetails() async {
    final result = await CaseService.instance.getCaseById(_case.id);
    if (result.isSuccess && result.data != null) {
      if (mounted) setState(() => _case = result.data!);
    }
  }

  Future<void> _fetchActions() async {
    final result = await CaseService.instance.getCaseActions(_case.id);
    if (result.isSuccess && result.data != null) {
      if (mounted) setState(() => _actions = result.data!);
    }
  }

  Future<void> _performAction(String action, {String? notes}) async {
    setState(() => _isLoading = true);
    try {
      final result = await CaseService.instance.reviewCase(_case.id, action, notes);
      if (result.isSuccess && result.data != null) {
        if (mounted) {
          setState(() => _case = result.data!);
          _fetchActions();
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.actionSuccess), backgroundColor: ImboniColors.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Error'), backgroundColor: ImboniColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveCase() async {
    final updatedCase = await showDialog<CaseModel>(
      context: context,
      builder: (ctx) => ResolutionDialog(caseId: _case.id),
    );

    if (updatedCase != null && mounted) {
      setState(() => _case = updatedCase);
      _fetchActions();
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.caseResolvedSuccess), backgroundColor: ImboniColors.success),
      );
    }
  }

  Future<void> _escalateCase() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.escalate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.escalateReason, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.description,
                border: const OutlineInputBorder(),
                hintText: l10n.escalateHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );

    if (shouldSubmit == true && controller.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final result = await CaseService.instance.escalateCase(_case.id, controller.text);
        if (result.isSuccess && result.data != null) {
          if (mounted) {
            setState(() => _case = result.data!);
            _fetchActions();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.caseEscalatedSuccess), backgroundColor: ImboniColors.success),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.error ?? 'Failed to escalate'), backgroundColor: ImboniColors.error),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Theme Getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor => _isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white;
  Color get _textColor => _isDark ? Theme.of(context).colorScheme.onSurface : Colors.black87;
  Color get _subTextColor => _isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.grey[700]!;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: _buildAppBar(Theme.of(context), _isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    
    // SAFE CENTERING: Calculate horizontal padding manually
    final contentMaxWidth = 1200.0;
    double horizontalPadding = 16.0;
    
    if (screenWidth > contentMaxWidth) {
      horizontalPadding = (screenWidth - contentMaxWidth) / 2;
    } else if (isDesktop) {
      horizontalPadding = screenWidth * 0.1;
    } else if (isTablet) {
      horizontalPadding = 24.0;
    }
    
    final hasEvidence = _case.evidence != null && _case.evidence!.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(theme, _isDark),
      body: RefreshIndicator(
        onRefresh: _refreshCaseDetails,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          children: [
            // Header Section
            _buildHeaderCard(theme, l10n, _isDark, _cardColor, _textColor),
            const SizedBox(height: 20),

            // Main Content (Grid-like logic)
            if (isDesktop || isTablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                        const SizedBox(height: 20),
                        _buildDescriptionCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right Column
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReporterCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                        const SizedBox(height: 20),
                        _buildEvidenceCard(theme, l10n, _isDark, _cardColor, _textColor, hasEvidence),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                  const SizedBox(height: 16),
                  _buildReporterCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                  const SizedBox(height: 16),
                  _buildEvidenceCard(theme, l10n, _isDark, _cardColor, _textColor, hasEvidence),
                ],
              ),

            const SizedBox(height: 20),
            _buildTimelineSection(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
            
            // Action Buttons (Moved Inline)
            if (!(_case.status == 'RESOLVED' || _case.status == 'CLOSED'))
             Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildActionButtonsCard(theme, l10n, _isDark, _cardColor),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _case.caseReference,
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
          onPressed: () {
            _refreshCaseDetails();
            _fetchActions();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildHeaderCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor) {
    final statusColor = ImboniColors.getStatusColor(_case.status);
    final urgencyColor = ImboniColors.getUrgencyColor(_case.urgency);
    final categoryColor = ImboniColors.getCategoryColor(_case.category);

    return CaseDetailCard(
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status + Category + Urgency + Countdown badges
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildBadge(_getStatusLabel(l10n, _case.status), statusColor, Icons.circle, isDark),
              _buildBadge(_getCategoryLabel(l10n, _case.category), categoryColor, _getCategoryIcon(_case.category), isDark),
              _buildBadge(_getUrgencyLabel(l10n, _case.urgency), urgencyColor, Icons.flag, isDark),
              // Countdown Timer
              if (_case.deadline != null)
                CountdownTimer(
                  deadline: _case.deadline!,
                  showIcon: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            _case.title,
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
                _case.caseReference,
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

  Widget _buildInfoCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return CaseDetailCard(
      title: l10n.importantInfo,
      icon: Icons.info_outline,
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Grid - 2 columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(Icons.location_on_outlined, l10n.location, _case.locationName ?? 'Unknown', isDark, subTextColor, textColor),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.layers_outlined, l10n.level, _getLevelLabel(l10n, _case.currentLevel), isDark, subTextColor, textColor),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(Icons.calendar_today_outlined, l10n.date, _formatDate(_case.createdAt), isDark, subTextColor, textColor),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.access_time, l10n.time, _formatTime(_case.createdAt), isDark, subTextColor, textColor),
                  ],
                ),
              ),
            ],
          ),
          
          // Deadline if exists
          if (_case.deadline != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ImboniColors.warning.withAlpha(isDark ? 50 : 25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ImboniColors.warning.withAlpha(75)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: ImboniColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.deadline}: ${_formatDate(_case.deadline!)}',
                    style: const TextStyle(
                      color: ImboniColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildDescriptionCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return CaseDetailCard(
      title: l10n.description,
      icon: Icons.description_outlined,
      backgroundColor: cardColor,
      child: Container(
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
          _case.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            fontSize: 14,
            color: subTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildReporterCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return CaseDetailCard(
      title: l10n.reporter,
      icon: Icons.person_outline,
      backgroundColor: cardColor,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _case.isAnonymous 
                ? (isDark ? Colors.grey[700] : Colors.grey[300])
                : theme.colorScheme.primaryContainer,
            child: Icon(
              _case.isAnonymous ? Icons.visibility_off : Icons.person,
              color: _case.isAnonymous 
                  ? (isDark ? Colors.white54 : Colors.grey[600])
                  : theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _case.isAnonymous ? l10n.anonymous : (_case.citizenName ?? l10n.citizen),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _case.isAnonymous ? l10n.submittedAnonymouslyLabel : l10n.citizen,
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, bool hasEvidence) {
    return CaseDetailCard(
      title: l10n.evidence,
      icon: Icons.attach_file,
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasEvidence)
             Center(
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
             )
          else
            _buildEvidenceGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildEvidenceGrid(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: (_case.evidence ?? []).map((e) {
        final isImage = e.mimeType.startsWith('image/');
        final isAudio = e.mimeType.startsWith('audio/');

        return GestureDetector(
          onTap: isImage ? () => _openLightbox(e) : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(50)),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(15),
            ),
            child: isImage
                ? Hero(
                    tag: e.url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiClient.storageUrl}${e.url}',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                      ),
                    ),
                  )
                : isAudio
                    ? InkWell(
                        onTap: () => _player.play(UrlSource('${ApiClient.storageUrl}${e.url}')),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill, size: 28, color: ImboniColors.primary),
                            const SizedBox(height: 4),
                            Text('Audio', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[600])),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file, size: 28, color: isDark ? Colors.white54 : Colors.grey[600]),
                          const SizedBox(height: 4),
                          Text('File', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[600])),
                        ],
                      ),
          ),
        );
      }).toList(),
    );
  }

  void _openLightbox(EvidenceModel evidence) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: Hero(
              tag: evidence.url,
              child: Image.network(
                '${ApiClient.storageUrl}${evidence.url}',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    ));
  }

  // Timeline Section - Horizontal Row Format
  Widget _buildTimelineSection(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    if (_actions.isEmpty) return const SizedBox.shrink();

    final reversedActions = _actions.reversed.toList();

    return CaseDetailCard(
      backgroundColor: cardColor,
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
          const SizedBox(height: 20),

          // Horizontal timeline
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: reversedActions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                final isLast = index == reversedActions.length - 1;
                final color = _getActionColor(action.actionType);

                return Row(
                  children: [
                    // Timeline Item
                    _buildTimelineItem(l10n, action, color, isDark, textColor, subTextColor),
                    
                    // Connector line
                    if (!isLast)
                      Container(
                        width: 40,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withAlpha(150), _getActionColor(reversedActions[index + 1].actionType).withAlpha(150)],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(AppLocalizations l10n, CaseAction action, Color color, bool isDark, Color textColor, Color subTextColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 38 : 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getActionIcon(action.actionType), size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getActionTitle(l10n, action.actionType),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Date/Time
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: subTextColor),
              const SizedBox(width: 4),
              Text(
                _formatDate(action.createdAt),
                style: TextStyle(fontSize: 10, color: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: subTextColor),
              const SizedBox(width: 4),
              Text(
                _formatTime(action.createdAt),
                style: TextStyle(fontSize: 10, color: subTextColor),
              ),
            ],
          ),
          
          // Notes if any
          if (action.notes != null && action.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              action.notes!,
              style: TextStyle(fontSize: 10, color: textColor, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'CREATED': return Icons.add_circle_outline;
      case 'ESCALATED': return Icons.arrow_upward;
      case 'RESOLVED': return Icons.check_circle_outline;
      case 'VIEWED': return Icons.visibility;
      case 'ASSIGNED': return Icons.person_add;
      case 'ACCEPTED': return Icons.thumb_up_alt_outlined;
      default: return Icons.info_outline;
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
      default: return type;
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
      default: return Colors.grey;
    }
  }

  Widget _buildActionButtonsCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor) {
    return CaseDetailCard(
      backgroundColor: cardColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ImboniColors.primary, ImboniColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ImboniColors.primary.withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_case.status == 'OPEN')
                      ? () => _performAction('ACCEPT')
                      : (_case.status == 'IN_PROGRESS') ? _resolveCase : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (_case.status == 'OPEN') ? Icons.pan_tool_alt : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          (_case.status == 'OPEN') ? l10n.takeCase : l10n.resolveCase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_case.status == 'IN_PROGRESS' || _case.status == 'OPEN') ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _escalateCase,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ImboniColors.error,
                  side: const BorderSide(color: ImboniColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_upward, size: 18, color: ImboniColors.error),
                    const SizedBox(width: 8),
                    Text(
                      l10n.escalate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ImboniColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
