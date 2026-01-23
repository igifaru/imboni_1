import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';


import 'package:imboni/shared/services/api_client.dart';
import 'package:imboni/shared/services/auth_service.dart'; // Import AuthService
import 'resolution_dialog.dart';
import 'manual_assignment_dialog.dart';
import '../../shared/widgets/pdf_viewer_screen.dart';
import '../../shared/widgets/media_viewers.dart';

import 'package:imboni/shared/widgets/case_details/case_header_card.dart';
import 'package:imboni/shared/widgets/case_details/case_info_card.dart';
import 'package:imboni/shared/widgets/case_details/case_description_card.dart';
import 'package:imboni/shared/widgets/case_details/case_evidence_card.dart';
import 'package:imboni/shared/widgets/case_details/case_timeline_section.dart';
import 'package:imboni/shared/widgets/case_details/case_detail_card.dart';


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
  List<CaseAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _case = widget.caseData;
    _refreshCaseDetails();
    _fetchActions();
  }



  // CHECK: Can the current user perform actions?
  bool get _canPerformActions {
    // If case is closed/resolved, no actions
    if (_case.status == 'RESOLVED') return false;
    
    // If Unassigned (OPEN), any leader in the unit can take/assign it
    // If Assigned, ONLY the assigned leader can act
    // However, we apply robust fallbacks for data inconsistencies or admin overrides
    final user = authService.currentUser;
    if (user == null) return false;

    // 1. Exact ID Match (Primary)
    if (user.id == _case.assignedLeaderId) return true;
    
    // 2. Admin Override
    if (user.role == 'ADMIN') return true;

    // 3. Name Match Fallback (Robust: Case-insensitive, Partial)
    if (_case.assignedLeaderName != null && user.name != null) {
       final assignedName = _case.assignedLeaderName!.trim().toLowerCase();
       final currentName = user.name!.trim().toLowerCase();
       
       if (assignedName.isNotEmpty && currentName.isNotEmpty) {
           if (assignedName == currentName) return true;
           if (assignedName.contains(currentName) || currentName.contains(assignedName)) return true;
       }
    }
    
    return false;
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
            CaseHeaderCard(caseModel: _case),
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
                        CaseInfoCard(caseModel: _case),
                        const SizedBox(height: 20),
                        CaseDescriptionCard(caseModel: _case),
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
                        CaseEvidenceCard(
                          caseModel: _case,
                          onEvidenceTap: _handleEvidenceTap,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CaseInfoCard(caseModel: _case),
                  const SizedBox(height: 16),
                  CaseDescriptionCard(caseModel: _case),
                  const SizedBox(height: 16),
                  _buildReporterCard(theme, l10n, _isDark, _cardColor, _textColor, _subTextColor),
                  const SizedBox(height: 16),
                  CaseEvidenceCard(
                    caseModel: _case,
                    onEvidenceTap: _handleEvidenceTap,
                  ),
                ],
              ),

            const SizedBox(height: 20),
            CaseTimelineSection(caseModel: _case, actions: _actions),
            
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

  // Duplicate UI builders removed (Header, Info, Description) - Replaced by shared widgets


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

  // Evidence builders removed - Replaced by shared
  void _handleEvidenceTap(EvidenceModel e) {
    // Preserve existing Leader evidence logic
    final url = '${ApiClient.storageUrl}${e.url}';

    // Generic Extension Check
    final ext = e.fileName.split('.').last.toLowerCase();
    final isPdf = ext == 'pdf' || e.mimeType == 'application/pdf';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) || e.mimeType.startsWith('image/');
    final isAudio = ['mp3', 'wav', 'aac', 'm4a'].contains(ext) || e.mimeType.startsWith('audio/');
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext) || e.mimeType.startsWith('video/');

    if (isImage) {
        // Collect all images for gallery
        final allImages = (_case.evidence ?? []).where((ev) {
           final ex = ev.fileName.split('.').last.toLowerCase();
           return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ex) || ev.mimeType.startsWith('image/');
        }).toList();

        final initialIndex = allImages.indexOf(e);
        
        // Map to URLs and Names
        final urls = allImages.map((ev) => '${ApiClient.storageUrl}${ev.url}').toList();
          
        final names = allImages.map((ev) => ev.fileName).toList();

        showDialog(
          context: context,
          builder: (_) => GalleryImageViewerDialog(
            urls: urls,
            fileNames: names,
            initialIndex: initialIndex != -1 ? initialIndex : 0,
          ),
        );
    } else if (isPdf) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(url: url, fileName: e.fileName),
          ),
        );
    } else if (isAudio) {
        showDialog(
          context: context,
          builder: (_) => AudioPlayerDialog(url: url, fileName: e.fileName),
        );
    } else if (isVideo) {
        showDialog(
          context: context,
          builder: (_) => VideoPlayerDialog(url: url, fileName: e.fileName),
        );
    } else {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
