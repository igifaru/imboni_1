import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/category_selector.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/widgets/case_submission/media_attachment_widget.dart';
import '../../shared/widgets/case_submission/audio_recorder_widget.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/case_service.dart';
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
      message: _loadingMessage ?? l10n.processing,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(children: [
        _buildStepItem(0, l10n.problem, theme),
        Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: _currentStep >= 1 ? ImboniColors.primary : theme.colorScheme.surfaceContainerHighest)),
        _buildStepItem(1, l10n.location, theme),
        Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: _currentStep >= 2 ? ImboniColors.primary : theme.colorScheme.surfaceContainerHighest)),
        _buildStepItem(2, l10n.evidence, theme),
      ]),
    );
  }

  Widget _buildStepItem(int step, String label, ThemeData theme) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? ImboniColors.primary : Colors.transparent,
          border: Border.all(color: isActive ? ImboniColors.primary : theme.colorScheme.outline, width: 2),
          boxShadow: isActive ? [BoxShadow(color: ImboniColors.primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)] : null,
        ),
        child: Center(
          child: isActive 
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text('${step + 1}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: theme.textTheme.labelSmall?.copyWith(
        color: isCurrent ? ImboniColors.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
      )),
    ]);
  }

  Widget _buildStep1(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.isEmergency) _buildEmergencyBanner(theme, l10n),
            _buildAnonymousToggle(l10n, theme),
            const SizedBox(height: 32),
            
            Text(l10n.selectCategory, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CategorySelector(selectedCategory: _selectedCategory, onCategorySelected: (cat) => setState(() => _selectedCategory = cat)),
            const SizedBox(height: 32),
            
            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: ImboniColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit_note, color: ImboniColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.caseTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 24),
                
                if (!widget.isEmergency) ...[
                  Text(l10n.urgencyTitle, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  _buildUrgencySelector(theme, l10n),
                  const SizedBox(height: 24),
                ],
                
                Text(l10n.caseTitle, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: l10n.caseTitleHint,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (v) => (v == null || v.length < 5) ? l10n.caseTitleError : null,
                ),
                const SizedBox(height: 24),
                
                Text(l10n.describeIssue, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: l10n.descHint,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 5,
                  validator: (v) => (v == null || v.length < 20) ? l10n.descError : null,
                ),
              ]),
            ),
            const SizedBox(height: 40),
            
            Center(
              child: SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedCategory != null) {
                      setState(() => _currentStep = 1);
                    } else if (_selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectCategoryError), backgroundColor: ImboniColors.error));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ImboniColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: ImboniColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(l10n.continueBtn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Step 2 and 3 can reuse similar polish later ...

  Widget _buildEmergencyBanner(ThemeData theme, AppLocalizations l10n) => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ImboniColors.urgencyEmergency.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ImboniColors.urgencyEmergency.withValues(alpha: 0.5)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: ImboniColors.urgencyEmergency, shape: BoxShape.circle),
        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 16),
      Expanded(child: Text(l10n.emergencyWarning, style: const TextStyle(color: ImboniColors.urgencyEmergency, fontWeight: FontWeight.bold))),
    ]),
  );

  Widget _buildAnonymousToggle(AppLocalizations l10n, ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
    ),
    child: SwitchListTile(
      title: Text(l10n.submitAnonymously, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(l10n.anonymousExplanation, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      value: _isAnonymous,
      onChanged: (v) => setState(() => _isAnonymous = v),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isAnonymous ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_isAnonymous ? Icons.visibility_off : Icons.visibility, color: _isAnonymous ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  Widget _buildUrgencySelector(ThemeData theme, AppLocalizations l10n) => Row(children: [
    _UrgencyChip(label: l10n.urgencyNormal, icon: Icons.info_outline, isSelected: _urgency == 'NORMAL', color: ImboniColors.urgencyNormal, onTap: () => setState(() => _urgency = 'NORMAL')),
    const SizedBox(width: 12),
    _UrgencyChip(label: l10n.urgencyHigh, icon: Icons.priority_high, isSelected: _urgency == 'HIGH', color: ImboniColors.urgencyHigh, onTap: () => setState(() => _urgency = 'HIGH')),
    const SizedBox(width: 12),
    _UrgencyChip(label: l10n.urgencyEmergency, icon: Icons.warning_amber, isSelected: _urgency == 'EMERGENCY', color: ImboniColors.urgencyEmergency, onTap: () => setState(() => _urgency = 'EMERGENCY')),
  ]);
  Widget _buildStep2(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ImboniColors.info.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ImboniColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: ImboniColors.info),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.selectLocPrompt, style: theme.textTheme.bodyMedium)),
              ]),
            ),
            const SizedBox(height: 24),

            // Location Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: LocationSelector(
                initialSelection: _location,
                onLocationChanged: (loc) => setState(() => _location = loc),
              ),
            ),
            const SizedBox(height: 24),

            if (_location.isComplete)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ImboniColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ImboniColors.success.withAlpha(75)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.check_circle, color: ImboniColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.confirmLoc, style: theme.textTheme.labelLarge?.copyWith(color: ImboniColors.success)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_location.fullAddress, style: theme.textTheme.bodyMedium),
                ]),
              ),
            const SizedBox(height: 40),

            // Buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 0),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: theme.colorScheme.outline),
                          ),
                          child: Text(l10n.backBtn, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _location.isComplete ? () => setState(() => _currentStep = 2) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ImboniColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: ImboniColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            l10n.continueBtn, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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

  Widget _buildStep3(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
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

            // Media Card
             Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(l10n.evidence, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   MediaAttachmentWidget(
                    attachments: _attachments,
                    onChanged: (attachments) => setState(() => _attachments = attachments),
                  ),
                  const SizedBox(height: 24),
                   AudioRecorderWidget(
                    audioPath: _audioPath,
                    onRecordingComplete: (path) => setState(() => _audioPath = path),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.summary, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SummaryRow(icon: Icons.category_outlined, label: l10n.selectCategory, value: _selectedCategory ?? '-'),
                _SummaryRow(icon: Icons.location_on_outlined, label: l10n.location, value: _location.village ?? '-'),
                _SummaryRow(icon: Icons.attach_file, label: l10n.evidence, value: '${_attachments.length + (_audioPath != null ? 1 : 0)}'),
              ]),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
             Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 1),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: theme.colorScheme.outline),
                          ),
                          child: Text(l10n.backBtn, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _submitCase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ImboniColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: ImboniColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                            l10n.submitCase, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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



  Future<void> _submitCase() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.processing;
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
            setState(() => _loadingMessage = '${l10n.uploadingDocs} ($current/$evidenceCount)...');
            final uploadRes = await caseService.uploadEvidence(caseId, attachment.path);
            if (!uploadRes.isSuccess) {
              failedUploads.add(attachment.path.split('/').last);
              debugPrint('Failed to upload ${attachment.path}: ${uploadRes.error}');
            }
          }
          
          // Upload Audio
          if (_audioPath != null) {
            current++;
            setState(() => _loadingMessage = '${l10n.uploadingAudio} ($current/$evidenceCount)...');
            final uploadRes = await caseService.uploadEvidence(caseId, _audioPath!);
             if (!uploadRes.isSuccess) {
              failedUploads.add('Ijwi');
              debugPrint('Failed to upload audio: ${uploadRes.error}');
            }
          }
        }
        
        // 3. Success (with warning if uploads failed)
        if (failedUploads.isNotEmpty) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('${l10n.partialSuccess}: ${failedUploads.join(', ')}'), 
               backgroundColor: Colors.orange,
               duration: const Duration(seconds: 5),
             )
           );
            _showSuccessDialog(response.data!, l10n);
           }
        } else {
             _showSuccessDialog(response.data!, l10n); 
        }

      } else { 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? l10n.failed), backgroundColor: ImboniColors.error)); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.failed}: $e'), backgroundColor: ImboniColors.error));
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  void _showSuccessDialog(CaseModel caseData, AppLocalizations l10n) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Row(children: [const Icon(Icons.check_circle, color: ImboniColors.success), const SizedBox(width: 8), Text(l10n.successTitle)]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.successMessage),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.trackingNumber),
          const SizedBox(height: 4),
          SelectableText(caseData.caseReference, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ImboniColors.primary)),
        ])),
        const SizedBox(height: 12),
        Text(l10n.saveTrackingHint, style: const TextStyle(fontSize: 12)),
      ]),
      actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); }, child: Text(l10n.ok))],
    ));
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final IconData icon; // Added icon
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _UrgencyChip({required this.label, required this.icon, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isSelected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: isSelected ? 2 : 1)
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isSelected ? color : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
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
