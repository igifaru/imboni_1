import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/constants/rwanda_provinces.dart';

class ProvinceStatsWidget extends StatefulWidget {
  const ProvinceStatsWidget({super.key});

  @override
  State<ProvinceStatsWidget> createState() => _ProvinceStatsWidgetState();
}

class _ProvinceStatsWidgetState extends State<ProvinceStatsWidget> {
  Map<String, Map<String, int>> _statsByProvince = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await adminService.getUserStatsByProvince();
      if (mounted) {
        // Convert list to map for easy lookup
        final Map<String, Map<String, int>> statsMap = {};
        for (final stat in stats) {
          final province = stat['province'] as String?;
          if (province != null) {
            statsMap[province] = {
              'active': stat['active'] as int? ?? 0,
              'inactive': stat['inactive'] as int? ?? 0,
            };
          }
        }
        setState(() {
          _statsByProvince = statsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load statistics';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                      child: const Icon(Icons.map_outlined, color: ImboniColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Users by Province',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadStats();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)))
            else
              Column(
                children: rwandaProvinces.map((province) {
                  final code = province.code;
                  final name = province.name;
                  final stats = _statsByProvince[code] ?? {'active': 0, 'inactive': 0};
                  return _buildProvinceCard(context, name, stats['active']!, stats['inactive']!);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceCard(BuildContext context, String provinceName, int active, int inactive) {
    final theme = Theme.of(context);
    final total = active + inactive;
    final activePercent = total > 0 ? active / total : 0.0;

    // Color based on activity
    Color statusColor;
    if (total == 0) {
      statusColor = Colors.grey;
    } else if (activePercent > 0.8) {
      statusColor = Colors.green;
    } else if (activePercent > 0.5) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Province Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_city, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Province Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provinceName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat(context, 'Active', active, Colors.green),
                    const SizedBox(width: 16),
                    _buildMiniStat(context, 'Inactive', inactive, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          // Total Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ImboniColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                color: ImboniColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
