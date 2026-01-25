import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/utils/case_helper.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/widgets/countdown_timer.dart';
import 'case_detail_card.dart';

class CaseHeaderCard extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback? onExpired;

  const CaseHeaderCard({super.key, required this.caseModel, this.onExpired});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;

    final statusColor = ImboniColors.getStatusColor(caseModel.status);
    final urgencyColor = ImboniColors.getUrgencyColor(caseModel.urgency);
    final categoryColor = ImboniColors.getCategoryColor(caseModel.category);

    return CaseDetailCard(
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildBadge(CaseHelper.getStatusLabel(l10n, caseModel.status), statusColor, Icons.circle, isDark),
              _buildBadge(CaseHelper.getCategoryLabel(l10n, caseModel.category), categoryColor, CaseHelper.getCategoryIcon(caseModel.category), isDark),
              _buildBadge(CaseHelper.getUrgencyLabel(l10n, caseModel.urgency), urgencyColor, Icons.flag, isDark),
              
              if (caseModel.deadline != null)
                CountdownTimer(
                  deadline: caseModel.deadline!,
                  showIcon: true,
                  onExpired: onExpired,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            caseModel.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          
          // Case Reference
          Row(
            children: [
              Icon(Icons.tag, size: 16, color: isDark ? Colors.white54 : Colors.grey),
              const SizedBox(width: 6),
              Text(
                caseModel.caseReference,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 65 : 30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
