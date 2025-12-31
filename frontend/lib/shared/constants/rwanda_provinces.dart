/// Rwanda's 5 Provinces with their Kinyarwanda names
/// This is the single source of truth for province definitions across the app.
library rwanda_provinces;

/// Province data class
class RwandaProvince {
  final String code;
  final String name;
  final String englishKey; // Key used in data.json (East, West, North, South, Kigali)

  const RwandaProvince({
    required this.code,
    required this.name,
    required this.englishKey,
  });

  /// Convert to Map for dropdown usage
  Map<String, String> toMap() => {'code': code, 'name': name};
}

/// All 5 Rwanda Provinces
const List<RwandaProvince> rwandaProvinces = [
  RwandaProvince(code: 'Kigali', name: 'Kigali', englishKey: 'Kigali'),
  RwandaProvince(code: 'Amajyaruguru', name: 'Amajyaruguru (Northern Province)', englishKey: 'North'),
  RwandaProvince(code: 'Amajyepfo', name: 'Amajyepfo (Southern Province)', englishKey: 'South'),
  RwandaProvince(code: 'Iburasirazuba', name: 'Iburasirazuba (Eastern Province)', englishKey: 'East'),
  RwandaProvince(code: 'Iburengerazuba', name: 'Iburengerazuba (Western Province)', englishKey: 'West'),
];

/// Get province by code
RwandaProvince? getProvinceByCode(String code) {
  try {
    return rwandaProvinces.firstWhere((p) => p.code == code);
  } catch (_) {
    return null;
  }
}

/// Get province by English key (for data.json matching)
RwandaProvince? getProvinceByEnglishKey(String key) {
  try {
    return rwandaProvinces.firstWhere((p) => p.englishKey == key);
  } catch (_) {
    return null;
  }
}

/// Province code mapping: Kinyarwanda -> English (for backend compatibility)
const Map<String, String> provinceCodeToEnglish = {
  'Kigali': 'Kigali',
  'Amajyaruguru': 'North',
  'Amajyepfo': 'South',
  'Iburasirazuba': 'East',
  'Iburengerazuba': 'West',
};

/// Reverse mapping: English -> Kinyarwanda
const Map<String, String> provinceEnglishToCode = {
  'Kigali': 'Kigali',
  'North': 'Amajyaruguru',
  'South': 'Amajyepfo',
  'East': 'Iburasirazuba',
  'West': 'Iburengerazuba',
};
