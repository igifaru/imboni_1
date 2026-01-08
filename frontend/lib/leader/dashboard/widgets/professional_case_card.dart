import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/widgets/countdown_timer.dart';
import 'package:intl/intl.dart';

class ProfessionalCaseCard extends StatelessWidget {
  final CaseModel caseData;
  final VoidCallback onTap;

  const ProfessionalCaseCard({
    super.key,
    required this.caseData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = ImboniColors.getStatusColor(caseData.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withAlpha(isDark ? 50 : 30)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Title + Status + Countdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              caseData.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Countdown Timer (if deadline exists)
                          if (caseData.deadline != null) ...[
                            CountdownChip(
                              deadline: caseData.deadline!,
                              prefix: l10n.escalationIn,
                            ),
                            const SizedBox(width: 6),
                          ],
                          _buildStatusChip(caseData.status, statusColor),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Details Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 1: Case ID
                          Expanded(
                            flex: 2,
                            child: _buildDetailItem(
                              context: context,
                              label: 'ID', // Keeping generic or use localized ID if needed
                              value: '#${caseData.caseReference}',
                              valueStyle: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                            ),
                          ),
                          // Column 2: Category
                          Expanded(
                            flex: 3,
                            child: _buildDetailItem(
                              context: context,
                              label: l10n.categoryLabel,
                              value: caseData.category,
                              icon: Icons.category_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 3: Location
                          Expanded(
                            flex: 2,
                            child: _buildDetailItem(
                              context: context,
                              label: l10n.location,
                              value: caseData.locationName ?? 'Unknown',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          // Column 4: Submitted
                          Expanded(
                            flex: 3,
                            child: _buildDetailItem(
                              context: context,
                              label: l10n.submitted,
                              value: _formatTimeAgo(caseData.createdAt),
                              icon: Icons.access_time,
                            ),
                          ),
                        ],
                      ),

                      // Assigned Leader Row (if assigned to another leader)
                      if (caseData.assignedLeaderName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                context: context,
                                label: l10n.assignedTo,
                                value: caseData.assignedLeaderName!,
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Spacer(),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 8),

                      // Footer Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: onTap,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.colorScheme.primary.withAlpha(100)),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                                child: Text(l10n.viewDetails, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
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

  Widget _buildStatusChip(String status, Color color) {
    String label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withAlpha(255), // Full opacity for text
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailItem({required BuildContext context, required String label, required String value, IconData? icon, TextStyle? valueStyle}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                style: valueStyle ?? TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(date);
  }
}
