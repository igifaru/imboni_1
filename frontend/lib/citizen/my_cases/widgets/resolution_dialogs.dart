import 'package:flutter/material.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/theme/colors.dart';

export 'package:imboni/shared/widgets/dialogs/confirmation_dialog.dart';

class DisputeResolutionDialog extends StatefulWidget {
  const DisputeResolutionDialog({super.key});

  @override
  State<DisputeResolutionDialog> createState() => _DisputeResolutionDialogState();
}

class _DisputeResolutionDialogState extends State<DisputeResolutionDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dispute,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.reasonForDispute,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: ImboniColors.warning, width: 2),
                  ),
                ),
                maxLines: 4,
                onChanged: (v) => _reason = v,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () => Navigator.pop(context, _reason),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ImboniColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(l10n.submit),
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
}
