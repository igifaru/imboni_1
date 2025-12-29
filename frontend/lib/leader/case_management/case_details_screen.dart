import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:imboni/shared/services/api_client.dart'; // Ensure ApiClient is imported

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

  @override
  void initState() {
    super.initState();
    _case = widget.caseData;
    _refreshCaseDetails();
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

  Future<void> _performAction(String action, {String? notes}) async {
    setState(() => _isLoading = true);
    try {
      final result = await CaseService.instance.reviewCase(_case.id, action, notes);
      if (result.isSuccess && result.data != null) {
        if (mounted) {
          setState(() => _case = result.data!);
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
    // Redesigned UI matching 'Guhunga umungu' style
    final theme = Theme.of(context);
    final hasEvidence = _case.evidence != null && _case.evidence!.isNotEmpty;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow, // Slightly grey background
        appBar: AppBar(
          title: Text('Dosiye #${_case.caseReference.substring(0, 8)}...'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. Header Card
              _buildHeaderCard(theme),
              const SizedBox(height: 16),
              
              // 2. Info Grid Card
              _buildInfoGridCard(theme),
              const SizedBox(height: 16),
              
              // 3. Description Card
              _buildDescriptionCard(theme),
              const SizedBox(height: 16),
              
              // 4. Evidence Card
              _buildEvidenceCard(theme, hasEvidence),
              
              const SizedBox(height: 80), // Space for FAB/Bottom Bar
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomAction(theme),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _case.title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(_case.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dosiye #${_case.caseReference}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGridCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Amakuru y'Ingenzi", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(theme, Icons.balance, 'Icyiciro:', _case.category),
                    const SizedBox(height: 16),
                    _buildInfoItem(theme, Icons.location_on_outlined, 'Aho biri:', 'Umudugudu'), // Hardcoded level for now or extract from ID?
                    // Actually case model has currentLevel?
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(theme, Icons.calendar_today_outlined, 'Itariki:', _case.createdAt.toString().split(' ')[0]),
                    const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Ibisobanuro Birambuye", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           Text(_case.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Ibimenyetso", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           if (!hasEvidence)
             Center(
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 24),
                 child: Column(
                   children: [
                     Icon(Icons.folder_off_outlined, size: 48, color: theme.colorScheme.outline),
                     const SizedBox(height: 12),
                     Text('Nta bimenyetso byatanzwe kuri iyi dosiye.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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
        
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withAlpha(50)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.withAlpha(20),
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                child: Image.network('${ApiClient.baseUrl}${e.url}', fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                )
              : isAudio
                  ? InkWell(
                      onTap: () => _player.play(UrlSource('${ApiClient.baseUrl}${e.url}')),
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
        );
      }).toList(),
    );
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
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: (_case.status == 'OPEN') 
                    ? () => _performAction('ACCEPT') 
                    : (_case.status == 'IN_PROGRESS') ? _resolveCase : null,
                style: FilledButton.styleFrom(
                  backgroundColor: ImboniColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon((_case.status == 'OPEN') ? Icons.pan_tool_alt : Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    Text((_case.status == 'OPEN') ? 'Fata Iyi Dosiye' : 'Kemura Burundu'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_case.status == 'IN_PROGRESS' || _case.status == 'OPEN')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                   onPressed: _escalateCase,
                   style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   child: const Text('Ohereza hejuru (Escalate)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
