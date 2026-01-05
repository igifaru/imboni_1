/// Project Card Widget - Polished & Responsive
import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../models/pftcv_models.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 4,
      shadowColor: Colors.black.withAlpha(20),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check if we have enough width for a 2-column internal layout
            // This is useful if the grid item is wide or if used in a list view
            final isWide = constraints.maxWidth > 500;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(theme, colorScheme, isDark),

                // Body content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildInfoColumn(theme, colorScheme)),
                              const SizedBox(width: 16),
                              Container(width: 1, color: colorScheme.outlineVariant.withAlpha(50)),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildStatsColumn(theme, colorScheme)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoColumn(theme, colorScheme),
                              const Spacer(),
                              const Divider(height: 24),
                              _buildStatsColumn(theme, colorScheme),
                            ],
                          ),
                  ),
                ),
                
                // Footer
                _buildFooter(theme, colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ImboniColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(project.sector.icon, color: ImboniColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  project.projectCode,
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(150), letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: project.status),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (project.locationName != null) ...[
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: colorScheme.onSurface.withAlpha(180)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  project.locationName!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Imari', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(150))),
                const SizedBox(height: 2),
                Text(project.budgetFormatted, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
             Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Yatanzwe', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(150))),
                const SizedBox(height: 2),
                Text(
                  project.releasedFormatted,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsColumn(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Igice cyatanzwe', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(150))),
            Text(
              '${(project.releaseRatio * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: project.releaseRatio.clamp(0.0, 1.0),
            backgroundColor: colorScheme.surfaceContainerHighest,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: colorScheme.surfaceContainer),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RiskBadge(riskLevel: project.riskLevel),
          Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${project.verifiedPercentage}% Verified',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
            ],
          ),
        ],
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
      decoration: BoxDecoration(
        color: riskLevel.color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: riskLevel.color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: riskLevel.color),
          const SizedBox(width: 4),
          Text(
            riskLevel.label,
            style: TextStyle(fontSize: 10, color: riskLevel.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: status.color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, color: status.color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
