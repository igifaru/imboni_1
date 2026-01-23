import 'package:flutter/material.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/services/case_service.dart';
import 'package:imboni/shared/theme/colors.dart';

class EditCaseDialog extends StatefulWidget {
  final CaseModel caseModel;

  const EditCaseDialog({super.key, required this.caseModel});

  @override
  State<EditCaseDialog> createState() => _EditCaseDialogState();
}

class _EditCaseDialogState extends State<EditCaseDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedUrgency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.caseModel.title);
    _descriptionController = TextEditingController(text: widget.caseModel.description);
    _selectedUrgency = widget.caseModel.urgency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final newTitle = _titleController.text.trim();
    final newDesc = _descriptionController.text.trim();

    // Validate
    if (newTitle.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.caseTitleError), backgroundColor: ImboniColors.error),
      );
      return;
    }
    if (newDesc.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.descError), backgroundColor: ImboniColors.error),
      );
      return;
    }

    // Check if anything changed
    final titleChanged = newTitle != widget.caseModel.title;
    final descChanged = newDesc != widget.caseModel.description;
    final urgencyChanged = _selectedUrgency != widget.caseModel.urgency;

    if (!titleChanged && !descChanged && !urgencyChanged) {
      Navigator.pop(context); // Nothing changed
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await CaseService.instance.updateCase(
        widget.caseModel.id,
        title: titleChanged ? newTitle : null,
        description: descChanged ? newDesc : null,
        urgency: urgencyChanged ? _selectedUrgency : null,
      );

      if (mounted) {
        if (response.isSuccess && response.data != null) {
          Navigator.pop(context, response.data);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? l10n.cannotEditCase),
              backgroundColor: ImboniColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: ImboniColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ImboniColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: ImboniColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.editCase,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      Text(
                        l10n.caseTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: l10n.caseTitleHint,
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.withAlpha(25),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description field
                      Text(
                        l10n.description,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: l10n.descHint,
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.withAlpha(25),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Urgency selector
                      Text(
                        l10n.urgencyTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildUrgencyOption('NORMAL', l10n.urgencyNormal, Icons.info_outline, 
                              ImboniColors.urgencyNormal),
                          const SizedBox(width: 12),
                          _buildUrgencyOption('HIGH', l10n.urgencyHigh, Icons.priority_high, 
                              ImboniColors.urgencyHigh),
                          const SizedBox(width: 12),
                          _buildUrgencyOption('EMERGENCY', l10n.urgencyEmergency, Icons.warning_amber, 
                              ImboniColors.urgencyEmergency),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ImboniColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(l10n.saveChanges),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyOption(String value, String label, IconData icon, Color color) {
    final isSelected = value == _selectedUrgency;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedUrgency = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(38) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline.withAlpha(75),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
