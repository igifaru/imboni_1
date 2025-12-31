import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Map<String, dynamic>? _data;
  final Map<String, String> _sectorToDistrict = {};
  final Map<String, String> _districtToProvince = {};
  final Set<String> _districts = {};
  final Set<String> _provinces = {};

  bool get isLoaded => _data != null;

  Future<void> load() async {
    if (_data != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data.json');
      _data = json.decode(jsonString);
      _parseHierarchy();
    } catch (e) {
      debugPrint('Error loading location data: $e');
      // Fallback or empty initialization
      _data = {};
    }
  }

  void _parseHierarchy() {
    if (_data == null) return;

    _provinces.clear();
    _districts.clear();
    _districtToProvince.clear();
    _sectorToDistrict.clear();

    _data!.forEach((provinceName, districtsMap) {
      _provinces.add(provinceName);
      
      if (districtsMap is Map) {
        districtsMap.forEach((districtName, sectorsMap) {
          _districts.add(districtName);
          _districtToProvince[districtName] = provinceName;
          
          if (sectorsMap is Map) {
            sectorsMap.forEach((sectorName, cells) {
              // Note: Sector names might duplicate across districts, 
              // but we store the last one found or consider composite key if needed.
              // For visualization, simple mapping is usually sufficient.
              _sectorToDistrict[sectorName] = districtName;
            });
          }
        });
      }
    });
  }

  /// Tries to find the District name from a location string.
  /// The location string might contain Province, District, or Sector names.
  String? extractDistrict(String location) {
    if (_data == null) return null;
    final normalized = location.trim(); // case sensitive matching usually for keys

    // 1. Check if location IS a district
    for (final d in _districts) {
      if (normalized.contains(d)) return d;
    }

    // 2. Check if location IS a sector (map to district)
    for (final s in _sectorToDistrict.keys) {
      if (normalized.contains(s)) return _sectorToDistrict[s];
    }

    return null;
  }

  String? getProvinceForDistrict(String district) {
    return _districtToProvince[district];
  }

  List<String> getProvinces() => _provinces.toList()..sort();

  List<String> getDistricts(String province) {
    if (_data == null) return [];
    final provinceData = _data![province] as Map<String, dynamic>?;
    final list = provinceData?.keys.toList() ?? [];
    list.sort();
    return list;
  }

  List<String> getSectors(String province, String district) {
    if (_data == null) return [];
    final provinceData = _data![province] as Map<String, dynamic>?;
    final districtData = provinceData?[district] as Map<String, dynamic>?;
    final list = districtData?.keys.toList() ?? [];
    list.sort();
    return list;
  }

  List<String> getCells(String province, String district, String sector) {
    if (_data == null) return [];
    final provinceData = _data![province] as Map<String, dynamic>?;
    final districtData = provinceData?[district] as Map<String, dynamic>?;
    final sectorData = districtData?[sector];
    
    if (sectorData is List) {
      final list = List<String>.from(sectorData);
      list.sort();
      return list;
    }
    return [];
  }
}
