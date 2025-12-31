import 'package:flutter/material.dart';
import '../models/location_selection.dart';
import 'components/hierarchical_map_view.dart';

class RwandaAdministrativeMap extends StatefulWidget {
  final Map<String, int> casesByProvince;
  final Map<String, int> casesByDistrict;
  final String? selectedProvince;
  final ValueChanged<String>? onProvinceSelected;
  final ValueChanged<String>? onDistrictSelected;
  final bool showAIInsights;

  const RwandaAdministrativeMap({
    super.key,
    required this.casesByProvince,
    required this.casesByDistrict,
    this.selectedProvince,
    this.onProvinceSelected,
    this.onDistrictSelected,
    this.showAIInsights = false,
  });

  @override
  State<RwandaAdministrativeMap> createState() => _RwandaAdministrativeMapState();
}

class _RwandaAdministrativeMapState extends State<RwandaAdministrativeMap> {
  LocationSelection _selection = const LocationSelection();

  @override
  void didUpdateWidget(covariant RwandaAdministrativeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProvince != oldWidget.selectedProvince) {
      if (widget.selectedProvince != null && widget.selectedProvince!.isNotEmpty) {
        _selection = _selection.copyWith(province: widget.selectedProvince);
      } else {
        _selection = const LocationSelection();
      }
    }
  }

  void _handleSelectionChanged(LocationSelection newSelection) {
    setState(() => _selection = newSelection);
    
    // Notify parents
    if (newSelection.province != widget.selectedProvince) {
      widget.onProvinceSelected?.call(newSelection.province ?? '');
    }
    if (newSelection.district != null) {
      widget.onDistrictSelected?.call(newSelection.district!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 500, // Augmented height for nested views
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: HierarchicalMapView(
                selection: _selection,
                onSelectionChanged: _handleSelectionChanged,
                casesByProvince: widget.casesByProvince,
                casesByDistrict: widget.casesByDistrict,
                isDark: isDark,
              ),
            ),
          ),
          
          // Footer with Legend and AI Insights
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                _buildLegend(theme),
                if (widget.showAIInsights) ...[
                  const SizedBox(height: 12),
                  _buildAIInsightsBanner(theme, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Color(0xFF4CAF50), label: 'Low'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFFF9800), label: 'Medium'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFF44336), label: 'High Priority'),
      ],
    );
  }

  Widget _buildAIInsightsBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3F1914) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEDD5)),
      ),
      child: Row(children: [
        Icon(Icons.auto_awesome, color: isDark ? const Color(0xFFF87171) : const Color(0xFFEA580C), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'AI Insight', 
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold, 
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF9A3412)
              )
            ),
            Text(
              'Unusually high case density in North Province compared to last month.', 
              style: TextStyle(
                fontSize: 12, 
                color: isDark ? const Color(0xFFFECACA) : const Color(0xFF9A3412)
              )
            ),
          ]),
        ),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
