import 'package:flutter/material.dart';
import '../models/location_selection.dart';
import 'components/hierarchical_map_view.dart';

class RwandaAdministrativeMap extends StatefulWidget {
  final Map<String, int>? casesByProvince;
  final Map<String, int>? casesByDistrict;
  final Map<String, int>? casesBySector;
  final Map<String, int>? casesByCell;
  final Map<String, int>? casesByVillage;
  
  /// Initial selection based on user's scope
  final LocationSelection? initialSelection;
  
  /// User's scope level (determines how far up they can navigate)
  final AdministrativeLevel? scopeLevel;
  
  /// Whether this user can toggle to view full map (typically Citizens)
  final bool canViewFullMap;
  
  final String? selectedProvince;
  final ValueChanged<String>? onProvinceSelected;
  final ValueChanged<String>? onDistrictSelected;
  final ValueChanged<LocationSelection>? onSelectionChanged;
  final bool showAIInsights;

  const RwandaAdministrativeMap({
    super.key,
    this.casesByProvince,
    this.casesByDistrict,
    this.casesBySector,
    this.casesByCell,
    this.casesByVillage,
    this.initialSelection,
    this.scopeLevel,
    this.canViewFullMap = false,
    this.selectedProvince,
    this.onProvinceSelected,
    this.onDistrictSelected,
    this.onSelectionChanged,
    this.showAIInsights = false,
  });

  @override
  State<RwandaAdministrativeMap> createState() => _RwandaAdministrativeMapState();
}

class _RwandaAdministrativeMapState extends State<RwandaAdministrativeMap> {
  late LocationSelection _selection;
  bool _isFullMapMode = false;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection ?? const LocationSelection();
  }

  @override
  void didUpdateWidget(covariant RwandaAdministrativeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle external province selection
    if (widget.selectedProvince != oldWidget.selectedProvince) {
      if (widget.selectedProvince != null && widget.selectedProvince!.isNotEmpty) {
        _selection = _selection.copyWith(province: widget.selectedProvince);
      } else if (_isFullMapMode) {
        _selection = const LocationSelection();
      }
    }
    
    // Handle initial selection changes
    if (widget.initialSelection != oldWidget.initialSelection && widget.initialSelection != null) {
      if (!_isFullMapMode) {
        _selection = widget.initialSelection!;
      }
    }
  }

  void _handleSelectionChanged(LocationSelection newSelection) {
    setState(() => _selection = newSelection);
    
    // Notify parents
    widget.onSelectionChanged?.call(newSelection);
    
    if (newSelection.province != widget.selectedProvince) {
      widget.onProvinceSelected?.call(newSelection.province ?? '');
    }
    if (newSelection.district != null) {
      widget.onDistrictSelected?.call(newSelection.district!);
    }
  }

  void _toggleFullMap() {
    setState(() {
      _isFullMapMode = !_isFullMapMode;
      if (_isFullMapMode) {
        // Full map mode - start from provinces
        _selection = const LocationSelection();
      } else {
        // Return to user's scoped view
        _selection = widget.initialSelection ?? const LocationSelection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 500,
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
          // Header with scope indicator and toggle
          _buildHeader(theme, isDark),
          
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HierarchicalMapView(
                selection: _selection,
                onSelectionChanged: _handleSelectionChanged,
                casesByProvince: widget.casesByProvince,
                casesByDistrict: widget.casesByDistrict,
                casesBySector: widget.casesBySector,
                casesByCell: widget.casesByCell,
                casesByVillage: widget.casesByVillage,
                isDark: isDark,
                scopeLevel: _isFullMapMode ? null : widget.scopeLevel,
                isFullMapMode: _isFullMapMode,
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

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Current location indicator
          Icon(
            Icons.location_on,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selection.fullPath.isNotEmpty 
                  ? _selection.fullPath 
                  : 'Rwanda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Full map toggle (for citizens)
          if (widget.canViewFullMap)
            TextButton.icon(
              onPressed: _toggleFullMap,
              icon: Icon(
                _isFullMapMode ? Icons.my_location : Icons.public,
                size: 18,
              ),
              label: Text(
                _isFullMapMode ? 'My Location' : 'Full Map',
                style: const TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
