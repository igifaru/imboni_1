/// Represents the administrative levels in Rwanda
enum AdministrativeLevel {
  none,
  province,
  district,
  sector,
  cell,
  village,
}

class LocationSelection {
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;
  
  /// The scope level determines the highest level this user can navigate to
  final AdministrativeLevel? scopeLevel;

  const LocationSelection({
    this.province,
    this.district,
    this.sector,
    this.cell,
    this.village,
    this.scopeLevel,
  });

  LocationSelection copyWith({
    String? province,
    String? district,
    String? sector,
    String? cell,
    String? village,
    AdministrativeLevel? scopeLevel,
  }) {
    return LocationSelection(
      province: province ?? this.province,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
      village: village ?? this.village,
      scopeLevel: scopeLevel ?? this.scopeLevel,
    );
  }

  String get fullPath {
    final parts = [province, district, sector, cell, village].whereType<String>();
    return parts.join(' > ');
  }

  AdministrativeLevel get currentLevel {
    if (village != null) return AdministrativeLevel.village;
    if (cell != null) return AdministrativeLevel.cell;
    if (sector != null) return AdministrativeLevel.sector;
    if (district != null) return AdministrativeLevel.district;
    if (province != null) return AdministrativeLevel.province;
    return AdministrativeLevel.none;
  }

  /// Check if user can drill up from current level based on their scope
  bool canDrillUp(AdministrativeLevel userScope) {
    return currentLevel.index > userScope.index;
  }

  bool get isComplete => village != null;

  /// Create initial selection based on user's administrative assignment
  static LocationSelection fromScope({
    required String? province,
    String? district,
    String? sector,
    String? cell,
    String? village,
    required AdministrativeLevel scopeLevel,
  }) {
    return LocationSelection(
      province: province,
      district: district,
      sector: sector,
      cell: cell,
      village: village,
      scopeLevel: scopeLevel,
    );
  }

  @override
  String toString() => fullPath;
}
