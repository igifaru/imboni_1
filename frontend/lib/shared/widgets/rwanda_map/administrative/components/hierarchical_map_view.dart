import 'package:flutter/material.dart';
import 'package:imboni/shared/services/admin_units_service.dart';


import '../../models/location_selection.dart';
import 'grid_selector.dart';
import 'list_selector.dart';

class HierarchicalMapView extends StatelessWidget {
  final LocationSelection selection;
  final Function(LocationSelection) onSelectionChanged;
  final Map<String, int>? casesByProvince;
  final Map<String, int>? casesByDistrict;
  final Map<String, int>? casesBySector;
  final Map<String, int>? casesByCell;
  final Map<String, int>? casesByVillage;
  final bool isDark;
  
  /// The user's scope level - determines how far up they can navigate
  final AdministrativeLevel? scopeLevel;
  
  /// Whether the user is in full map mode (no restrictions)
  final bool isFullMapMode;

  const HierarchicalMapView({
    required this.selection,
    required this.onSelectionChanged,
    this.casesByProvince,
    this.casesByDistrict,
    this.casesBySector,
    this.casesByCell,
    this.casesByVillage,
    this.isDark = false,
    this.scopeLevel,
    this.isFullMapMode = false,
    super.key,
  });

  /// Check if user can navigate back (drill up) from current level
  bool _canGoBack(AdministrativeLevel currentLevel) {
    if (isFullMapMode) return true;
    if (scopeLevel == null) return true;
    
    // Can only go back if current level is deeper than scope level
    return currentLevel.index > scopeLevel!.index;
  }

  @override
  Widget build(BuildContext context) {
    final service = adminUnitsService;

    // Province level view
    if (selection.province == null) {
      return GridSelector(
        title: 'Provinces of Rwanda',
        items: service.getProvinces(),
        counts: casesByProvince,
        isDark: isDark,
        onSelected: (province) {
          onSelectionChanged(selection.copyWith(province: province));
        },
      );
    } 
    
    // District level view
    if (selection.district == null) {
      return GridSelector(
        title: 'Districts in ${selection.province}',
        items: service.getDistricts(selection.province!),
        counts: casesByDistrict,
        isDark: isDark,
        onSelected: (district) {
          onSelectionChanged(selection.copyWith(district: district));
        },
        onBack: _canGoBack(AdministrativeLevel.district) 
            ? () => onSelectionChanged(const LocationSelection())
            : null,
      );
    } 
    
    // Sector level view
    if (selection.sector == null) {
      return ListSelector(
        title: 'Sectors in ${selection.district}',
        items: service.getSectors(selection.province!, selection.district!),
        counts: casesBySector,
        onSelected: (sector) {
          onSelectionChanged(selection.copyWith(sector: sector));
        },
        onBack: _canGoBack(AdministrativeLevel.sector) 
            ? () => onSelectionChanged(selection.copyWith(district: null))
            : null,
      );
    } 
    
    // Cell level view
    if (selection.cell == null) {
      return ListSelector(
        title: 'Cells in ${selection.sector}',
        items: service.getCells(selection.province!, selection.district!, selection.sector!),
        counts: casesByCell,
        onSelected: (cell) {
          onSelectionChanged(selection.copyWith(cell: cell));
        },
        onBack: _canGoBack(AdministrativeLevel.cell) 
            ? () => onSelectionChanged(selection.copyWith(sector: null))
            : null,
      );
    }
    
    // Village level view
    if (selection.village == null) {
      return ListSelector(
        title: 'Villages in ${selection.cell}',
        items: service.getVillages(
          selection.province!, 
          selection.district!, 
          selection.sector!, 
          selection.cell!,
        ),
        counts: casesByVillage,
        onSelected: (village) {
          onSelectionChanged(selection.copyWith(village: village));
        },
        onBack: _canGoBack(AdministrativeLevel.village) 
            ? () => onSelectionChanged(selection.copyWith(cell: null))
            : null,
      );
    }
    
    // Deepest level - show village detail
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 48, color: isDark ? Colors.white70 : Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            selection.village!,
            style: TextStyle(
              fontSize: 20, // Reverted to original as 'value: value' is not valid for TextStyle
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selection.fullPath,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_canGoBack(AdministrativeLevel.village)) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => onSelectionChanged(selection.copyWith(village: null)),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Villages'),
            ),
          ],
        ],
      ),
    );
  }
}
