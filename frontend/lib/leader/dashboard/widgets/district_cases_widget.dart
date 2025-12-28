import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../admin/services/admin_service.dart';
import '../../../shared/models/models.dart';

/// Widget to display districts for a Province Leader with case statistics
/// Fetches data from /my-jurisdiction API based on leader's assignment
class DistrictCasesWidget extends StatefulWidget {
  final List<CaseModel> cases;
  final bool isLoading;

  const DistrictCasesWidget({
    super.key,
    required this.cases,
    this.isLoading = false,
  });

  @override
  State<DistrictCasesWidget> createState() => _DistrictCasesWidgetState();
}

class _DistrictCasesWidgetState extends State<DistrictCasesWidget> {
  bool _isLoadingJurisdiction = true;
  String? _error;
  String? _provinceName;
  List<String> _districts = [];

  @override
  void initState() {
    super.initState();
    _loadJurisdiction();
  }

  Future<void> _loadJurisdiction() async {
    setState(() {
      _isLoadingJurisdiction = true;
      _error = null;
    });

    try {
      final data = await adminService.getMyJurisdiction();
      if (mounted) {
        if (data != null && data['success'] == true) {
          setState(() {
            _provinceName = data['assignment']?['province'] ?? 'Unknown';
            _districts = List<String>.from(data['districts'] ?? []);
            _isLoadingJurisdiction = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load jurisdiction data';
            _isLoadingJurisdiction = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingJurisdiction = false;
        });
      }
    }
  }

  /// Get case counts per district
  Map<String, Map<String, int>> _getCasesByDistrict() {
    final Map<String, Map<String, int>> result = {};
    
    // Initialize all districts with zeros
    for (final district in _districts) {
      result[district] = {'open': 0, 'resolved': 0, 'total': 0};
    }
    
    // Count cases per district (you may need to adjust this based on your case model)
    for (final c in widget.cases) {
      // Try to match district from case location or jurisdiction
      for (final district in _districts) {
        if (c.title.toLowerCase().contains(district.toLowerCase()) ||
            c.caseReference.toLowerCase().contains(district.toLowerCase())) {
          result[district]!['total'] = (result[district]!['total'] ?? 0) + 1;
          if (c.status == 'RESOLVED' || c.status == 'CLOSED') {
            result[district]!['resolved'] = (result[district]!['resolved'] ?? 0) + 1;
          } else {
            result[district]!['open'] = (result[district]!['open'] ?? 0) + 1;
          }
          break;
        }
      }
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caseData = _getCasesByDistrict();

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
                            style: theme.textTheme.bodySmall?.copyWith(color: ImboniColors.primary),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ),
            const SizedBox(height: 16),
            if (_isLoadingJurisdiction || widget.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _loadJurisdiction, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_districts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No districts found', style: theme.textTheme.bodyMedium),
                ),
              )
            else
              Column(
                children: _districts.map((district) {
                  final stats = caseData[district] ?? {'open': 0, 'resolved': 0, 'total': 0};
                  return _buildDistrictCard(context, district, stats['open']!, stats['resolved']!, stats['total']!);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictCard(BuildContext context, String districtName, int open, int resolved, int total) {
    final theme = Theme.of(context);

    // Color based on open cases
    Color statusColor;
    if (total == 0) {
      statusColor = Colors.grey;
    } else if (open == 0) {
      statusColor = Colors.green;
    } else if (open < 3) {
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
          // District Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.apartment, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          // District Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(districtName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat(context, 'Open', open, Colors.orange),
                    const SizedBox(width: 12),
                    _buildMiniStat(context, 'Resolved', resolved, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          // Total Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: total > 0 ? ImboniColors.primary.withAlpha(20) : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                color: total > 0 ? ImboniColors.primary : Colors.grey,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

