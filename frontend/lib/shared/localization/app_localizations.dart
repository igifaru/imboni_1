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
  String get dispute => get('dispute');
  String get save => get('save');
  String get submit => get('submit');
  String get notifications => get('notifications');
  String get resolved => get('resolved');
  String get caseResolved => get('case_resolved');
  String get caseEscalated => get('case_escalated');
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
  String get cameraNotSupported => get('camera_not_supported');
  String get recordingError => get('recording_error');

  // Case Details Screen
  String get caseDetails => get('case_details');
  String get importantInfo => get('important_info');
  String get location => get('location');
  String get level => get('level');
  String get date => get('date');
  String get time => get('time');
  String get deadline => get('deadline');
  String get description => get('description');
  String get reporter => get('reporter');
  String get submittedAnonymouslyLabel => get('submitted_anonymously_label');
  String get citizen => get('citizen');
  String get noEvidenceProvided => get('no_evidence_provided');
  String get timeline => get('timeline');
  String get caseCreated => get('case_created');
  String get caseEscalated => get('case_escalated');
  String get caseResolved => get('case_resolved');
  String get caseViewed => get('case_viewed');
  String get caseAssigned => get('case_assigned');
  String get caseAccepted => get('case_accepted');
  String get takeCase => get('take_case');
  String get resolveCase => get('resolve_case');
  String get escalate => get('escalate');
  String get escalateReason => get('escalate_reason');
  String get escalateHint => get('escalate_hint');
  String get actionSuccess => get('action_success');
  String get caseResolvedSuccess => get('case_resolved_success');
  String get caseEscalatedSuccess => get('case_escalated_success');
  String get urgencyNormal => get('urgency_normal');
  String get urgencyHigh => get('urgency_high');
  String get urgencyEmergency => get('urgency_emergency');

  // My Cases Screen
  String get myCasesTitle => get('my_cases_title');
  String get allCases => get('all_cases');
  String get openCases => get('open_cases');
  String get inProgressCases => get('in_progress_cases');
  String get resolvedCases => get('resolved_cases');
  String get noCasesFound => get('no_cases_found');
  String get errorOccurred => get('error_occurred');
  String get tryAgain => get('try_again');
  String get viewDetails => get('view_details');
  String get submittedOn => get('submitted_on');
  String get currentlyAt => get('currently_at');

  // Citizen Home Screen
  String get welcomeMessage => get('welcome_message');
  String get welcomeSubtitle => get('welcome_subtitle');
  String get yourCases => get('your_cases');
  String get submitCaseSubtitle => get('submit_case_subtitle');
  String get trackCaseSubtitle => get('track_case_subtitle');
  String get emergencySubtitle => get('emergency_subtitle');
  String get myCasesSubtitle => get('my_cases_subtitle');
  String get recentCases => get('recent_cases');
  String get viewAllCases => get('view_all_cases');
  String get noCasesYet => get('no_cases_yet');
  String get useSumbitCaseHint => get('use_submit_case_hint');

  // Track Case Screen
  String get trackCaseTitle => get('track_case_title');
  String get trackCaseHint => get('track_case_hint');
  String get enterReference => get('enter_reference');
  String get search => get('search');
  String get caseFound => get('case_found');
  String get caseNotFound => get('case_not_found');
  String get checkReferenceHint => get('check_reference_hint');
  String get currentLevel => get('current_level');

  // Profile Screen (additional keys not defined elsewhere)
  String get profile => get('profile');
  String get accountInfo => get('account_info');
  String get about => get('about');
  String get phone => get('phone');
  String get logout => get('logout');
  String get registeredOn => get('registered_on');
  String get residenceLocation => get('residence_location');
  String get email => get('email');
  String get editProfile => get('edit_profile');
  String get saveChanges => get('save_changes');
  String get termsAndConditions => get('terms_and_conditions');
  String get help => get('help');
  String get logoutConfirm => get('logout_confirm');
  String get yes => get('yes');
  String get no => get('no');
  String get profileSaved => get('profile_saved');
  String get saveFailed => get('save_failed');
  String get notProvided => get('not_provided');
  String get aboutApp => get('about_app');

  String get selectCategoryError => get('select_category_error');
  // Submit Case Screen
  String get processing => get('processing');
  String get problem => get('problem');
  // 'location' and 'selectCategory' already exist
  String get urgencyTitle => get('urgency_title');
  String get caseTitle => get('case_title');
  String get caseTitleHint => get('case_title_hint');
  String get caseTitleError => get('case_title_error');
  String get descHint => get('desc_hint');
  String get descError => get('desc_error');
  String get continueBtn => get('continue_btn');
  String get selectLocPrompt => get('select_loc_prompt');
  String get confirmLoc => get('confirm_loc');
  String get backBtn => get('back_btn');
  String get summary => get('summary');
  String get emergencyWarning => get('emergency_warning');
  String get uploadingDocs => get('uploading_docs');
  String get uploadingAudio => get('uploading_audio');
  String get partialSuccess => get('partial_success');
  String get successTitle => get('success_title');
  String get successMessage => get('success_message');
  String get trackingNumber => get('tracking_number');
  String get saveTrackingHint => get('save_tracking_hint');
  String get ok => get('ok');
  String get failed => get('failed');
  String get notificationsLabel => get('notifications_label');
  String get themeLabel => get('theme_label');
  
  // Assigned Cases Screen
  String get assignedCases => get('assigned_cases');
  String get searchHint => get('search_hint');
  String get sortNewest => get('sort_newest');
  String get sortOldest => get('sort_oldest');
  String get sortPriority => get('sort_priority');
  String get sortBy => get('sort_by');
  String get priority => get('priority'); // Reusing urgency_title if appropriate, but priority is used for sorting
  String get submitted => get('submitted');
  String get categoryLabel => get('category_label');

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
    'dispute': 'Kuregera',
    'save': 'Kubika',
    'submit': 'Ohereza',
    'resolved': 'Byakemutse',
    'notifications': 'Ubutumwa',
    'case_resolved': 'Ikibazo cyafunzwe. Murakoze!',
    'case_escalated': 'Ikibazo cyoherejwe ku rwego rwisumbuye',
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
    'assigned_cases': 'Ibibazo Byatanzwe',
    'search_hint': 'Shakisha ikibazo...',
    'sort_newest': 'Bya vuba',
    'sort_oldest': 'Bimaze igihe',
    'sort_priority': 'Uburemere',
    'sort_by': 'Tonganya:',
    'priority': 'Uburemere',
    'submitted': 'Yatanzwe',
    'category_label': 'Icyiciro',

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
    'camera_not_supported': 'Camera ntabwo ikunda kuri mudasobwa. Mwatuvugisha cyangwa mugahitamo ifoto isanzwe.',
    'recording_error': 'Ikibazo mu gufata amajwi.',
    // Case Details Screen RW
    'case_details': 'Ibisobanuro by\'Ikibazo',
    'important_info': 'Amakuru y\'Ingenzi',
    'location': 'Aho biri',
    'level': 'Urwego',
    'date': 'Itariki',
    'time': 'Igihe',
    'deadline': 'Itariki ntarengwa',
    'description': 'Ibisobanuro',
    'reporter': 'Uwabitangaje',
    'submitted_anonymously_label': 'Yatanze mu ibanga',
    'citizen': 'Umuturage',
    'no_evidence_provided': 'Nta bimenyetso byatanzwe',
    'timeline': 'Aho kigeze',
    'case_created': 'Cyatangajwe',
    'case_escalated': 'Cyoherejwe Hejuru',
    'case_resolved': 'Cyakemuwe',
    'case_viewed': 'Cyarebwe',
    'case_assigned': 'Cyatanzwe',
    'case_accepted': 'Cyemejwe',
    'take_case': 'Fata Iyi Dosiye',
    'resolve_case': 'Kemura Burundu',
    'escalate': 'Ohereza hejuru',
    'escalate_reason': 'Tanga impamvu iki kibazo kigomba koherezwa kurwego rwisumbuye:',
    'escalate_hint': 'Urugero: Nta bubasha dufite...',
    'action_success': 'Igikorwa cyagenze neza',
    'case_resolved_success': 'Ikibazo cyakemuwe!',
    'case_escalated_success': 'Ikibazo cyoherejwe hejuru!',
    'urgency_normal': 'Bisanzwe',
    'urgency_high': 'Byihutirwa',
    'urgency_emergency': 'Byihutirwa Cyane',
    // My Cases Screen RW
    'my_cases_title': 'Ibibazo byanjye',
    'all_cases': 'Byose',
    'open_cases': 'Bifunguwe',
    'in_progress_cases': 'Bikorwaho',
    'resolved_cases': 'Byakemutse',
    'no_cases_found': 'Nta kibazo kiraboneka',
    'error_occurred': 'Habaye ikosa',
    'try_again': 'Gerageza nanone',
    'view_details': 'Reba byose',
    'submitted_on': 'Cyatanzwe ku itariki',
    'currently_at': 'Kiri ku rwego rwa',
    // Citizen Home Screen RW
    'welcome_message': 'Murakaza neza kuri Imboni.',
    'welcome_subtitle': 'Tanga ikibazo cyawe, tugufashemo.',
    'your_cases': 'Ibibazo byawe',
    'submit_case_subtitle': 'Tanga ikibazo gishya',
    'track_case_subtitle': 'Kurikirana ikibazo',
    'emergency_subtitle': 'Ubutabazi bwihuse',
    'my_cases_subtitle': 'Reba ibibazo byawe',
    'recent_cases': 'Ibibazo byawe vuba',
    'view_all_cases': 'Reba byose',
    'no_cases_yet': 'Nta kibazo ufite',
    'use_submit_case_hint': 'Koresha "Tanga Ikibazo" hejuru kugirango utange ikibazo cyawe',
    // Track Case Screen RW
    'track_case_title': 'Kurikirana ikibazo',
    'track_case_hint': 'Andika nimero yawe yo gukurikirana',
    'enter_reference': 'Andika nimero',
    'search': 'Shakisha',
    'case_found': 'Ikibazo cyabonetse',
    'case_not_found': 'Ntibishoboye kuboneka',
    'check_reference_hint': 'Reba neza nimero wanditse',
    'current_level': 'Urwego ruri kugikoraho',
    // Profile Screen RW
    'profile': 'Umwirondoro',
    'account_info': 'Amakuru y\'Ikonti',
    'about': 'Ibyerekeye',
    'phone': 'Telefoni',
    'logout': 'Sohoka',
    'registered_on': 'Yiyandikishije',
    'residence_location': 'Aho abarizwa',
    'edit_profile': 'Hindura Umwirondoro',
    'save_changes': 'Bika Ibyahinduwe',
    'terms_and_conditions': 'Amategeko n\'Amabwiriza',
    'logout_confirm': 'Uzi neza ko ushaka gusohoka?',
    'yes': 'Yego',
    'no': 'Oya',
    'profile_saved': 'Umwirondoro wabitswe!',
    'save_failed': 'Byanze',
    'not_provided': 'Ntiyanditswe',
    'about_app': 'Ibyerekeye Porogaramu',
    'notifications_label': 'Menyesha',
    'theme_label': 'Insanganyamatsiko',
    // Submit Case Screen RW
    'processing': 'Gutunganya...',
    'problem': 'Ikibazo',
    'select_category_error': 'Hitamo icyiciro',
    'urgency_title': 'Ubukana',
    'case_title': 'Umutwe w\'ikibazo',
    'case_title_hint': 'Umutwe muto usobanura ikibazo',
    'case_title_error': 'Umutwe ugomba kuba nibura inyuguti 5',
    'desc_hint': 'Sobanura neza ikibazo cyawe',
    'desc_error': 'Ibisobanuro bigomba kuba nibura inyuguti 20',
    'continue_btn': 'Komeza',
    'select_loc_prompt': 'Hitamo aho ikibazo kibarizwa (aho cyabereye)',
    'confirm_loc': 'Aho ikibazo kibarizwa',
    'back_btn': 'Subira inyuma',
    'summary': 'Incamake',
    'emergency_warning': 'Ikibazo cy\'ubutabazi bwihutirwa kiremerwa vuba',
    'uploading_docs': 'Kohereza inyandiko...',
    'uploading_audio': 'Kohereza amajwi...',
    'partial_success': 'Ikibazo cyakiriwe, ariko ibimenyetso bimwe byanze',
    'success_title': 'Byagenze neza!',
    'success_message': 'Ikibazo cyawe cyoherejwe neza.',
    'tracking_number': 'Nimero yo gukurikirana:',
    'save_tracking_hint': 'Bika iyi nimero kugirango ukurikirane ikibazo cyawe.',
    'ok': 'Sawa',
    'failed': 'Byanze',
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
    'dispute': 'Dispute',
    'save': 'Save',
    'submit': 'Submit',
    'resolved': 'Resolved',
    'notifications': 'Notifications',
    'case_resolved': 'Case has been resolved. Thank you!',
    'case_escalated': 'Case escalated to next level',
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
    'camera_not_supported': 'Camera not supported on Desktop. Please upload a file.',
    'recording_error': 'Could not start recording.',
    // Case Details Screen EN
    'case_details': 'Case Details',
    'important_info': 'Important Information',
    'location': 'Location',
    'level': 'Level',
    'date': 'Date',
    'time': 'Time',
    'deadline': 'Deadline',
    'description': 'Description',
    'reporter': 'Reporter',
    'submitted_anonymously_label': 'Submitted anonymously',
    'citizen': 'Citizen',
    'no_evidence_provided': 'No evidence provided',
    'timeline': 'Timeline',
    'case_created': 'Created',
    'case_escalated': 'Escalated',
    'case_resolved': 'Resolved',
    'case_viewed': 'Viewed',
    'case_assigned': 'Assigned',
    'case_accepted': 'Accepted',
    'take_case': 'Take This Case',
    'resolve_case': 'Mark Resolved',
    'escalate': 'Escalate',
    'escalate_reason': 'Provide a reason for escalation:',
    'escalate_hint': 'Example: We do not have authority...',
    'action_success': 'Action completed successfully',
    'case_resolved_success': 'Case has been resolved!',
    'case_escalated_success': 'Case has been escalated!',
    'urgency_normal': 'Normal',
    'urgency_high': 'High',
    'urgency_emergency': 'Emergency',
    // My Cases Screen EN
    'my_cases_title': 'My Cases',
    'all_cases': 'All',
    'open_cases': 'Open',
    'in_progress_cases': 'In Progress',
    'resolved_cases': 'Resolved',
    'no_cases_found': 'No cases found',
    'error_occurred': 'An error occurred',
    'try_again': 'Try again',
    'view_details': 'View details',
    'submitted_on': 'Submitted on',
    'currently_at': 'Currently at',
    // Citizen Home Screen EN
    'welcome_message': 'Welcome to Imboni.',
    'welcome_subtitle': 'Submit your case, we will help you.',
    'your_cases': 'Your Cases',
    'submit_case_subtitle': 'Submit a new case',
    'track_case_subtitle': 'Track your case',
    'emergency_subtitle': 'Rapid assistance',
    'my_cases_subtitle': 'View your cases',
    'recent_cases': 'Recent Cases',
    'view_all_cases': 'View all',
    'no_cases_yet': 'No cases yet',
    'use_submit_case_hint': 'Use "Submit Case" above to submit your case',
    // Track Case Screen EN
    'track_case_title': 'Track Case',
    'track_case_hint': 'Enter your tracking number',
    'enter_reference': 'Enter reference',
    'search': 'Search',
    'case_found': 'Case found',
    'case_not_found': 'Could not be found',
    'check_reference_hint': 'Check the reference you entered',
    'current_level': 'Current level handling',
    // Profile Screen EN
    'profile': 'Profile',
    'account_info': 'Account Information',
    'about': 'About',
    'phone': 'Phone',
    'logout': 'Logout',
    'registered_on': 'Registered on',
    'residence_location': 'Residence Location',
    'edit_profile': 'Edit Profile',
    'save_changes': 'Save Changes',
    'terms_and_conditions': 'Terms and Conditions',
    'logout_confirm': 'Are you sure you want to logout?',
    'yes': 'Yes',
    'no': 'No',
    'profile_saved': 'Profile saved!',
    'save_failed': 'Save failed',
    'not_provided': 'Not provided',
    'about_app': 'About App',
    'notifications_label': 'Notifications',
    'theme_label': 'Theme',
    // Assigned Cases EN
    'assigned_cases': 'Assigned Cases',
    'search_hint': 'Search cases...',
    'sort_newest': 'Newest First',
    'sort_oldest': 'Oldest First',
    'sort_priority': 'Priority',
    'sort_by': 'Sort by:',
    'priority': 'Priority',
    'submitted': 'Submitted',
    'category_label': 'Category',

    // Submit Case Screen EN
    'processing': 'Processing...',
    'problem': 'Problem',
    'select_category_error': 'Select category',
    'urgency_title': 'Urgency',
    'case_title': 'Case Title',
    'case_title_hint': 'Short title describing the issue',
    'case_title_error': 'Title must be at least 5 characters',
    'desc_hint': 'Describe your issue in detail',
    'desc_error': 'Description must be at least 20 characters',
    'continue_btn': 'Continue',
    'select_loc_prompt': 'Select where the issue is located',
    'confirm_loc': 'Issue Location',
    'back_btn': 'Back',
    'summary': 'Summary',
    'emergency_warning': 'Emergency cases are handled immediately',
    'uploading_docs': 'Uploading documents...',
    'uploading_audio': 'Uploading audio...',
    'partial_success': 'Case received, but some evidence failed to upload',
    'success_title': 'Success!',
    'success_message': 'Your case has been submitted successfully.',
    'tracking_number': 'Tracking Number:',
    'save_tracking_hint': 'Save this number to track your case.',
    'ok': 'OK',
    'failed': 'Failed',
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
    'dispute': 'Contester',
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
    'add_evidence': 'Ajouter une preuve',
    'camera_not_supported': 'Caméra non prise en charge sur l\'ordinateur. Veuillez télécharger un fichier.',
    'recording_error': 'Impossible de démarrer l\'enregistrement.',
    // Case Details Screen FR
    'case_details': 'Détails du Cas',
    'important_info': 'Informations Importantes',
    'location': 'Lieu',
    'level': 'Niveau',
    'date': 'Date',
    'time': 'Heure',
    'deadline': 'Date limite',
    'description': 'Description',
    'reporter': 'Rapporteur',
    'submitted_anonymously_label': 'Soumis anonymement',
    'citizen': 'Citoyen',
    'no_evidence_provided': 'Aucune preuve fournie',
    'timeline': 'Chronologie',
    'case_created': 'Créé',
    'case_escalated': 'Escaladé',
    'case_resolved': 'Résolu',
    'case_viewed': 'Consulté',
    'case_assigned': 'Assigné',
    'case_accepted': 'Accepté',
    'take_case': 'Prendre ce Cas',
    'resolve_case': 'Marquer Résolu',
    'escalate': 'Escalader',
    'escalate_reason': 'Indiquez la raison de l\'escalade:',
    'escalate_hint': 'Exemple: Nous n\'avons pas l\'autorité...',
    'action_success': 'Action effectuée avec succès',
    'case_resolved_success': 'Le cas a été résolu!',
    'case_escalated_success': 'Le cas a été escaladé!',
    'urgency_normal': 'Normal',
    'urgency_high': 'Élevé',
    'urgency_emergency': 'Urgence',
    // My Cases Screen FR
    'my_cases_title': 'Mes Dossiers',
    'all_cases': 'Tous',
    'open_cases': 'Ouverts',
    'in_progress_cases': 'En cours',
    'resolved_cases': 'Résolus',
    'no_cases_found': 'Aucun dossier trouvé',
    'error_occurred': 'Une erreur est survenue',
    'try_again': 'Réessayer',
    'view_details': 'Voir détails',
    'submitted_on': 'Soumis le',
    'currently_at': 'Actuellement à',
    // Citizen Home Screen FR
    'welcome_message': 'Bienvenue sur Imboni.',
    'welcome_subtitle': 'Soumettez votre cas, nous vous aiderons.',
    'your_cases': 'Vos Dossiers',
    'submit_case_subtitle': 'Soumettre un nouveau cas',
    'track_case_subtitle': 'Suivre votre cas',
    'emergency_subtitle': 'Assistance rapide',
    'my_cases_subtitle': 'Voir vos dossiers',
    'recent_cases': 'Dossiers Récents',
    'view_all_cases': 'Voir tout',
    'no_cases_yet': 'Pas encore de dossiers',
    'use_submit_case_hint': 'Utilisez "Soumettre un cas" ci-dessus pour soumettre votre dossier',
    // Track Case Screen FR
    'track_case_title': 'Suivre le Cas',
    'track_case_hint': 'Entrez votre numéro de suivi',
    'enter_reference': 'Entrer la référence',
    'search': 'Rechercher',
    'case_found': 'Cas trouvé',
    'case_not_found': 'Introuvable',
    'check_reference_hint': 'Vérifiez la référence entrée',
    'current_level': 'Niveau actuel',
    // Profile Screen FR
    'profile': 'Profil',
    'account_info': 'Informations du Compte',
    'about': 'À propos',
    'phone': 'Téléphone',
    'logout': 'Déconnexion',
    'registered_on': 'Inscrit le',
    'residence_location': 'Lieu de Résidence',
    'edit_profile': 'Modifier le Profil',
    'save': 'Enregistrer',
    'submit': 'Soumettre',
    'resolved': 'Résolu',
    'case_resolved': 'Le dossier a été résolu. Merci!',
    'case_escalated': 'Dossier transmis au niveau supérieur',
    'save_changes': 'Enregistrer les Modifications',
    'terms_and_conditions': 'Termes et Conditions',
    'logout_confirm': 'Voulez-vous vraiment vous déconnecter?',
    'yes': 'Oui',
    'no': 'Non',
    'profile_saved': 'Profil enregistré!',
    'save_failed': 'Échec de l\'enregistrement',
    'not_provided': 'Non fourni',
    'about_app': 'À propos de l\'Application',
    'notifications_label': 'Notifications',
    'theme_label': 'Thème',
    // Assigned Cases FR
    'assigned_cases': 'Dossiers Assignés',
    'search_hint': 'Rechercher...',
    'sort_newest': 'Plus récents',
    'sort_oldest': 'Plus anciens',
    'sort_priority': 'Priorité',
    'sort_by': 'Trier par:',
    'priority': 'Priorité',
    'submitted': 'Soumis',
    'category_label': 'Catégorie',

    // Submit Case Screen FR
    'processing': 'Traitement...',
    'problem': 'Problème',
    'select_category_error': 'Sélectionner une catégorie',
    'urgency_title': 'Urgence',
    'case_title': 'Titre du Dossier',
    'case_title_hint': 'Titre court décrivant le problème',
    'case_title_error': 'Le titre doit contenir au moins 5 caractères',
    'desc_hint': 'Décrivez votre problème en détail',
    'desc_error': 'La description doit contenir au moins 20 caractères',
    'continue_btn': 'Continuer',
    'select_loc_prompt': 'Sélectionnez où se situe le problème',
    'confirm_loc': 'Lieu du Problème',
    'back_btn': 'Retour',
    'summary': 'Résumé',
    'emergency_warning': 'Les cas d\'urgence sont traités immédiatement',
    'uploading_docs': 'Chargement des documents...',
    'uploading_audio': 'Chargement de l\'audio...',
    'partial_success': 'Cas reçu, mais certaines preuves n\'ont pas pu être téléchargées',
    'success_title': 'Succès!',
    'success_message': 'Votre cas a été soumis avec succès.',
    'tracking_number': 'Numéro de Suivi:',
    'save_tracking_hint': 'Enregistrez ce numéro pour suivre votre cas.',
    'ok': 'D\'accord',
    'failed': 'Échoué',
  },
};
