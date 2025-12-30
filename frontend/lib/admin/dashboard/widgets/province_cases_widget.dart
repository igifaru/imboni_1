import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/constants/rwanda_provinces.dart';
import '../../../shared/localization/app_localizations.dart';

class ProvinceCasesWidget extends StatelessWidget {
  final List<CaseModel> cases;
  final bool isLoading;

  const ProvinceCasesWidget({
    super.key,
    required this.cases,
    this.isLoading = false,
  });

  /// Group cases by province based on currentLevel or administrative unit
  Map<String, Map<String, int>> get _casesByProvince {
    final Map<String, Map<String, int>> result = {};

    // Initialize all provinces with zeros
    for (final province in rwandaProvinces) {
      result[province.code] = {'open': 0, 'resolved': 0, 'total': 0};
    }

    for (final c in cases) {
      // Extract province from currentLevel (e.g., "PROVINCE", "DISTRICT", etc.)
      // or from the case's administrative unit info
      String? provinceCode = _extractProvince(c);
      
      if (provinceCode != null && result.containsKey(provinceCode)) {
        result[provinceCode]!['total'] = (result[provinceCode]!['total'] ?? 0) + 1;
        
        if (c.status == 'RESOLVED' || c.status == 'CLOSED') {
          result[provinceCode]!['resolved'] = (result[provinceCode]!['resolved'] ?? 0) + 1;
        } else {
          result[provinceCode]!['open'] = (result[provinceCode]!['open'] ?? 0) + 1;
        }
      }
    }

    return result;
  }

  // Mapping from Backend Administrative Unit Codes to Frontend Province Keys
  static const Map<String, String> _backendCodeToProvinceKey = {
    'NORTHERN PROVINCE': 'Amajyaruguru',
    'SOUTHERN PROVINCE': 'Amajyepfo',
    'EASTERN PROVINCE': 'Iburasirazuba',
    'WESTERN PROVINCE': 'Iburengerazuba',
    'KIGALI CITY': 'Kigali',
  };

  String? _extractProvince(CaseModel c) {
    // 1. Try to use strict code matching if available (Best Accuracy)
    if (c.administrativeUnitCode != null && c.administrativeUnitCode!.isNotEmpty) {
      final code = c.administrativeUnitCode!;
      
      // Direct Map Check (e.g. valid for Province level cases)
      if (_backendCodeToProvinceKey.containsKey(code)) {
        return _backendCodeToProvinceKey[code];
      }

      // Prefix Check (e.g. "NORTHERN PROVINCE:BURERA")
      for (final entry in _backendCodeToProvinceKey.entries) {
        if (code.startsWith('${entry.key}:')) {
          return entry.value;
        }
      }
    }

    // 2. Try to extract province from currentLevel string (Fallback)
    final level = c.currentLevel.toUpperCase();
    for (final entry in provinceEnglishToCode.entries) {
      if (level.contains(entry.key.toUpperCase())) {
        return entry.value; 
      }
    }

    // 3. Last Resort: Unknown/Unassigned
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caseData = _casesByProvince;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ImboniColors.primary.withAlpha(isDark ? 50 : 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cases_outlined, color: ImboniColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).casesByProvince,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ImboniColors.info.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cases.length} ${AppLocalizations.of(context).total}',
                    style: const TextStyle(
                      color: ImboniColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              Column(
                children: rwandaProvinces.map((province) {
                  final code = province.code;
                  final name = province.name;
                  final stats = caseData[code] ?? {'open': 0, 'resolved': 0, 'total': 0};
                  return _buildProvinceCard(context, name, stats['open']!, stats['resolved']!, stats['total']!);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceCard(BuildContext context, String provinceName, int open, int resolved, int total) {
    final theme = Theme.of(context);

    // Color based on open cases
    Color statusColor;
    if (total == 0) {
      statusColor = Colors.grey;
    } else if (open == 0) {
      statusColor = Colors.green;
    } else if (open < 3) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Province Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_city, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Province Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provinceName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat(context, AppLocalizations.of(context).open, open, Colors.orange),
                    const SizedBox(width: 12),
                    _buildMiniStat(context, AppLocalizations.of(context).resolved, resolved, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          // Total Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: total > 0 ? ImboniColors.primary.withAlpha(20) : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                color: total > 0 ? ImboniColors.primary : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
