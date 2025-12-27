class LocationSelection {
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;

  const LocationSelection({
    this.province,
    this.district,
    this.sector,
    this.cell,
  });

  LocationSelection copyWith({
    String? province,
    String? district,
    String? sector,
    String? cell,
  }) {
    // If setting a higher level, nullify lower levels by logic in caller usually, 
    // but here we just replace what is passed. 
    // Caller often does copyWith(province: p, district: null...)
    return LocationSelection(
      province: province ?? this.province,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
    );
  }

  String get fullPath {
    final parts = [province, district, sector, cell].whereType<String>();
    return parts.join(' > ');
  }

  String get level {
    if (cell != null) return 'Cell';
    if (sector != null) return 'Sector';
    if (district != null) return 'District';
    if (province != null) return 'Province';
    return 'None';
  }

  bool get isComplete => cell != null;

  @override
  String toString() => fullPath;
}
