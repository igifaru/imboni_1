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
    Locale('rw'),
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
  
  // Registration Form
  String get registerNewLeader => get('register_new_leader');
  String get registerNewLeaderDesc => get('register_new_leader_desc');
  String get personalInfo => get('personal_info');
  String get addPhoto => get('add_photo');
  String get fullName => get('full_name');
  String get exampleName => get('example_name');
  String get nationalId => get('national_id');
  String get phoneNumber => get('phone_number');
  String get emailOptional => get('email_optional');
  String get roleAndLocation => get('role_and_location');
  String get leadershipRole => get('leadership_role');
  String get selectRole => get('select_role');
  String get workLocation => get('work_location');
  String get startDate => get('start_date');
  String get securityAndStatus => get('security_and_status');
  String get tempPassword => get('temp_password');
  String get accountStatus => get('account_status');
  String get active => get('active');
  String get inactive => get('inactive');
  String get copyPassword => get('copy_password');
  String get passwordCopied => get('password_copied');
  String get registrationSuccess => get('registration_success');
  String get registrationFailed => get('registration_failed');
  String get connectionError => get('connection_error');
  String get selectLevel => get('select_level');
  String get hintRoleSelect => get('hint_role_select');

  // Settings Screen
  String get settings => get('settings');
  String get myAccount => get('my_account');
  String get preferences => get('preferences');
  String get supportAbout => get('support_about');
  String get changePassword => get('change_password');
  String get logOut => get('log_out');
  String get language => get('language');
  String get theme => get('theme');
  String get darkMode => get('dark_mode');
  String get helpCenter => get('help_center');
  String get privacyPolicy => get('privacy_policy');
  String get aboutImboni => get('about_imboni');
  String get version => get('version');
  String get role => get('role');
  String get jurisdiction => get('jurisdiction');
  String get logoutConfirmTitle => get('logout_confirm_title');
  String get logoutConfirmContent => get('logout_confirm_content');
  String get emailNotifications => get('email_notifications');
  String get smsAlerts => get('sms_alerts');
  
  // Dashboard
  String get dashboard => get('dashboard');
  String get myCases => get('my_cases');
  String get alerts => get('alerts');
  String get performance => get('performance');

  // Admin Strings
  String get adminDashboard => get('admin_dashboard');
  String get home => get('home');
  String get users => get('users');
  String get userManagement => get('user_management');
  String get registerLeader => get('register_leader');
  String get searchUsersHint => get('search_users_hint');
  String get allUsers => get('all_users');
  String get leaders => get('leaders');
  String get citizens => get('citizens');
  String get retry => get('retry');
  String get noUsersFound => get('no_users_found'); 
  String get name => get('name');
  String get status => get('status');
  String get actions => get('actions');
  String get imboniAdmin => get('imboni_admin');
  
  // Dashboard Widgets
  String get searchCases => get('search_cases');
  String get urgent => get('urgent');
  // active is already defined
  String get escalated => get('escalated');
  String get godViewTitle => get('god_view_title');
  String get aiInsights => get('ai_insights');
  String get casesByProvince => get('cases_by_province');
  String get total => get('total');
  // statusOpen and statusResolved defined
  String get open => get('open'); // Short version for cards
  String get resolved => get('resolved'); // Short version for cards

  // Attachments / Evidence
  String get attachEvidence => get('attach_evidence');
  String get takePhoto => get('take_photo');
  String get gallery => get('gallery');
  String get video => get('video');
  String get document => get('document');
  String get noAttachments => get('no_attachments');
  String get maxFileSize => get('max_file_size');
  String get fileTooLarge => get('file_too_large');
  String get maxAttachmentsReached => get('max_attachments_reached');
  String get voiceNote => get('voice_note');
  String get voiceNoteRecorded => get('voice_note_recorded');
  String get delete => get('delete');
  String get recording => get('recording');
  String get tapToRecord => get('tap_to_record');
  String get tapToStop => get('tap_to_stop');
  String get ready => get('ready');
  String get microphonePermissionRequired => get('microphone_permission_required');
  String get evidence => get('evidence');
  String get addEvidence => get('add_evidence');
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
    // Registration Form RW
    'register_new_leader': 'Ongeraho Umuyobozi',
    'register_new_leader_desc': 'Ongeraho umuyobozi mushya muri sisitemu.',
    'personal_info': 'Amakuru Yihariye',
    'add_photo': 'Ongeraho Ifoto',
    'full_name': 'Amazina Yose',
    'example_name': 'Urugero: Mugabo Jean',
    'national_id': "Nimero y'Indangamuntu",
    'phone_number': 'Nimero ya Telefoni',
    'email_optional': 'Imell (Optional)',
    'role_and_location': "Inshingano n'Aho Akorera",
    'leadership_role': "Urwego rw'Ubuyobozi",
    'select_role': 'Hitamo Urwego',
    'work_location': 'Aho Akorera',
    'start_date': 'Itariki Yatangiriyeho',
    'security_and_status': 'Umutekano na Status',
    'temp_password': "Ijambo ry'Ibanga ry'Agateganyo",
    'account_status': 'Status ya Konti',
    'active': 'Active',
    'inactive': 'Inactive',
    'copy_password': "Kopia Ijambo ry'Ibanga",
    'password_copied': "Ijambo ry'Ibanga ryakopowe",
    'registration_success': 'Yanditswe neza nka Uyobora',
    'registration_failed': 'Kwiyandikisha byanze',
    'connection_error': 'Ikibazo cya interineti',
    'select_level': 'Hitamo',
    'hint_role_select': 'Hitamo Urwego (urugero: Umuyobozi w\'Umudugudu)',
    // User Management RW
    'user_management': 'Imicungire y\'Abakoresha',
    'search_users_hint': 'Shakisha izina, imeri, cyangwa inshingano...',
    'no_users_found': 'Nta mukoresha ubonetse',
    'all_users': 'Bose',
    'leaders': 'Abayobozi',
    'citizens': 'Abaturage',
    'name': 'Izina',
    'status': 'Status',
    'actions': 'Ibikorwa',
    'imboni_admin': 'Admin',
    // Settings RW
    'settings': 'Igenamiterere',
    'my_account': 'Konti Yanjye',
    'preferences': 'Ibyo Ukunda',
    'support_about': 'Ubufasha & Ibyerekeye',
    'change_password': 'Hindura Ijambo ry\'Ibanga',
    'log_out': 'Sohoka',
    'language': 'Ururimi',
    'theme': 'Insanganyamatsiko',
    'dark_mode': 'Mode Yijimye',
    'help_center': 'Ikigo cy\'Ubufasha',
    'privacy_policy': 'Politiki y\'Ibanga',
    'about_imboni': 'Ibyerekeye Imboni',
    'version': 'Verisiyo',
    'role': 'Inshingano',
    'jurisdiction': 'Ifasi',
    'logout_confirm_title': 'Gusohoka',
    'logout_confirm_content': 'Urahamya ko ushaka gusohoka?',
    'email_notifications': 'Ubutumwa bwa Email',
    'sms_alerts': 'Impuruza za SMS',
    
    // Dashboard RW
    'dashboard': 'Incamake',
    'my_cases': 'Ibibazo',
    'alerts': 'Imburira',
    'performance': 'Imikorere',
    // New Dashboard Keys RW
    'search_cases': 'Shakisha ibibazo...',
    'urgent': 'Byihutirwa',
    'escalated': 'Byazamuwe',
    'god_view_title': "Incamake y'Igihugu 'God View'",
    'ai_insights': 'Isesengura rya AI',
    'cases_by_province': 'Ibibazo mu Ntara',
    'total': 'Yose',
    'open': 'Gifunguye',
    'resolved': 'Cyakemutse',
    // Attachments RW
    'attach_evidence': 'Ongeraho Ibimenyetso',
    'take_photo': 'Fata Ifoto',
    'gallery': 'Fata mu Bubiko',
    'video': 'Video',
    'document': 'Inyandiko',
    'no_attachments': 'Nta bimenyetso byongewe',
    'max_file_size': 'Ingano ntarengwa',
    'file_too_large': 'Dosiye irenze ingano',
    'max_attachments_reached': 'Wagezeho ibimenyetso byinshi',
    'voice_note': 'Ijwi ry\'Icyemezo',
    'voice_note_recorded': 'Ijwi ryafashwe',
    'delete': 'Siba',
    'recording': 'Gufata ijwi...',
    'tap_to_record': 'Kanda kugirango ubone ijwi',
    'tap_to_stop': 'Kanda guhagarika',
    'ready': 'Byateguwe',
    'microphone_permission_required': 'Usabwa kwemererwa gukoresha microphone',
    'evidence': 'Ibimenyetso',
    'add_evidence': 'Ongeraho Ibimenyetso',
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
    // Registration Form EN
    'register_new_leader': 'Register New Leader',
    'register_new_leader_desc': 'Register a new leader in the system.',
    'personal_info': 'Personal Information',
    'add_photo': 'Add Photo',
    'full_name': 'Full Name',
    'example_name': 'Example: John Doe',
    'national_id': 'National ID',
    'phone_number': 'Phone Number',
    'email_optional': 'Email (Optional)',
    'role_and_location': 'Role and Location',
    'leadership_role': 'Leadership Role',
    'select_role': 'Select Role',
    'work_location': 'Work Location',
    'start_date': 'Start Date',
    'security_and_status': 'Security and Status',
    'temp_password': 'Temporary Password',
    'account_status': 'Account Status',
    'active': 'Active',
    'inactive': 'Inactive',
    'copy_password': 'Copy Password',
    'password_copied': 'Password Copied',
    'registration_success': 'Successfully registered Head of',
    'registration_failed': 'Registration failed',
    'connection_error': 'Connection error',
    'select_level': 'Select',
    'hint_role_select': 'Select Role (e.g., Village Leader)',
    // User Management EN
    'user_management': 'User Management',
    'search_users_hint': 'Search by name, email, or role...',
    'no_users_found': 'No users found',
    'all_users': 'All Users',
    'leaders': 'Leaders',
    'citizens': 'Citizens',
    'name': 'Name',
    'status': 'Status',
    'actions': 'Actions',
    'imboni_admin': 'Admin',
    // Settings EN
    'settings': 'Settings',
    'my_account': 'My Account',
    'preferences': 'Preferences',
    'support_about': 'Support & About',
    'change_password': 'Change Password',
    'log_out': 'Log Out',
    'language': 'Language',
    'theme': 'Theme',
    'dark_mode': 'Dark Mode',
    'help_center': 'Help Center',
    'privacy_policy': 'Privacy Policy',
    'about_imboni': 'About Imboni',
    'version': 'Version',
    'role': 'Role',
    'jurisdiction': 'Jurisdiction',
    'logout_confirm_title': 'Logout',
    'logout_confirm_content': 'Are you sure you want to logout?',
    'email_notifications': 'Email Notifications',
    'sms_alerts': 'SMS Alerts',

    // Dashboard EN
    'dashboard': 'Dashboard',
    'my_cases': 'Cases',
    'alerts': 'Alerts',
    'performance': 'Performance',
    // New Dashboard Keys EN
    'search_cases': 'Search cases...',
    'urgent': 'Urgent',
    'escalated': 'Escalated',
    'god_view_title': 'National "God View" Dashboard',
    'ai_insights': 'AI Insights',
    'cases_by_province': 'Cases by Province',
    'total': 'Total',
    'open': 'Open',
    'resolved': 'Resolved',
    // Attachments EN
    'attach_evidence': 'Attach Evidence',
    'take_photo': 'Take Photo',
    'gallery': 'Gallery',
    'video': 'Video',
    'document': 'Document',
    'no_attachments': 'No attachments added',
    'max_file_size': 'Max file size',
    'file_too_large': 'File is too large',
    'max_attachments_reached': 'Max attachments reached',
    'voice_note': 'Voice Note',
    'voice_note_recorded': 'Voice note recorded',
    'delete': 'Delete',
    'recording': 'Recording...',
    'tap_to_record': 'Tap to record',
    'tap_to_stop': 'Tap to stop',
    'ready': 'Ready',
    'microphone_permission_required': 'Microphone permission required',
    'evidence': 'Evidence',
    'add_evidence': 'Add Evidence',
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
    // Registration Form FR
    'register_new_leader': 'Inscrire un Nouveau Leader',
    'register_new_leader_desc': 'Inscrire un nouveau leader dans le système.',
    'personal_info': 'Informations Personnelles',
    'add_photo': 'Ajouter une Photo',
    'full_name': 'Nom Complet',
    'example_name': 'Exemple: Jean Dupont',
    'national_id': 'Identité Nationale',
    'phone_number': 'Numéro de Téléphone',
    'email_optional': 'Email (Optionnel)',
    'role_and_location': 'Rôle et Lieu',
    'leadership_role': 'Rôle de Leadership',
    'select_role': 'Sélectionner le Rôle',
    'work_location': 'Lieu de Travail',
    'start_date': 'Date de Début',
    'security_and_status': 'Sécurité et Statut',
    'temp_password': 'Mot de Passe Temporaire',
    'account_status': 'Statut du Compte',
    'active': 'Actif',
    'inactive': 'Inactif',
    'copy_password': 'Copier le Mot de Passe',
    'password_copied': 'Mot de Passe Copié',
    'registration_success': 'Chef enregistré avec succès pour',
    'registration_failed': "L'inscription a échoué",
    'connection_error': 'Erreur de connexion',
    'select_level': 'Sélectionner',
    'hint_role_select': 'Sélectionner le Rôle (ex: Chef de Village)',
    // User Management FR
    'user_management': 'Gestion des Utilisateurs',
    'search_users_hint': 'Rechercher par nom, email ou rôle...',
    'no_users_found': 'Aucun utilisateur trouvé',
    'all_users': 'Tous',
    'leaders': 'Chefs',
    'citizens': 'Citoyens',
    'name': 'Nom',
    'status': 'Statut',
    'actions': 'Actions',
    'imboni_admin': 'Admin',
    // Settings FR
    'settings': 'Paramètres',
    'my_account': 'Mon Compte',
    'preferences': 'Préférences',
    'support_about': 'Support & À propos',
    'change_password': 'Changer le Mot de Passe',
    'log_out': 'Se Déconnecter',
    'language': 'Langue',
    'theme': 'Thème',
    'dark_mode': 'Mode Sombre',
    'help_center': "Centre d'Aide",
    'privacy_policy': 'Politique de Confidentialité',
    'about_imboni': 'À propos de Imboni',
    'version': 'Version',
    'role': 'Rôle',
    'jurisdiction': 'Juridiction',
    'logout_confirm_title': 'Déconnexion',
    'logout_confirm_content': 'Êtes-vous sûr de vouloir vous déconnecter?',
    'email_notifications': 'Notifications Email',
    'sms_alerts': 'Alertes SMS',

    // Dashboard FR
    'dashboard': 'Tableau de bord',
    'my_cases': 'Dossiers',
    'alerts': 'Alertes',
    'performance': 'Performance',
    // New Dashboard Keys FR
    'search_cases': 'Rechercher des cas...',
    'urgent': 'Urgent',
    'escalated': 'Escalé',
    'god_view_title': 'Tableau de bord national',
    'ai_insights': 'Analyses IA',
    'cases_by_province': 'Cas par Province',
    'total': 'Total',
    'open': 'Ouvert',
    'resolved': 'Résolu',
    // Attachments FR
    'attach_evidence': 'Joindre des preuves',
    'take_photo': 'Prendre une photo',
    'gallery': 'Galerie',
    'video': 'Vidéo',
    'document': 'Document',
    'no_attachments': 'Aucune pièce jointe',
    'max_file_size': 'Taille max du fichier',
    'file_too_large': 'Fichier trop volumineux',
    'max_attachments_reached': 'Nombre max de pièces jointes atteint',
    'voice_note': 'Note vocale',
    'voice_note_recorded': 'Note vocale enregistrée',
    'delete': 'Supprimer',
    'recording': 'Enregistrement...',
    'tap_to_record': 'Appuyez pour enregistrer',
    'tap_to_stop': 'Appuyez pour arrêter',
    'ready': 'Prêt',
    'microphone_permission_required': 'Permission microphone requise',
    'evidence': 'Preuves',
    'add_evidence': 'Ajouter des preuves',
  },
};
