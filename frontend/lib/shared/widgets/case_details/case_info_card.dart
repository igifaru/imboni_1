import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/utils/case_helper.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'case_detail_card.dart';
import 'package:intl/intl.dart';

class CaseInfoCard extends StatelessWidget {
  final CaseModel caseModel;

  const CaseInfoCard({super.key, required this.caseModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    final subTextColor = isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[700]!;

    return CaseDetailCard(
      title: l10n.importantInfo,
      icon: Icons.info_outline,
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(Icons.location_on_outlined, l10n.location, caseModel.locationPath ?? caseModel.locationName ?? 'Unknown', isDark, subTextColor, textColor),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.layers_outlined, l10n.level, CaseHelper.getLevelLabel(l10n, caseModel.currentLevel), isDark, subTextColor, textColor),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(Icons.calendar_today_outlined, l10n.date, _formatDate(caseModel.createdAt), isDark, subTextColor, textColor),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.access_time, l10n.time, _formatTime(caseModel.createdAt), isDark, subTextColor, textColor),
                  ],
                ),
              ),
            ],
          ),
          
          if (caseModel.deadline != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ImboniColors.warning.withAlpha(isDark ? 50 : 25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ImboniColors.warning.withAlpha(75)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: ImboniColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.deadline}: ${_formatDate(caseModel.deadline!)}',
                    style: const TextStyle(
                      color: ImboniColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (caseModel.assignedLeaderName != null || (caseModel.resolution != null && caseModel.resolution!.resolvedBy.isNotEmpty)) ...[
             const SizedBox(height: 16),
             _buildInfoItem(
               Icons.person_outline, 
               caseModel.status == 'RESOLVED' || caseModel.status == 'CLOSED' ? "Resolved By" : l10n.assignedTo, 
               caseModel.status == 'RESOLVED' || caseModel.status == 'CLOSED' 
                   ? (caseModel.resolution?.resolvedByName ?? caseModel.resolution?.resolvedBy ?? 'Unknown') 
                   : (caseModel.assignedLeaderName ?? 'Unknown'), 
               isDark, subTextColor, textColor
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isDark, Color subTextColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subTextColor)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);
}
