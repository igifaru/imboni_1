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

final adminUnitsService = AdminUnitsService.instance;
