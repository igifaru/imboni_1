import 'package:flutter/material.dart';

/// Imboni Color Palette - Rwanda national colors
class ImboniColors {
  ImboniColors._();

  // Primary - Green (Rwanda flag)
  static const Color primary = Color(0xFF00A86B);
  static const Color primaryLight = Color(0xFF4DD9A0);
  static const Color primaryDark = Color(0xFF007A4D);

  // Secondary - Blue (Trust & Governance)
  static const Color secondary = Color(0xFF1E3A8A);
  static const Color secondaryLight = Color(0xFF3B5998);
  static const Color secondaryDark = Color(0xFF0F1F4A);

  // Accent - Yellow (Rwanda flag)
  static const Color accent = Color(0xFFFFC300);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Case Status Colors
  static const Color statusOpen = Color(0xFF3B82F6);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF22C55E);
  static const Color statusEscalated = Color(0xFFEF4444);
  static const Color statusClosed = Color(0xFF6B7280);

  // Urgency Colors
  static const Color urgencyNormal = Color(0xFF6B7280);
  static const Color urgencyHigh = Color(0xFFF59E0B);
  static const Color urgencyEmergency = Color(0xFFEF4444);

  // Category Colors
  static const Color categoryJustice = Color(0xFF8B5CF6);
  static const Color categoryHealth = Color(0xFFEC4899);
  static const Color categoryLand = Color(0xFF84CC16);
  static const Color categoryInfrastructure = Color(0xFFF97316);
  static const Color categorySecurity = Color(0xFFEF4444);
  static const Color categorySocial = Color(0xFF06B6D4);
  static const Color categoryEducation = Color(0xFF3B82F6);
  static const Color categoryOther = Color(0xFF6B7280);

  // Neutral Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // Dark Mode
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceVariantDark = Color(0xFF374151);
  static const Color outlineDark = Color(0xFF4B5563);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return statusOpen;
      case 'IN_PROGRESS': return statusInProgress;
      case 'RESOLVED': return statusResolved;
      case 'ESCALATED': return statusEscalated;
      case 'CLOSED': return statusClosed;
      default: return statusOpen;
    }
  }

  static Color getUrgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'EMERGENCY': return urgencyEmergency;
      case 'HIGH': return urgencyHigh;
      default: return urgencyNormal;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'JUSTICE': return categoryJustice;
      case 'HEALTH': return categoryHealth;
      case 'LAND': return categoryLand;
      case 'INFRASTRUCTURE': return categoryInfrastructure;
      case 'SECURITY': return categorySecurity;
      case 'SOCIAL': return categorySocial;
      case 'EDUCATION': return categoryEducation;
      default: return categoryOther;
    }
  }
}
