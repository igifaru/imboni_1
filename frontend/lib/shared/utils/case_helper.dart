import 'package:flutter/material.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:intl/intl.dart';

class CaseHelper {
  static String getStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return l10n.statusOpen;
      case 'IN_PROGRESS': return l10n.statusInProgress;
      case 'RESOLVED': return l10n.statusResolved;
      case 'CLOSED': return l10n.statusClosed;
      case 'ESCALATED': return l10n.statusEscalated;
      default: return status.replaceAll('_', ' ');
    }
  }

  static String getCategoryLabel(AppLocalizations l10n, String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return l10n.categoryJustice;
      case 'HEALTH': return l10n.categoryHealth;
      case 'LAND': return l10n.categoryLand;
      case 'INFRASTRUCTURE': return l10n.categoryInfrastructure;
      case 'SECURITY': return l10n.categorySecurity;
      case 'SOCIAL': return l10n.categorySocial;
      case 'EDUCATION': return l10n.categoryEducation;
      default: return category;
    }
  }

  static String getUrgencyLabel(AppLocalizations l10n, String urgency) {
    switch (urgency.toUpperCase()) {
      case 'HIGH': return l10n.urgencyHigh;
      case 'EMERGENCY': return l10n.urgencyEmergency;
      default: return l10n.urgencyNormal;
    }
  }

  static String getLevelLabel(AppLocalizations l10n, String level) {
    switch (level.toUpperCase()) {
      case 'VILLAGE': return l10n.levelVillage;
      case 'CELL': return l10n.levelCell;
      case 'SECTOR': return l10n.levelSector;
      case 'DISTRICT': return l10n.levelDistrict;
      case 'PROVINCE': return l10n.levelProvince;
      case 'NATIONAL': return l10n.levelNational;
      default: return level;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return Icons.balance;
      case 'HEALTH': return Icons.health_and_safety;
      case 'LAND': return Icons.terrain;
      case 'INFRASTRUCTURE': return Icons.construction;
      case 'SECURITY': return Icons.security;
      case 'SOCIAL': return Icons.people;
      case 'EDUCATION': return Icons.school;
      default: return Icons.category;
    }
  }

  static String formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(date);
  }
}
