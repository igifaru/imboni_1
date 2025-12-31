import 'package:flutter/material.dart';

import '../services/admin_units_service.dart';
import '../models/models.dart';

/// Location Selector Widget - Cascading dropdowns for Rwanda's admin hierarchy
class LocationSelector extends StatefulWidget {
  final LocationSelection? initialSelection;
  final ValueChanged<LocationSelection> onLocationChanged;
  final bool showVillage;

  const LocationSelector({
    super.key,
    this.initialSelection,
    required this.onLocationChanged,
    this.showVillage = true,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late LocationSelection _selection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection ?? const LocationSelection();
    _loadData();
  }

  Future<void> _loadData() async {
    await adminUnitsService.load();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Province / Intara',
          value: _selection.province,
          items: adminUnitsService.provinces,
          onChanged: (value) {
            setState(() => _selection = LocationSelection(province: value));
            widget.onLocationChanged(_selection);
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'District / Akarere',
          value: _selection.district,
          items: _selection.province != null ? adminUnitsService.getDistricts(_selection.province!) : [],
          onChanged: (value) {
            setState(() => _selection = _selection.copyWith(district: value, sector: null, cell: null, village: null));
            widget.onLocationChanged(_selection);
          },
          enabled: _selection.province != null,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Sector / Umurenge',
          value: _selection.sector,
          items: _selection.province != null && _selection.district != null
              ? adminUnitsService.getSectors(_selection.province!, _selection.district!)
              : [],
          onChanged: (value) {
            setState(() => _selection = _selection.copyWith(sector: value, cell: null, village: null));
            widget.onLocationChanged(_selection);
          },
          enabled: _selection.district != null,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Cell / Akagari',
          value: _selection.cell,
          items: _selection.province != null && _selection.district != null && _selection.sector != null
              ? adminUnitsService.getCells(_selection.province!, _selection.district!, _selection.sector!)
              : [],
          onChanged: (value) {
            setState(() => _selection = _selection.copyWith(cell: value, village: null));
            widget.onLocationChanged(_selection);
          },
          enabled: _selection.sector != null,
        ),
        if (widget.showVillage) ...[
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Village / Umudugudu',
            value: _selection.village,
            items: _selection.province != null && _selection.district != null && _selection.sector != null && _selection.cell != null
                ? adminUnitsService.getVillages(_selection.province!, _selection.district!, _selection.sector!, _selection.cell!)
                : [],
            onChanged: (value) {
              setState(() => _selection = _selection.copyWith(village: value));
              widget.onLocationChanged(_selection);
            },
            enabled: _selection.cell != null,
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            enabled: enabled,
            hintText: enabled ? 'Select $label' : 'Select previous level first',
            suffixIcon: enabled ? const Icon(Icons.arrow_drop_down) : const Icon(Icons.lock_outline, size: 20),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
        ),
      ],
    );
  }
}
