import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'case_detail_card.dart';

class CaseDescriptionCard extends StatelessWidget {
  final CaseModel caseModel;

  const CaseDescriptionCard({super.key, required this.caseModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final subTextColor = isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[700]!;

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
          caseModel.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            fontSize: 14,
            color: subTextColor,
          ),
        ),
      ),
    );
  }
}
