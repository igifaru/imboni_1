import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/category_selector.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/widgets/case_submission/media_attachment_widget.dart';
import '../../shared/widgets/case_submission/audio_recorder_widget.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/case_service.dart';
import '../../shared/services/admin_units_service.dart';
import '../../shared/models/models.dart';

/// Submit Case Screen - with location selection
class SubmitCaseScreen extends StatefulWidget {
  final bool isEmergency;
  final bool isAnonymous;

  const SubmitCaseScreen({super.key, this.isEmergency = false, this.isAnonymous = false});

  @override
  State<SubmitCaseScreen> createState() => _SubmitCaseScreenState();
}

class _SubmitCaseScreenState extends State<SubmitCaseScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _loadingMessage;
  
  // Form state
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _urgency = 'NORMAL';
  bool _isAnonymous = false;
  LocationSelection _location = const LocationSelection();
  List<CaseAttachment> _attachments = [];
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _isAnonymous = widget.isAnonymous;
    if (widget.isEmergency) _urgency = 'EMERGENCY';
  }

  @override
  void dispose() { _titleController.dispose(); _descriptionController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: _loadingMessage ?? 'Gutanga ikibazo...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEmergency ? l10n.emergency : l10n.submitCase),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _buildStepIndicator(theme, l10n),
          ),
        ),
        body: Form(
          key: _formKey,
          child: _currentStep == 0 
              ? _buildStep1(theme, l10n) 
              : _currentStep == 1 
                  ? _buildStep2(theme, l10n)
                  : _buildStep3(theme, l10n),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(children: [
        _buildStepDot(0, 'Ikibazo', theme),
        Expanded(child: Container(height: 2, color: _currentStep >= 1 ? ImboniColors.primary : theme.colorScheme.outline)),
        _buildStepDot(1, 'Aho kibarizwa', theme),
        Expanded(child: Container(height: 2, color: _currentStep >= 2 ? ImboniColors.primary : theme.colorScheme.outline)),
        _buildStepDot(2, l10n.evidence, theme),
      ]),
    );
  }

  Widget _buildStepDot(int step, String label, ThemeData theme) {
    final isActive = _currentStep >= step;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? ImboniColors.primary : theme.colorScheme.surfaceContainerHighest, border: Border.all(color: isActive ? ImboniColors.primary : theme.colorScheme.outline)),
        child: Center(child: isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant))),
      ),
      const SizedBox(height: 4),
      Text(label, style: theme.textTheme.labelSmall?.copyWith(color: isActive ? ImboniColors.primary : theme.colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _buildStep1(ThemeData theme, AppLocalizations l10n) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (widget.isEmergency) _buildEmergencyBanner(theme),
      _buildAnonymousToggle(l10n, theme),
      const SizedBox(height: 24),
      
      Text(l10n.selectCategory, style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      CategorySelector(selectedCategory: _selectedCategory, onCategorySelected: (cat) => setState(() => _selectedCategory = cat)),
      const SizedBox(height: 24),
      
      if (!widget.isEmergency) ...[
        Text('Ubukana', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildUrgencySelector(theme),
        const SizedBox(height: 24),
      ],
      
      Text('Umutwe w\'ikibazo', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      TextFormField(controller: _titleController, decoration: const InputDecoration(hintText: 'Umutwe muto usobanura ikibazo'), validator: (v) => (v == null || v.length < 5) ? 'Umutwe ugomba kuba nibura inyuguti 5' : null),
      const SizedBox(height: 24),
      
      Text(l10n.describeIssue, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      TextFormField(controller: _descriptionController, decoration: const InputDecoration(hintText: 'Sobanura neza ikibazo cyawe'), maxLines: 5, validator: (v) => (v == null || v.length < 20) ? 'Ibisobanuro bigomba kuba nibura inyuguti 20' : null),
      const SizedBox(height: 32),
      
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate() && _selectedCategory != null) setState(() => _currentStep = 1);
          else if (_selectedCategory == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hitamo icyiciro')));
        },
        child: const Text('Komeza'),
      ),
    ]);
  }

  Widget _buildStep2(ThemeData theme, AppLocalizations l10n) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ImboniColors.info.withAlpha(25), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.info_outline, color: ImboniColors.info),
          const SizedBox(width: 12),
          Expanded(child: Text('Hitamo aho ikibazo kibarizwa (aho cyabereye)', style: theme.textTheme.bodyMedium)),
        ]),
      ),
      const SizedBox(height: 24),
      
      LocationSelector(
        initialSelection: _location,
        onLocationChanged: (loc) => setState(() => _location = loc),
      ),
      const SizedBox(height: 24),
      
      if (_location.isComplete)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ImboniColors.success.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: ImboniColors.success.withAlpha(75))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle, color: ImboniColors.success, size: 20),
              const SizedBox(width: 8),
              Text('Aho ikibazo kibarizwa', style: theme.textTheme.labelLarge?.copyWith(color: ImboniColors.success)),
            ]),
            const SizedBox(height: 8),
            Text(_location.fullAddress, style: theme.textTheme.bodyMedium),
          ]),
        ),
      const SizedBox(height: 32),
      
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('Subira inyuma'))),
        const SizedBox(width: 16),
        Expanded(child: ElevatedButton(onPressed: _location.isComplete ? () => setState(() => _currentStep = 2) : null, child: const Text('Komeza'))),
      ]),
    ]);
  }

  Widget _buildStep3(ThemeData theme, AppLocalizations l10n) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Info banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.attach_file_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(
            l10n.addEvidence,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          )),
        ]),
      ),
      const SizedBox(height: 24),

      // Media attachments (images, video, documents)
      MediaAttachmentWidget(
        attachments: _attachments,
        onChanged: (attachments) => setState(() => _attachments = attachments),
      ),
      const SizedBox(height: 24),

      // Voice note recorder
      AudioRecorderWidget(
        audioPath: _audioPath,
        onRecordingComplete: (path) => setState(() => _audioPath = path),
      ),
      const SizedBox(height: 32),

      // Summary card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Incamake', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _SummaryRow(icon: Icons.category_outlined, label: 'Icyiciro', value: _selectedCategory ?? '-'),
          _SummaryRow(icon: Icons.location_on_outlined, label: 'Ahantu', value: _location.village ?? '-'),
          _SummaryRow(icon: Icons.attach_file, label: l10n.evidence, value: '${_attachments.length + (_audioPath != null ? 1 : 0)}'),
        ]),
      ),
      const SizedBox(height: 24),

      // Navigation buttons
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep = 1), child: const Text('Subira inyuma'))),
        const SizedBox(width: 16),
        Expanded(child: ElevatedButton(
          onPressed: _submitCase,
          child: Text(l10n.submitCase),
        )),
      ]),
    ]);
  }

  Widget _buildEmergencyBanner(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: ImboniColors.urgencyEmergency.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: ImboniColors.urgencyEmergency)),
    child: Row(children: [const Icon(Icons.warning_amber_rounded, color: ImboniColors.urgencyEmergency), const SizedBox(width: 12), Expanded(child: Text('Ikibazo cy\'ubutabazi bwihutirwa kiremerwa vuba', style: theme.textTheme.bodyMedium?.copyWith(color: ImboniColors.urgencyEmergency)))]),
  );

  Widget _buildAnonymousToggle(AppLocalizations l10n, ThemeData theme) => Card(
    child: SwitchListTile(title: Text(l10n.submitAnonymously), subtitle: Text(l10n.anonymousExplanation, style: theme.textTheme.bodySmall), value: _isAnonymous, onChanged: (v) => setState(() => _isAnonymous = v), secondary: Icon(_isAnonymous ? Icons.visibility_off : Icons.visibility, color: _isAnonymous ? ImboniColors.primary : null)),
  );

  Widget _buildUrgencySelector(ThemeData theme) => Row(children: [
    _UrgencyChip(label: 'Bisanzwe', isSelected: _urgency == 'NORMAL', color: ImboniColors.urgencyNormal, onTap: () => setState(() => _urgency = 'NORMAL')),
    const SizedBox(width: 8),
    _UrgencyChip(label: 'Bikomeye', isSelected: _urgency == 'HIGH', color: ImboniColors.urgencyHigh, onTap: () => setState(() => _urgency = 'HIGH')),
    const SizedBox(width: 8),
    _UrgencyChip(label: 'Ubutabazi', isSelected: _urgency == 'EMERGENCY', color: ImboniColors.urgencyEmergency, onTap: () => setState(() => _urgency = 'EMERGENCY')),
  ]);

  Future<void> _submitCase() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Gutunganya ikibazo...';
    });
    
    try {
      // 1. Create Case
      final unitId = '${_location.province}_${_location.district}_${_location.sector}_${_location.cell}_${_location.village}';
      final request = CreateCaseRequest(
        category: _selectedCategory!, 
        urgency: _urgency, 
        title: _titleController.text, 
        description: _descriptionController.text, 
        administrativeUnitId: unitId, 
        submittedAnonymously: _isAnonymous
      );
      
      final response = await caseService.submitCase(request);
      
      if (!mounted) return;
      
      if (response.isSuccess && response.data != null) { 
        final caseId = response.data!.id;
        
        // 2. Upload Evidence
        final evidenceCount = _attachments.length + (_audioPath != null ? 1 : 0);
        final List<String> failedUploads = [];

        if (evidenceCount > 0) {
          int current = 0;
          
          // Upload Attachments
          for (final attachment in _attachments) {
            current++;
            setState(() => _loadingMessage = 'Kohereza inyandiko ($current/$evidenceCount)...');
            final uploadRes = await caseService.uploadEvidence(caseId, attachment.path);
            if (!uploadRes.isSuccess) {
              failedUploads.add(attachment.path.split('/').last);
              debugPrint('Failed to upload ${attachment.path}: ${uploadRes.error}');
            }
          }
          
          // Upload Audio
          if (_audioPath != null) {
            current++;
            setState(() => _loadingMessage = 'Kohereza amajwi ($current/$evidenceCount)...');
            final uploadRes = await caseService.uploadEvidence(caseId, _audioPath!);
             if (!uploadRes.isSuccess) {
              failedUploads.add('Ijwi (Voice Note)');
              debugPrint('Failed to upload audio: ${uploadRes.error}');
            }
          }
        }
        
        // 3. Success (with warning if uploads failed)
        if (failedUploads.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Ikibazo cyakiriwe, ariko ibimenyetso bimwe byanze: ${failedUploads.join(', ')}'), 
               backgroundColor: Colors.orange,
               duration: const Duration(seconds: 5),
             )
           );
            _showSuccessDialog(response.data!); // Still show success as case is created
        } else {
             _showSuccessDialog(response.data!); 
        }

      } else { 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? 'Byanze'), backgroundColor: ImboniColors.error)); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ImboniColors.error));
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  void _showSuccessDialog(CaseModel caseData) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.check_circle, color: ImboniColors.success), SizedBox(width: 8), Text('Byagenze neza!')]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ikibazo cyawe cyoherejwe neza.'),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nimero yo gukurikirana:'),
          const SizedBox(height: 4),
          SelectableText(caseData.caseReference, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ImboniColors.primary)),
        ])),
        const SizedBox(height: 12),
        const Text('Bika iyi nimero kugirango ukurikirane ikibazo cyawe.', style: TextStyle(fontSize: 12)),
      ]),
      actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); }, child: const Text('Sawa'))],
    ));
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _UrgencyChip({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: isSelected ? color.withAlpha(38) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? color : Theme.of(context).colorScheme.outline, width: isSelected ? 2 : 1)),
    child: Text(label, style: TextStyle(color: isSelected ? color : null, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
  )));
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
