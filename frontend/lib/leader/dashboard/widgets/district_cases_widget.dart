import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../admin/services/admin_service.dart';

/// Widget to display districts for a Province Leader
/// Fetches data from /my-jurisdiction API based on leader's assignment
class DistrictCasesWidget extends StatefulWidget {
  const DistrictCasesWidget({super.key});

  @override
  State<DistrictCasesWidget> createState() => _DistrictCasesWidgetState();
}

class _DistrictCasesWidgetState extends State<DistrictCasesWidget> {
  bool _isLoading = true;
  String? _error;
  String? _provinceName;
  List<String> _districts = [];
  Map<String, dynamic>? _districtData;

  @override
  void initState() {
    super.initState();
    _loadJurisdiction();
  }

  Future<void> _loadJurisdiction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await adminService.getMyJurisdiction();
      if (mounted) {
        if (data != null && data['success'] == true) {
          setState(() {
            _provinceName = data['assignment']?['province'] ?? 'Unknown';
            _districts = List<String>.from(data['districts'] ?? []);
            _districtData = data['data'] as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load jurisdiction data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
                      child: const Icon(Icons.location_city, color: ImboniColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Districts in Province',
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
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                  onPressed: _loadJurisdiction,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
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
                  // Get sector count for this district if available
                  final sectorCount = _districtData?[district] != null
                      ? (_districtData![district] as Map<String, dynamic>).length
                      : 0;
                  return _buildDistrictCard(context, district, sectorCount);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictCard(BuildContext context, String districtName, int sectorCount) {
    final theme = Theme.of(context);

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
              color: ImboniColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment, color: ImboniColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          // District Name & Sector count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(districtName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '$sectorCount Sectors',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
