import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:imboni/shared/services/api_client.dart';
import '../../shared/widgets/timeline_widget.dart';

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
          _fetchActions(); // Refresh timeline
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Igikorwa cyagenze neza'), backgroundColor: ImboniColors.success),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Error'), backgroundColor: ImboniColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveCase() async {
    final controller = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kemura Ikibazo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Uko cyakemutse / Ibisobanuro',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Reka')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Emeza')),
        ],
      ),
    );

    if (shouldSubmit == true && controller.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final result = await CaseService.instance.resolveCase(_case.id, controller.text);
        if (result.isSuccess && result.data != null) {
          if (mounted) {
            setState(() => _case = result.data!);
            _fetchActions();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ikibazo cyakemuwe!'), backgroundColor: ImboniColors.success),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _escalateCase() async {
    final controller = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ohereza hejuru (Escalate)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanga impamvu iki kibazo kigomba koherezwa kurwego rwisumbuye:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Impamvu / Ibisobanuro',
                border: OutlineInputBorder(),
                hintText: 'Urugero: Nta bubasha dufite...'
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Reka')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ohereza')),
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
              const SnackBar(content: Text('Ikibazo cyoherejwe hejuru!'), backgroundColor: ImboniColors.success),
            );
          }
        } else {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed to escalate'), backgroundColor: ImboniColors.error));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEvidence = _case.evidence != null && _case.evidence!.isNotEmpty;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(theme),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Info Grid
                  _buildInfoGridCard(theme),
                  const SizedBox(height: 16),
                  
                  // 2. Description
                  _buildDescriptionCard(theme),
                  const SizedBox(height: 16),
                  
                  // 3. Evidence
                  _buildEvidenceCard(theme, hasEvidence),
                  const SizedBox(height: 16),
                  
                  // 4. Timeline
                  _buildTimelineCard(theme),

                  const SizedBox(height: 100), // Space for bottom bar
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomAction(theme),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar.large(
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.primary.withAlpha(10),
      title: Text(
        'Dosiye #${_case.caseReference.substring(0, 8)}...',
        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildStatusChip(_case.status),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
         background: Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter,
               colors: [theme.colorScheme.surface, theme.colorScheme.surfaceContainerLow],
             ),
           ),
         ),
      ),
    );
  }

  Widget _buildInfoGridCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
               const SizedBox(width: 8),
               Text("Amakuru y'Ingenzi", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(theme, Icons.balance, 'Icyiciro:', _case.category),
                    const SizedBox(height: 20),
                    _buildInfoItem(theme, Icons.location_on_outlined, 'Aho biri:', 'Umudugudu'), 
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(theme, Icons.calendar_today_outlined, 'Itariki:', _case.createdAt.toString().split(' ')[0]),
                    const SizedBox(height: 20),
                     _buildInfoItem(theme, Icons.person_outline, 'Uwabitangaje:', _case.isAnonymous ? 'Anonyme' : 'Umuturage'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary.withAlpha(200)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
               Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
               const SizedBox(width: 8),
               Text("Ibisobanuro", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
           const SizedBox(height: 12),
           Text(_case.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(ThemeData theme, bool hasEvidence) {
     return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
               Icon(Icons.attach_file, size: 20, color: theme.colorScheme.primary),
               const SizedBox(width: 8),
               Text("Ibimenyetso (Evidence)", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
           const SizedBox(height: 16),
           if (!hasEvidence)
             Center(
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 24),
                 child: Column(
                   children: [
                     Icon(Icons.folder_off_outlined, size: 48, color: theme.colorScheme.outline.withOpacity(0.5)),
                     const SizedBox(height: 12),
                     Text('Nta bimenyetso byatanzwe.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                   ],
                 ),
               ),
             )
           else
             _buildEvidenceGrid(),
        ],
      ),
    );
  }

  Widget _buildEvidenceGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _case.evidence!.map((e) {
        final isImage = e.mimeType.startsWith('image/');
        final isAudio = e.mimeType.startsWith('audio/');
        
        return GestureDetector(
          onTap: isImage ? () => _openLightbox(e) : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withAlpha(50)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withAlpha(10),
            ),
            child: isImage
                ? Hero(
                    tag: e.url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiClient.storageUrl}${e.url}', 
                        fit: BoxFit.cover, 
                        errorBuilder: (c,e,s) => const Icon(Icons.broken_image)
                      ),
                    ),
                  )
                : isAudio
                    ? InkWell(
                        onTap: () => _player.play(UrlSource('${ApiClient.storageUrl}${e.url}')),
                        borderRadius: BorderRadius.circular(12),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.play_circle_fill, size: 32, color: ImboniColors.primary),
                          SizedBox(height: 4),
                          Text('Audio', style: TextStyle(fontSize: 10)),
                        ]),
                      )
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.insert_drive_file, size: 32),
                        SizedBox(height: 4),
                        Text('File', style: TextStyle(fontSize: 10)),
                      ]),
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

  Widget _buildTimelineCard(ThemeData theme) {
    if (_actions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
               Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
               const SizedBox(width: 8),
               Text("Amateka ya Dosiye", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
           const SizedBox(height: 16),
           TimelineWidget(
             items: _actions.map((a) => TimelineItem(
               title: _getActionTitle(a.actionType),
               description: a.notes ?? '',
               date: a.createdAt,
               color: _getActionColor(a.actionType),
             )).toList().reversed.toList(), // Show newest first? Or oldest? TimelineWidget renders top-down. Usually newest top?
           ),
        ],
      ),
    );
  }

  String _getActionTitle(String type) {
    switch (type) {
      case 'CREATED': return 'Yarasibwe (Created)';
      case 'ESCALATED': return 'Yoherejwe Hejuru';
      case 'RESOLVED': return 'Yakemuwe';
      case 'VIEWED': return 'Yarebwe';
      case 'ASSIGNED': return 'Yahawe Umuyobozi';
       default: return type;
    }
  }

  Color _getActionColor(String type) {
    switch (type) {
      case 'CREATED': return Colors.blue;
      case 'ESCALATED': return Colors.purple;
      case 'RESOLVED': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
     Color color;
     String label = status;

    switch (status) {
      case 'OPEN': 
        color = Colors.blue; 
        label = "Iri gukorwaho (Open)";
        break;
      case 'IN_PROGRESS': 
        color = Colors.orange; 
        label = "Iri gukorwaho";
        break;
      case 'RESOLVED': 
        color = Colors.green; 
        label = "Yakemuwe";
        break;
      case 'CLOSED': 
        color = Colors.grey; 
        label = "Afuze";
        break;
      case 'ESCALATED':
         color = Colors.purple;
         label = "Yoherejwe Hejuru";
         break;
      default: color = Colors.black;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomAction(ThemeData theme) {
    if (_case.status == 'RESOLVED' || _case.status == 'CLOSED') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: (_case.status == 'OPEN') 
                    ? () => _performAction('ACCEPT') 
                    : (_case.status == 'IN_PROGRESS') ? _resolveCase : null,
                style: FilledButton.styleFrom(
                  backgroundColor: ImboniColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon((_case.status == 'OPEN') ? Icons.pan_tool_alt : Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Text((_case.status == 'OPEN') ? 'Fata Iyi Dosiye' : 'Kemura Burundu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
            if (_case.status == 'IN_PROGRESS' || _case.status == 'OPEN') ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                   onPressed: _escalateCase,
                   style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                     Icon(Icons.arrow_upward, size: 16),
                     SizedBox(width: 8),
                     Text('Ohereza hejuru', style: TextStyle(fontWeight: FontWeight.w600)),
                   ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
