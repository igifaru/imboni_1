import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'package:audioplayers/audioplayers.dart';

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
    _refreshCaseDetails(); // Fetch fresh data including evidence
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasEvidence = _case.evidence != null && _case.evidence!.isNotEmpty;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_case.caseReference),
          actions: [
            _buildStatusChip(_case.status),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header Info
            Text(_case.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.category, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(_case.category, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(_case.createdAt.toString().split(' ')[0], style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 24),

            // Description
            Text('Ibisobanuro', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_case.description, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 24),

            // Evidence Section
            Text('Ibimenyetso (Evidence)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!hasEvidence)
              const Text('Nta bimenyetso bihari.', style: TextStyle(fontStyle: FontStyle.italic))
            else
              _buildEvidenceGrid(),

            const SizedBox(height: 40),
          ]),
        ),
        bottomNavigationBar: _buildActionAndNavbar(theme),
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
                child: Image.network('http://localhost:3000${e.url}', fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                )
              : isAudio
                  ? InkWell(
                      onTap: () => _player.play(UrlSource('http://localhost:3000${e.url}')),
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
    switch (status) {
      case 'OPEN': color = Colors.blue; break;
      case 'IN_PROGRESS': color = Colors.orange; break;
      case 'RESOLVED': color = Colors.green; break;
      case 'CLOSED': color = Colors.grey; break;
      default: color = Colors.black;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildActionAndNavbar(ThemeData theme) {
    if (_case.status == 'RESOLVED' || _case.status == 'CLOSED') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(children: [
          if (_case.status == 'OPEN') ...[
            Expanded(child: FilledButton.tonal(
              onPressed: () => _performAction('ACCEPT'),
              child: const Text('Fata Ikibazo'),
            )),
          ],
          if (_case.status == 'IN_PROGRESS') ...[
            Expanded(child: OutlinedButton(
              onPressed: () => _performAction('REQUEST_INFO'),
              child: const Text('Saba Amakuru'),
            )),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
              onPressed: _resolveCase,
              style: FilledButton.styleFrom(backgroundColor: ImboniColors.success),
              child: const Text('Kemura'),
            )),
          ],
        ]),
      ),
    );
  }
}
