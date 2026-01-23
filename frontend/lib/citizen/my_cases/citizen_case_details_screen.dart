import 'package:flutter/material.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import 'package:imboni/shared/services/api_client.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/widgets/case_details/case_header_card.dart';
import 'package:imboni/shared/widgets/case_details/case_info_card.dart';
import 'package:imboni/shared/widgets/case_details/case_description_card.dart';
import 'package:imboni/shared/widgets/case_details/case_evidence_card.dart';
import 'package:imboni/shared/widgets/case_details/case_timeline_section.dart';
import 'package:imboni/shared/widgets/case_details/case_detail_card.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/edit_case_dialog.dart';
import 'widgets/resolution_dialogs.dart';

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
  late CaseModel _currentCase; // Track current case for edit updates

  @override
  void initState() {
    super.initState();
    _currentCase = widget.caseModel;
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
      final response = await CaseService.instance.confirmResolution(widget.caseModel.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.caseResolved), backgroundColor: ImboniColors.success),
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
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const DisputeResolutionDialog(),
    );

    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await CaseService.instance.disputeResolution(widget.caseModel.id, reason);
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

  /// Show edit case dialog
  Future<void> _showEditDialog(ThemeData theme, AppLocalizations l10n, bool isDark) async {
    final result = await showDialog<CaseModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditCaseDialog(caseModel: _currentCase),
    );

    // Update the case if edit was successful
    if (result != null && mounted) {
      setState(() => _currentCase = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.caseUpdatedSuccess), backgroundColor: ImboniColors.success),
      );
      _fetchActions(); // Refresh timeline
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;

    final caseModel = _currentCase; // Use current case for updates
    
    final bgColor = isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC);
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;

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
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Edit Button (Only for OPEN cases and if user is owner - assumed by screen context)
          if (caseModel.status == 'OPEN')
             IconButton(
               icon: const Icon(Icons.edit, color: ImboniColors.primary),
               tooltip: l10n.editCase,
               onPressed: () => _showEditDialog(theme, l10n, isDark),
             ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? screenWidth * 0.1 : 16,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner for ActionRequired
                      if (caseModel.status == 'PENDING_CONFIRMATION') ...[
                        _buildResolutionActionCard(theme, l10n, isDark, cardColor, textColor),
                        const SizedBox(height: 24),
                      ],

                      // Header Card
                      CaseHeaderCard(caseModel: caseModel),
                      const SizedBox(height: 20),

                      // Grid Layout for Large Screens
                      if (isWideScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  CaseInfoCard(caseModel: caseModel),
                                  const SizedBox(height: 20),
                                  CaseDescriptionCard(caseModel: caseModel),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: CaseEvidenceCard(
                                caseModel: caseModel,
                                onEvidenceTap: (e) => _handleEvidenceTap(context, e),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                             CaseInfoCard(caseModel: caseModel),
                             const SizedBox(height: 16),
                             CaseDescriptionCard(caseModel: caseModel),
                             const SizedBox(height: 16),
                             CaseEvidenceCard(
                               caseModel: caseModel,
                               onEvidenceTap: (e) => _handleEvidenceTap(context, e),
                             ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Timeline
                      CaseTimelineSection(caseModel: caseModel, actions: _actions),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Horizontal Timeline Section
  Widget _buildResolutionActionCard(ThemeData theme, AppLocalizations l10n, bool isDark, Color cardColor, Color textColor) {
    return CaseDetailCard(
       title: l10n.pendingConfirmation,
       icon: Icons.check_circle_outline,
       backgroundColor: ImboniColors.primary.withValues(alpha: 0.05),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             l10n.resolutionActionDesc,
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

  // Evidence handling methods
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
               child: const Text('Close'),
             ),
          ],
        ),
      ),
    );
  }
}
