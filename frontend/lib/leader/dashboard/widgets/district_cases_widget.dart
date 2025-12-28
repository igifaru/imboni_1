import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../admin/services/admin_service.dart';
import '../../../shared/models/models.dart';

/// Widget to display districts for a Province Leader with case statistics
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
  String? _provinceName;
  List<String> _districts = [];
  Map<String, int> _districtSectors = {};

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
      debugPrint('[DistrictCasesWidget] Fetching jurisdiction...');
      final data = await adminService.getMyJurisdiction();
      debugPrint('[DistrictCasesWidget] Data received: ${data != null}');
      
      if (mounted) {
        if (data != null && data['success'] == true) {
          setState(() {
            _provinceName = data['assignment']?['province'] ?? 'Unknown';
            _districts = List<String>.from(data['districts'] ?? []);
            
            // Extract sector counts from jurisdiction data
            final jurData = data['data'] as Map<String, dynamic>?;
            _districtSectors = {};
            if (jurData != null) {
              for (final district in _districts) {
                if (jurData[district] is Map) {
                  _districtSectors[district] = (jurData[district] as Map).length;
                }
              }
            }
            
            _isLoadingJurisdiction = false;
          });
          debugPrint('[DistrictCasesWidget] Loaded ${_districts.length} districts for $_provinceName');
        } else {
          setState(() {
            _error = 'Failed to load jurisdiction data';
            _isLoadingJurisdiction = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[DistrictCasesWidget] Error: $e');
      if (mounted) {
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoadingJurisdiction = false;
        });
      }
    }
  }

  /// Get case counts per district optimized
  Map<String, Map<String, int>> _getCasesByDistrict() {
    final Map<String, Map<String, int>> result = {};
    
    // Initialize
    for (final district in _districts) {
      result[district] = {'open': 0, 'resolved': 0, 'total': 0};
    }
    
    if (_districts.isEmpty) return result;

    // Count cases per district
    for (final c in widget.cases) {
      bool matched = false;
      for (final district in _districts) {
        // Match by title, reference, or description
        if (c.title.toLowerCase().contains(district.toLowerCase()) || 
            c.caseReference.toLowerCase().contains(district.toLowerCase()) ||
            c.description.toLowerCase().contains(district.toLowerCase())) {
          result[district]!['total'] = result[district]!['total']! + 1;
          if (c.status == 'RESOLVED' || c.status == 'CLOSED') {
            result[district]!['resolved'] = result[district]!['resolved']! + 1;
          } else {
            result[district]!['open'] = result[district]!['open']! + 1;
          }
          matched = true;
          break;
        }
      }
      
      if (!matched) {
        // Optionally handle unmatched
      }
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Improved loading logic: Only show loader if we have NO districts and NO error,
    // and either jurisdiction or dashboard is still loading.
    final bool showLoader = _isLoadingJurisdiction && _districts.isEmpty && _error == null;

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
            if (showLoader)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else if (_error != null)
              _buildErrorState(theme)
            else if (_districts.isEmpty && !_isLoadingJurisdiction)
              _buildEmptyState(theme)
            else
              _buildDistrictList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
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
                Text(
                  'Cases by District',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_provinceName != null)
                  Text(
                    _provinceName!,
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
              style: const TextStyle(
                color: ImboniColors.info,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadJurisdiction,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, color: theme.disabledColor, size: 40),
            const SizedBox(height: 12),
            Text('No districts found for this province', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictList(ThemeData theme) {
    final caseData = _getCasesByDistrict();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _districts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final district = _districts[index];
        final stats = caseData[district] ?? {'open': 0, 'resolved': 0, 'total': 0};
        final sectorCount = _districtSectors[district] ?? 0;
        return _buildDistrictCard(context, district, stats['open']!, stats['resolved']!, stats['total']!, sectorCount);
      },
    );
  }

  Widget _buildDistrictCard(BuildContext context, String districtName, int open, int resolved, int total, int sectorCount) {
    final theme = Theme.of(context);

    Color statusColor;
    if (total == 0) {
      statusColor = theme.disabledColor;
    } else if (open == 0) {
      statusColor = Colors.green;
    } else if (open < 3) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

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
            child: Icon(Icons.apartment, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(districtName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      '($sectorCount Sectors)',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha(150), fontSize: 10),
                    ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: total > 0 ? ImboniColors.primary.withAlpha(15) : theme.disabledColor.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                color: total > 0 ? ImboniColors.primary : theme.disabledColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
