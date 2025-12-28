import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../admin/services/admin_service.dart';
import '../../../shared/models/models.dart';

/// Widget to display cases broken down by sub-jurisdiction (e.g., Districts in a Province)
class DistrictCasesWidget extends StatefulWidget {
  final List<CaseModel> cases;
  final bool isDashboardLoading;

  const DistrictCasesWidget({
    super.key,
    required this.cases,
    this.isDashboardLoading = false,
  });

  @override
  State<DistrictCasesWidget> createState() => _DistrictCasesWidgetState();
}

class _DistrictCasesWidgetState extends State<DistrictCasesWidget> {
  bool _isLoadingJurisdiction = true;
  String? _error;
  String? _jurisdictionName;
  String _targetLevel = 'District'; // Default
  String _currentLevel = 'Province'; // Default
  List<String> _subUnits = [];
  Map<String, int> _subUnitCounts = {};

  @override
  void initState() {
    super.initState();
    _loadJurisdiction();
  }

  Future<void> _loadJurisdiction() async {
    if (!mounted) return;
    setState(() {
      _isLoadingJurisdiction = true;
      _error = null;
    });

    try {
      final data = await adminService.getMyJurisdiction();
      
      if (mounted) {
        if (data != null && data['success'] == true) {
          final level = data['level'] ?? 'PROVINCE';
          final targetLevel = data['targetLevel'] ?? _getNextLevel(level);

          setState(() {
            _currentLevel = _formatLevel(level);
            _targetLevel = _formatLevel(targetLevel);
            _jurisdictionName = data['jurisdiction'] ?? 'Unknown Area';
            
            final rawChildren = data['children'] ?? [];
            _subUnits = List<String>.from(rawChildren);

            // Extract nested counts
            final dynamic jurData = data['data'];
            _subUnitCounts = {};
            if (jurData is Map<String, dynamic>) {
              for (final child in _subUnits) {
                final subData = jurData[child];
                if (subData is Map || subData is List) {
                  _subUnitCounts[child] = (subData as dynamic).length;
                }
              }
            }
            
            _isLoadingJurisdiction = false;
          });
        } else {
          setState(() {
            _error = data?['error'] ?? 'Failed to load jurisdiction';
            _isLoadingJurisdiction = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoadingJurisdiction = false;
        });
      }
    }
  }

  /// Helper to guess next level if backend doesn't provide targetLevel
  String _getNextLevel(String current) {
    switch (current) {
      case 'ADMIN': return 'PROVINCE';
      case 'PROVINCE': return 'DISTRICT';
      case 'DISTRICT': return 'SECTOR';
      case 'SECTOR': return 'CELL';
      case 'CELL': return 'VILLAGE';
      default: return 'UNIT';
    }
  }

  Map<String, Map<String, int>> _getCasesBySubUnit() {
    final Map<String, Map<String, int>> result = {};
    for (final unit in _subUnits) {
      result[unit] = {'open': 0, 'resolved': 0, 'total': 0};
    }
    
    if (_subUnits.isEmpty) return result;

    for (final c in widget.cases) {
      for (final unit in _subUnits) {
        // Simple matching logic - implies case data contains unit name text
        if (c.title.toLowerCase().contains(unit.toLowerCase()) || 
            c.caseReference.toLowerCase().contains(unit.toLowerCase()) ||
            c.description.toLowerCase().contains(unit.toLowerCase())) {
          
          result[unit]!['total'] = result[unit]!['total']! + 1;
          if (c.status == 'RESOLVED' || c.status == 'CLOSED') {
            result[unit]!['resolved'] = result[unit]!['resolved']! + 1;
          } else {
            result[unit]!['open'] = result[unit]!['open']! + 1;
          }
          break; // Count once per unit match
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // For Village/Cell leaders with no children, we don't show the list
    final bool isLeafNode = _subUnits.isEmpty && !_isLoadingJurisdiction && _error == null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark),
            const SizedBox(height: 16),
            if (_isLoadingJurisdiction)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              _buildErrorState(theme)
            else if (isLeafNode)
               _buildLeafNodeState(theme)
            else
              _buildJurisdictionList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    // If it's a leaf node, don't say "Cases by X", say "My Unit Cases"
    final title = _subUnits.isNotEmpty 
        ? 'Cases by $_targetLevel' 
        : 'Overview';

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_jurisdictionName != null)
                  Text(
                    _jurisdictionName!,
                    style: theme.textTheme.bodySmall?.copyWith(color: ImboniColors.primary, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ],
        ),
        if (!widget.isDashboardLoading || widget.cases.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ImboniColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.cases.length} Total',
              style: const TextStyle(color: ImboniColors.info, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          TextButton(onPressed: _loadJurisdiction, child: const Text('Retry')),
        ],
      ),
    );
  }

  // Shown for Village/Lowest level leaders who have no sub-jurisdictions
  Widget _buildLeafNodeState(ThemeData theme) {
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
              'You are viewing the lowest administrative level.\nAll cases are directly under your jurisdiction.', 
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJurisdictionList(ThemeData theme) {
    final caseData = _getCasesBySubUnit();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subUnits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final unit = _subUnits[index];
        final stats = caseData[unit] ?? {'open': 0, 'resolved': 0, 'total': 0};
        // For sub-unit count, ideally we'd show the next level down count (e.g. Sectors in District)
        // But for generic, we just use the count we extracted
        final subCount = _subUnitCounts[unit] ?? 0;
        
        return _buildUnitCard(context, unit, stats['open']!, stats['resolved']!, stats['total']!, subCount);
      },
    );
  }

  Widget _buildUnitCard(BuildContext context, String name, int open, int resolved, int total, int subCount) {
    final theme = Theme.of(context);
    Color statusColor = total == 0 ? theme.disabledColor : (open == 0 ? Colors.green : (open < 3 ? Colors.orange : Colors.red));

    return Container(
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
                    Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (subCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                         // Display specific sub-unit name (e.g., 17 Sectors)
                        '($subCount ${_formatSubUnitName(_targetLevel, subCount)})',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha(150), fontSize: 10),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat('Open', open, Colors.orange),
                    const SizedBox(width: 12),
                    _buildMiniStat('Resolved', resolved, Colors.green),
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
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$count $label', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  String _formatLevel(String level) {
    if (level.isEmpty) return 'Unit';
    return level[0].toUpperCase() + level.substring(1).toLowerCase();
  }

  String _formatSubUnitName(String parentLevel, int count) {
    String singular;
    // parentLevel is like "District" (from _formatLevel)
    switch (parentLevel.toUpperCase()) {
      case 'PROVINCE': singular = 'District'; break;
      case 'DISTRICT': singular = 'Sector'; break;
      case 'SECTOR': singular = 'Cell'; break;
      case 'CELL': singular = 'Village'; break;
      case 'VILLAGE': singular = 'Household'; break;
      default: singular = 'Sub-unit';
    }
    return count == 1 ? singular : '${singular}s';
  }
}
