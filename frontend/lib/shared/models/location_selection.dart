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
