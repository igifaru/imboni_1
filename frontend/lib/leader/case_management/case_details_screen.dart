import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/widgets/countdown_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:imboni/shared/services/api_client.dart';
import 'package:imboni/shared/services/auth_service.dart'; // Import AuthService
import 'resolution_dialog.dart';
import 'manual_assignment_dialog.dart';
import 'package:intl/intl.dart';
import 'widgets/case_detail_card.dart';

// ... imports remain the same

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

  // CHECK: Can the current user perform actions?
  bool get _canPerformActions {
    // If case is closed/resolved, no actions
    if (_case.status == 'RESOLVED') return false;
    
    // If Unassigned (OPEN), any leader in the unit can take/assign it
    if (_case.assignedLeaderId == null || _case.assignedLeaderId!.isEmpty) return true;

    // If Assigned, ONLY the assigned leader can act
    final currentUserId = authService.currentUser?.id;
    return currentUserId == _case.assignedLeaderId;
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

  Future<void> _assignCase() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ManualAssignmentDialog(
         caseId: _case.id,
         administrativeUnitId: _case.administrativeUnitId,
      ),
    );

    if (result == true) {
      if (mounted) {
        _refreshCaseDetails();
        _fetchActions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionSuccess), backgroundColor: ImboniColors.success),
        );
      }
    }
  }

  // Theme Getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor => _isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white;
  Color get _textColor => _isDark ? Theme.of(context).colorScheme.onSurface : Colors.black87;
  Color get _subTextColor => _isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.grey[700]!;

  Future<void> _extendDeadline() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ExtendDeadlineDialog(
        caseStatus: _case.status,
        extensionCount: _case.extensionCount ?? 0,
      ),
    );

    if (result != null) {
      final days = result['days'] as int;
      final reason = result['reason'] as String;

      if (mounted) setState(() => _isLoading = true);
      try {
        final apiResult = await CaseService.instance.extendDeadline(_case.id, days, reason);
        if (apiResult.isSuccess && apiResult.data != null) {
          if (mounted) {
            setState(() => _case = apiResult.data!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).extensionSuccess), backgroundColor: ImboniColors.success),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(apiResult.error ?? 'Error'), backgroundColor: ImboniColors.error),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

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
    const contentMaxWidth = 1200.0;
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
                    _buildInfoItem(Icons.location_on_outlined, l10n.location, _case.locationPath ?? _case.locationName ?? 'Unknown', isDark, subTextColor, textColor),
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
        final isVideo = e.mimeType.startsWith('video/');
        final isPdf = e.mimeType == 'application/pdf';
        
        final url = '${ApiClient.storageUrl}${e.url}';
        
        // Extract extension for label (e.g. JPG, PDF, MP4)
        String ext = 'FILE';
        if (e.fileName.contains('.')) {
          ext = e.fileName.split('.').last.toUpperCase();
          if (ext.length > 4) ext = 'FILE'; 
        }

        return GestureDetector(
          onTap: () {
              if (isImage) {
                  _openLightbox(e);
              } else if (isAudio) {
                  _player.play(UrlSource(url));
              } else {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
          },
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
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAudio ? Icons.audiotrack :
                        isVideo ? Icons.videocam :
                        isPdf ? Icons.picture_as_pdf :
                        Icons.insert_drive_file,
                        size: 28,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAudio ? 'Audio' : ext, // Show extension for files/video
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[600]),
                      ),
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
      width: 200, // Increased from 140 to accommodate longer localized text
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
                  maxLines: 2, // Allow title to wrap
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
              _formatActionNotes(l10n, action.notes!),
              style: TextStyle(fontSize: 10, color: textColor, fontStyle: FontStyle.italic),
              maxLines: 4, // Increased lines for better readability of detailed notes
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
      case 'RESOLUTION': return Icons.task_alt;
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
      case 'RESOLUTION': return l10n.resolution;
      case 'VIEWED': return l10n.caseViewed;
      case 'ASSIGNED': return l10n.caseAssigned;
      case 'ACCEPTED': return l10n.caseAccepted;
      case 'STATUS_UPDATE': return l10n.caseStatusUpdate;
      case 'ASSIGNMENT': return l10n.caseAssignment;
      default: return type;
    }
  }

  // Helper to parse backend English strings and localize them
  String _formatActionNotes(AppLocalizations l10n, String note) {
    // 1. Check for Manual Assignment
    if (note.contains('Manually assigned to specific leader')) {
      return l10n.noteManualAssignment;
    }

    // 2. Check for Deadline Extension
    // Pattern: "Deadline extended by {days} days. Reason: "{reason}". Extension {count}/2."
    if (note.contains('Deadline extended by')) {
      try {
        final daysMatch = RegExp(r'extended by (\d+) days').firstMatch(note);
        final reasonMatch = RegExp(r'Reason: "([^"]+)"').firstMatch(note);
        final extMatch = RegExp(r'Extension (\d+/\d+)').firstMatch(note);

        String result = '';
        if (daysMatch != null) {
          result += '${l10n.noteDeadlineExtended} ${daysMatch.group(1)}. ';
        }
        if (reasonMatch != null) {
          result += '${l10n.noteReason}: "${reasonMatch.group(1)}". ';
        }
        if (extMatch != null) {
          result += '(${l10n.noteExtensionCount}: ${extMatch.group(1)})';
        }
        
        return result.isNotEmpty ? result : note;
      } catch (e) {
        return note; // Fallback to original if parsing fails
      }
    }

    return note;
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
    // Check permissions first
    if (!_canPerformActions) {
      // If user can't perform actions, don't show the card at all (or show read-only/taken message)
      return const SizedBox.shrink(); 
    }

    final canTakeCase = _case.status == 'OPEN' || _case.status == 'ESCALATED';
    
    return CaseDetailCard(
      backgroundColor: cardColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isBigScreen = constraints.maxWidth > 500; // Adjusted breakpoint
          
          final resolveButton = _buildResolveButton(l10n, canTakeCase);
          
          final escalateButton = (_case.status == 'IN_PROGRESS') 
              ? _buildEscalateButton(l10n) 
              : null;
              
          final assignButton = (canTakeCase || _case.status == 'IN_PROGRESS')
              ? _buildAssignButton(l10n, theme)
              : null;
              
          final extendButton = (_case.status == 'IN_PROGRESS')
              ? _buildExtendButton(l10n, theme)
              : null;
              
          if (isBigScreen) {
             return Row(
              children: [
                Expanded(child: resolveButton),
                if (escalateButton != null) ...[
                  const SizedBox(width: 16),
                  Expanded(child: escalateButton),
                ],
                if (extendButton != null) ...[
                  const SizedBox(width: 16),
                  Expanded(child: extendButton),
                ],
                if (assignButton != null) ...[
                   const SizedBox(width: 16),
                   Expanded(child: assignButton),
                ],
              ],
            );
          }
          
          // Small screen: Stacked rows
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: resolveButton),
                  if (escalateButton != null) ...[
                    const SizedBox(width: 12),
                    Expanded(child: escalateButton),
                  ],
                ],
              ),
              if (extendButton != null) ...[
                const SizedBox(height: 12),
                 SizedBox(width: double.infinity, child: extendButton),
              ],
              if (assignButton != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: assignButton,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExtendButton(AppLocalizations l10n, ThemeData theme) {
    final color = ImboniColors.warning;
    return OutlinedButton(
      onPressed: _extendDeadline,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_filled, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              l10n.extendDeadline,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildResolveButton(AppLocalizations l10n, bool canTakeCase) {
     return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
          onTap: canTakeCase
              ? () => _performAction('ACCEPT')
              : (_case.status == 'IN_PROGRESS') ? _resolveCase : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canTakeCase ? Icons.pan_tool_alt : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  canTakeCase ? l10n.takeCase : l10n.resolveCase,
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
    );
  }

  Widget _buildEscalateButton(AppLocalizations l10n) {
    return OutlinedButton(
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
      );
  }

  Widget _buildAssignButton(AppLocalizations l10n, ThemeData theme) {
    // Respects theme: uses theme color scheme secondary
    final color = theme.colorScheme.secondary;
    
    return OutlinedButton(
      onPressed: _assignCase,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            l10n.assignToStaff,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
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

class _ExtendDeadlineDialog extends StatefulWidget {
  final String? caseStatus;
  final int extensionCount;

  const _ExtendDeadlineDialog({this.caseStatus, this.extensionCount = 0});

  @override
  State<_ExtendDeadlineDialog> createState() => _ExtendDeadlineDialogState();
}

class _ExtendDeadlineDialogState extends State<_ExtendDeadlineDialog> {
  int? _selectedDays;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedDays != null && _reasonController.text.trim().isNotEmpty) {
      Navigator.pop(context, {
        'days': _selectedDays,
        'reason': _reasonController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600), // WIDER as requested
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              l10n.extendDeadlineTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // 1. Day Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.daysLabel,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (widget.extensionCount >= 2) 
                        ? ImboniColors.error.withAlpha(20) 
                        : ImboniColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${l10n.extensionsRemaining}: ${2 - widget.extensionCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (widget.extensionCount >= 2) ? ImboniColors.error : ImboniColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [1, 2, 3].map((d) {
                final isSelected = _selectedDays == d;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedDays = d),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        backgroundColor: isSelected ? theme.colorScheme.primary.withAlpha(20) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                      child: Text(
                        '$d ${d == 1 ? l10n.daySingular : l10n.dayPlural}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),

            // 2. Reason Input
            Text(
              l10n.extensionReasonLabel,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.extensionReasonHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
              ),
              onChanged: (_) => setState(() {}), // Refresh UI to update confirm button state
            ),

            const SizedBox(height: 24),

            // Warning
             if (widget.caseStatus == 'IN_PROGRESS')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ImboniColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ImboniColors.warning.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: ImboniColors.warning),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Text(
                         l10n.extensionLimitError,
                         style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                       ),
                     ),
                  ],
                ),
              ),

             const SizedBox(height: 24),

             // Footer Buttons
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 TextButton(
                   onPressed: () => Navigator.pop(context),
                   style: TextButton.styleFrom(
                     foregroundColor: theme.colorScheme.onSurfaceVariant,
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                   ),
                   child: Text(l10n.cancel),
                 ),
                 const SizedBox(width: 16),
                 FilledButton(
                   onPressed: (_selectedDays != null && _reasonController.text.trim().isNotEmpty) 
                       ? _submit 
                       : null,
                   style: FilledButton.styleFrom(
                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: Text(l10n.confirm),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }
}
