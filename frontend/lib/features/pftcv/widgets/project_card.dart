/// Project Card Widget for PFTCV
import 'package:flutter/material.dart';
import '../models/pftcv_models.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sector icon and risk indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(100),
                border: Border(left: BorderSide(color: project.riskLevel.color, width: 4)),
              ),
              child: Row(
                children: [
                  Icon(project.sector.icon, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(project.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  _RiskBadge(riskLevel: project.riskLevel),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code & Location
                    Row(
                      children: [
                        Icon(Icons.tag, size: 14, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(project.projectCode, style: theme.textTheme.bodySmall),
                        const Spacer(),
                        if (project.locationName != null) ...[
                          Icon(Icons.location_on, size: 14, color: colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(project.locationName!, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Sector chip
                    Chip(
                      label: Text(project.sector.label, style: const TextStyle(fontSize: 11)),
                      avatar: Icon(project.sector.icon, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.only(right: 6),
                    ),
                    const Spacer(),
                    // Budget progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Imari', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
                            Text(project.budgetFormatted, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: project.releaseRatio.clamp(0.0, 1.0),
                          backgroundColor: colorScheme.surfaceContainerHigh,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Yatanzwe: ${project.releasedFormatted}', style: theme.textTheme.bodySmall),
                            Text('${(project.releaseRatio * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer - Status and Verifications
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerLowest),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(status: project.status),
                  Row(
                    children: [
                      Icon(Icons.verified_user, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${project.verificationCount}', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Text('${project.verifiedPercentage}%', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  const _RiskBadge({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: riskLevel.color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
      child: Text(riskLevel.label, style: TextStyle(fontSize: 10, color: riskLevel.color, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: status.color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
      child: Text(status.label, style: TextStyle(fontSize: 11, color: status.color)),
    );
  }
}
