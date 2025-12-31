import 'package:flutter/material.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/models/models.dart';

/// Widget to display cases broken down by sub-jurisdiction (e.g., Districts in a Province)
class DistrictCasesWidget extends StatelessWidget {
  final List<SubUnitPerformance> subUnitStats;
  final bool isDashboardLoading;
  final String currentLevel; 
  final Function(String unitId, String unitName)? onUnitSelected;
  final PerformanceMetrics? currentMetrics; // New: Pass current level metrics

  const DistrictCasesWidget({
    super.key,
    required this.subUnitStats,
    this.isDashboardLoading = false,
    this.currentLevel = '',
    this.onUnitSelected,
    this.currentMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bool isLeafNode = subUnitStats.isEmpty && !isDashboardLoading;
    String targetLevel = _guessTargetLevel(currentLevel);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark, targetLevel),
            const SizedBox(height: 16),
            if (isDashboardLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (isLeafNode)
               _buildLeafNodeState(context, theme)
            else
              _buildJurisdictionList(context, targetLevel),
          ],
        ),
      ),
    );
  }

  String _guessTargetLevel(String current) {
    switch (current.toUpperCase()) {
      case 'ADMIN': return 'Province';
      case 'PROVINCE': return 'District';
      case 'DISTRICT': return 'Sector';
      case 'SECTOR': return 'Cell';
      case 'CELL': return 'Village';
      default: return 'Sub-unit';
    }
  }

  Widget _buildHeader(ThemeData theme, bool isDark, String targetLevel) {
    // If it's a leaf node, don't say "Cases by X", say "My Unit Cases"
    final title = (subUnitStats.isNotEmpty) 
        ? 'Cases by $targetLevel' 
        : (currentMetrics != null ? 'Current Location Overview' : 'Overview');

    // Use currentMetrics total if available at leaf node, otherwise sum sub-units
    final totalCases = subUnitStats.isNotEmpty 
        ? subUnitStats.fold(0, (sum, item) => sum + item.totalCases)
        : (currentMetrics?.totalCases ?? 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ImboniColors.primary.withAlpha(isDark ? 50 : 25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cases_outlined, color: ImboniColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        if (!isDashboardLoading && totalCases > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ImboniColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalCases Total',
              style: const TextStyle(color: ImboniColors.info, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildLeafNodeState(BuildContext context, ThemeData theme) {
    if (currentMetrics != null && currentMetrics!.totalCases > 0) {
       // Show Summary Stats for Leaf Node
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: theme.colorScheme.surfaceContainerLow,
           borderRadius: BorderRadius.circular(12),
         ),
         child: Column(
           children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
               _buildBigStat(context, 'Open', currentMetrics!.openCases, Colors.orange),
               _buildBigStat(context, 'Active', currentMetrics!.activeCases, Colors.blue),
             ]),
             const SizedBox(height: 16),
             Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
               _buildBigStat(context, 'Resolved', currentMetrics!.resolvedCases, Colors.green),
               _buildBigStat(context, 'Escalated', currentMetrics!.escalatedCases, ImboniColors.error),
             ]),
           ],
         ),
       );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.home_work_outlined, size: 48, color: theme.colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'No sub-units to display', 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              'You are viewing the lowest administrative level.', 
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStat(BuildContext context, String label, int count, Color color) {
    return Column(children: [
      Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
    ]);
  }

  Widget _buildJurisdictionList(BuildContext context, String targetLevel) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subUnitStats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stat = subUnitStats[index];
        return _buildUnitCard(context, stat, targetLevel);
      },
    );
  }

  Widget _buildUnitCard(BuildContext context, SubUnitPerformance stat, String targetLevel) {
    final theme = Theme.of(context);
    final total = stat.totalCases;
    final open = stat.openCases;
    final resolved = stat.resolvedCases;
    final escalated = stat.escalatedCases;

    Color statusColor = total == 0 ? theme.disabledColor : (open == 0 ? Colors.green : (open < 3 ? Colors.orange : Colors.red));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onUnitSelected?.call(stat.unitId, stat.unitName),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.location_city, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(stat.unitName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 16, color: theme.disabledColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildMiniStat(context, 'Open', open, Colors.orange),
                          _buildMiniStat(context, 'Active', stat.activeCases, Colors.blue), // New: Active
                          _buildMiniStat(context, 'Resolved', resolved, Colors.green),
                          _buildMiniStat(context, 'Escalated', escalated, ImboniColors.error), // Always show escalated
                        ],
                      ),
                    ],
                  ),
                ),
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                    child: Text('$total', style: const TextStyle(color: ImboniColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$count $label', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
