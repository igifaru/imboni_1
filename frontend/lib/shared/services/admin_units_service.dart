import 'dart:convert';
import 'package:flutter/services.dart';

/// Rwanda Administrative Units - Province, District, Sector, Cell, Village
class AdminUnitsService {
  static AdminUnitsService? _instance;
  Map<String, dynamic>? _data;
  bool _isLoaded = false;

  AdminUnitsService._();
  static AdminUnitsService get instance => _instance ??= AdminUnitsService._();

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data.json');
      _data = json.decode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
    } catch (e) {
      _data = {};
      _isLoaded = true;
    }
  }

  /// Get all provinces
  List<String> get provinces {
    if (_data == null) return [];
    return _data!.keys.toList()..sort();
  }

  /// Get districts in a province
  List<String> getDistricts(String province) {
    if (_data == null || !_data!.containsKey(province)) return [];
    final districts = _data![province] as Map<String, dynamic>;
    return districts.keys.toList()..sort();
  }

  /// Get sectors in a district
  List<String> getSectors(String province, String district) {
    if (_data == null) return [];
    final provinceData = _data![province] as Map<String, dynamic>?;
    if (provinceData == null) return [];
    final districtData = provinceData[district] as Map<String, dynamic>?;
    if (districtData == null) return [];
    return districtData.keys.toList()..sort();
  }

  /// Get cells in a sector
  List<String> getCells(String province, String district, String sector) {
    if (_data == null) return [];
    final provinceData = _data![province] as Map<String, dynamic>?;
    if (provinceData == null) return [];
    final districtData = provinceData[district] as Map<String, dynamic>?;
    if (districtData == null) return [];
    final sectorData = districtData[sector] as Map<String, dynamic>?;
    if (sectorData == null) return [];
    return sectorData.keys.toList()..sort();
  }

  /// Get villages in a cell
  List<String> getVillages(String province, String district, String sector, String cell) {
    if (_data == null) return [];
    final provinceData = _data![province] as Map<String, dynamic>?;
    if (provinceData == null) return [];
    final districtData = provinceData[district] as Map<String, dynamic>?;
    if (districtData == null) return [];
    final sectorData = districtData[sector] as Map<String, dynamic>?;
    if (sectorData == null) return [];
    final cellData = sectorData[cell];
    if (cellData is List) return List<String>.from(cellData)..sort();
    return [];
  }
}

/// Location selection model
class LocationSelection {
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;

  const LocationSelection({this.province, this.district, this.sector, this.cell, this.village});

  bool get isComplete => province != null && district != null && sector != null && cell != null && village != null;

  String get fullAddress {
    final parts = <String>[];
    if (village != null) parts.add(village!);
    if (cell != null) parts.add(cell!);
    if (sector != null) parts.add(sector!);
    if (district != null) parts.add(district!);
    if (province != null) parts.add(province!);
    return parts.join(', ');
  }

  LocationSelection copyWith({String? province, String? district, String? sector, String? cell, String? village}) {
    return LocationSelection(
      province: province ?? this.province,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
      village: village ?? this.village,
    );
  }
}

final adminUnitsService = AdminUnitsService.instance;
