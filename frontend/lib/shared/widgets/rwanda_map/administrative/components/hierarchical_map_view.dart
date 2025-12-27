import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../models/location_selection.dart';
import 'grid_selector.dart';
import 'list_selector.dart';

class HierarchicalMapView extends StatelessWidget {
  final LocationSelection selection;
  final Function(LocationSelection) onSelectionChanged;
  final Map<String, int>? casesByProvince;
  final Map<String, int>? casesByDistrict;
  final bool isDark;

  const HierarchicalMapView({
    required this.selection,
    required this.onSelectionChanged,
    this.casesByProvince,
    this.casesByDistrict,
    this.isDark = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = LocationService();

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
    } else if (selection.district == null) {
      return GridSelector(
        title: 'Districts in ${selection.province}',
        items: service.getDistricts(selection.province!),
        counts: casesByDistrict, // Note: This map contains all districts, grid_selector handles key lookup
        isDark: isDark,
        onSelected: (district) {
          onSelectionChanged(selection.copyWith(district: district));
        },
        onBack: () {
          onSelectionChanged(LocationSelection(province: null));
        },
      );
    } else if (selection.sector == null) {
      return ListSelector( // Switch to list for Sectors (many items)
        title: 'Sectors in ${selection.district}',
        items: service.getSectors(selection.province!, selection.district!),
        onSelected: (sector) {
          onSelectionChanged(selection.copyWith(sector: sector));
        },
        onBack: () {
          onSelectionChanged(selection.copyWith(province: selection.province, district: null));
        },
      );
    } else {
      return ListSelector(
        title: 'Cells in ${selection.sector}',
        items: service.getCells(selection.province!, selection.district!, selection.sector!),
        onSelected: (cell) {
          onSelectionChanged(selection.copyWith(cell: cell));
        },
        onBack: () {
          onSelectionChanged(selection.copyWith(province: selection.province, district: selection.district, sector: null));
        },
      );
    }
  }
}
