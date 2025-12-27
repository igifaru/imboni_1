import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Case Card Widget - Reusable case display component
class CaseCard extends StatelessWidget {
  final String caseReference;
  final String title;
  final String category;
  final String status;
  final String urgency;
  final String currentLevel;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const CaseCard({
    super.key,
    required this.caseReference,
    required this.title,
    required this.category,
    required this.status,
    required this.urgency,
    required this.currentLevel,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = ImboniColors.getStatusColor(status);
    final categoryColor = ImboniColors.getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(caseReference, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  StatusBadge(status: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(context, label: category, color: categoryColor, icon: _getCategoryIcon(category)),
                  if (urgency != 'NORMAL') _buildChip(context, label: urgency, color: ImboniColors.getUrgencyColor(urgency), icon: Icons.priority_high),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(currentLevel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                  Text(_formatDate(createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return Icons.gavel;
      case 'HEALTH': return Icons.local_hospital;
      case 'LAND': return Icons.landscape;
      case 'INFRASTRUCTURE': return Icons.construction;
      case 'SECURITY': return Icons.security;
      case 'SOCIAL': return Icons.people;
      case 'EDUCATION': return Icons.school;
      default: return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return diff.inHours == 0 ? '${diff.inMinutes}m ago' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(75))),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
