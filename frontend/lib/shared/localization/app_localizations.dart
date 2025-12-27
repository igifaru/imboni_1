import 'package:flutter/material.dart';

/// Imboni App Localizations - Kinyarwanda-first
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('rw'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Note: rw (Kinyarwanda) is not in Flutter's Material library
  // We use en/fr for Material widgets but our translations handle rw
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  String get(String key) => _translations[locale.languageCode]?[key] ?? _translations['rw']![key] ?? key;

  // Common
  String get appName => get('app_name');
  String get welcome => get('welcome');
  String get submitCase => get('submit_case');
  String get trackCase => get('track_case');
  String get emergency => get('emergency');
  String get anonymous => get('anonymous');
  String get login => get('login');
  String get register => get('register');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get save => get('save');
  String get notifications => get('notifications');
  String get selectCategory => get('select_category');
  String get describeIssue => get('describe_issue');
  String get submitAnonymously => get('submit_anonymously');
  String get anonymousExplanation => get('anonymous_explanation');

  // Categories
  String get categoryJustice => get('category_justice');
  String get categoryHealth => get('category_health');
  String get categoryLand => get('category_land');
  String get categoryInfrastructure => get('category_infrastructure');
  String get categorySecurity => get('category_security');
  String get categorySocial => get('category_social');
  String get categoryEducation => get('category_education');
  String get categoryOther => get('category_other');

  // Status
  String get statusOpen => get('status_open');
  String get statusInProgress => get('status_in_progress');
  String get statusResolved => get('status_resolved');
  String get statusEscalated => get('status_escalated');

  // Levels
  String get levelVillage => get('level_village');
  String get levelCell => get('level_cell');
  String get levelSector => get('level_sector');
  String get levelDistrict => get('level_district');
  String get levelProvince => get('level_province');
  String get levelNational => get('level_national');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['rw', 'en', 'fr'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _translations = {
  'rw': {
    'app_name': 'Imboni',
    'welcome': 'Murakaza neza',
    'submit_case': 'Tanga ikibazo',
    'track_case': 'Kurikirana ikibazo',
    'emergency': 'Ubutabazi bwihutirwa',
    'anonymous': 'Uzigama amazina',
    'login': 'Kwinjira',
    'register': 'Kwiyandikisha',
    'cancel': 'Kureka',
    'confirm': 'Kwemeza',
    'save': 'Kubika',
    'notifications': 'Ubutumwa',
    'select_category': 'Hitamo icyiciro',
    'describe_issue': 'Sobanura ikibazo',
    'submit_anonymously': 'Tanga utavuze izina ryawe',
    'anonymous_explanation': 'Amazina yawe ntazamenyekana',
    'category_justice': 'Ubutabera',
    'category_health': 'Ubuzima',
    'category_land': 'Ubutaka',
    'category_infrastructure': 'Ibikorwa remezo',
    'category_security': 'Umutekano',
    'category_social': 'Imibereho',
    'category_education': 'Uburezi',
    'category_other': 'Ibindi',
    'status_open': 'Gifunguwe',
    'status_in_progress': 'Gikorwaho',
    'status_resolved': 'Cyakemutse',
    'status_escalated': 'Cyazamutse',
    'level_village': 'Umudugudu',
    'level_cell': 'Akagari',
    'level_sector': 'Umurenge',
    'level_district': 'Akarere',
    'level_province': 'Intara',
    'level_national': "Urwego rw'Igihugu",
  },
  'en': {
    'app_name': 'Imboni',
    'welcome': 'Welcome',
    'submit_case': 'Submit Case',
    'track_case': 'Track Case',
    'emergency': 'Emergency',
    'anonymous': 'Stay Anonymous',
    'login': 'Login',
    'register': 'Register',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'save': 'Save',
    'notifications': 'Notifications',
    'select_category': 'Select Category',
    'describe_issue': 'Describe Issue',
    'submit_anonymously': 'Submit Anonymously',
    'anonymous_explanation': 'Your identity will be protected',
    'category_justice': 'Justice',
    'category_health': 'Health',
    'category_land': 'Land',
    'category_infrastructure': 'Infrastructure',
    'category_security': 'Security',
    'category_social': 'Social',
    'category_education': 'Education',
    'category_other': 'Other',
    'status_open': 'Open',
    'status_in_progress': 'In Progress',
    'status_resolved': 'Resolved',
    'status_escalated': 'Escalated',
    'level_village': 'Village',
    'level_cell': 'Cell',
    'level_sector': 'Sector',
    'level_district': 'District',
    'level_province': 'Province',
    'level_national': 'National Level',
  },
  'fr': {
    'app_name': 'Imboni',
    'welcome': 'Bienvenue',
    'submit_case': 'Soumettre un cas',
    'track_case': 'Suivre le cas',
    'emergency': 'Urgence',
    'anonymous': 'Rester anonyme',
    'login': 'Connexion',
    'register': "S'inscrire",
    'cancel': 'Annuler',
    'confirm': 'Confirmer',
    'save': 'Sauvegarder',
    'notifications': 'Notifications',
    'select_category': 'Sélectionner une catégorie',
    'describe_issue': 'Décrire le problème',
    'submit_anonymously': 'Soumettre anonymement',
    'anonymous_explanation': 'Votre identité sera protégée',
    'category_justice': 'Justice',
    'category_health': 'Santé',
    'category_land': 'Terrain',
    'category_infrastructure': 'Infrastructure',
    'category_security': 'Sécurité',
    'category_social': 'Social',
    'category_education': 'Éducation',
    'category_other': 'Autre',
    'status_open': 'Ouvert',
    'status_in_progress': 'En cours',
    'status_resolved': 'Résolu',
    'status_escalated': 'Escaladé',
    'level_village': 'Village',
    'level_cell': 'Cellule',
    'level_sector': 'Secteur',
    'level_district': 'District',
    'level_province': 'Province',
    'level_national': 'Niveau National',
  },
};
