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
  String get statusClosed => get('status_closed');

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
  String get invalidEmail => get('invalid_email');
  String get nidRequired => get('nid_required');
  String get nidLengthError => get('nid_length_error');
  String get phoneRequired => get('phone_required');
  String get invalidPhone => get('invalid_phone');

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
  String get banks => get('banks');
  String get bankManagement => get('bank_management');
  String get financialServices => get('financial_services');
  String get secureBankingSupport => get('secure_banking_support');
  String get bankingSupportDesc => get('banking_support_desc');
  String get selectBank => get('select_bank');
  String get bankingComplaints => get('banking_complaints');
  String get financialHelp => get('financial_help');
  String get myRecentComplaints => get('my_recent_complaints');
  String get bankComplaint => get('bank_complaint');
  String get registerNewBank => get('register_new_bank');
  String get addBank => get('add_bank');
  String get bankName => get('bank_name');
  String get bankCode => get('bank_code');
  String get headOfficeLocationLabel => get('head_office_location');
  String get contactEmail => get('contact_email');
  String get contactPhone => get('contact_phone');
  String get totalBanks => get('total_banks');
  String get activeBranches => get('active_branches');
  String get noBanksYet => get('no_banks_yet');
  String get addBankHint => get('add_bank_hint');
  String get bankCodeLabel => get('bank_code_label');
  String get statusReceived => get('status_received');
  String get statusUnderReview => get('status_under_review');
  String get statusInvestigation => get('status_investigation');
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
  String get fillAllFields => get('fill_all_fields');
  String get submissionFailed => get('submission_failed');
  String get complaintSubmittedSuccess => get('complaint_submitted_success');
  String get referenceCode => get('reference_code');
  String get backToHome => get('back_to_home');
  String get reportTo => get('report_to');
  String get bankCaseDetails => get('bank_case_details');
  String get selectBranch => get('select_branch');
  String get serviceCategory => get('service_category');
  String get describeIssueHint => get('describe_issue_hint');
  String get branchNameLabel => get('branch_name');
  String get serviceExampleHint => get('service_example_hint');
  String get enterDetailsHint => get('enter_details_hint');
  String get submitComplaint => get('submit_complaint');
  String get addBankService => get('add_bank_service');
  String get serviceNameHint => get('service_name_hint');
  String get addBtn => get('add_btn');
  String get registerNewBranch => get('register_new_branch');
  String get detailedAddress => get('detailed_address');
  String get branchPhone => get('branch_phone');
  String get branchesList => get('branches_list');
  String get servicesList => get('services_list');
  String get noBranchesHint => get('no_branches_hint');
  String get noServicesHint => get('no_services_hint');
  String get branchesTab => get('branches_tab');
  String get serviceCatalogTab => get('service_catalog_tab');
  String get authorizedBranches => get('authorized_branches');
  String get newBranchBtn => get('new_branch_btn');
  String get registeredServices => get('registered_services');
  String get hqLabel => get('hq_label');
  String get noDescription => get('no_description');
  
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
  // statusOpen and statusResolved defined above
  String get open => get('open'); // Short version for cards
  // resolved defined above
  // resolved defined above
  String get statusUpdate => get('status_update');
  String get resolution => get('resolution');
  // Attachments / Evidence
  String get attachEvidence => get('attach_evidence');
  String get takePhoto => get('take_photo');
  String get gallery => get('gallery');
  String get video => get('video');
  String get document => get('document');
  String get noAttachments => get('no_attachments');
  String get maxFileSize => get('max_file_size');
  String get confirmResolutionContent => get('confirm_resolution_content');
  String get reasonForDispute => get('reason_for_dispute');
  String get pendingConfirmation => get('pending_confirmation');
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
  // caseEscalated, caseResolved already defined above
  // String get caseResolved => get('case_resolved');
  // String get caseEscalated => get('case_escalated');
  String get caseViewed => get('case_viewed');
  String get caseAssigned => get('case_assigned');
  String get caseAccepted => get('case_accepted');
  String get caseStatusUpdate => get('case_status_update');
  String get caseAssignment => get('case_assignment');

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
  String get assignedTo => get('assigned_to');
  
  String get escalationIn => get('escalation_in');
  String get overdue => get('overdue');
  
  String get resolutionActionDesc => get('resolution_action_desc');
  String get statusChangedTo => get('status_changed_to');
  
  // Manual Assignment Dialog
  String get assignCaseTitle => get('assign_case_title');
  String get selectLeaderLabel => get('select_leader_label');
  String get chooseLeaderHint => get('choose_leader_hint');
  String get setDeadlineLabel => get('set_deadline_label');
  String get noActiveLeadersError => get('no_active_leaders_error');
  String get assignBtn => get('assign_btn');
  String get selectDateTime => get('select_date_time');

  // Extend Deadline
  String get extendDeadline => get('extend_deadline');
  String get extendDeadlineTitle => get('extend_deadline_title');
  String get daysLabel => get('days_label');
  String get extensionLimitError => get('extension_limit_error');
  String get extensionSuccess => get('extension_success');
  String get extensionReasonLabel => get('extension_reason_label');
  String get extensionReasonHint => get('extension_reason_hint');
  
  // Timeline Notes
  String get noteManualAssignment => get('note_manual_assignment');
  String get noteDeadlineExtended => get('note_deadline_extended'); // Expects argument replacement in UI logic
  String get noteReason => get('note_reason');
  String get noteExtensionCount => get('note_extension_count');

  String get daySingular => get('day_singular');
  String get dayPlural => get('day_plural');
  String get assignToStaff => get('assign_to_staff');
  String get extensionsRemaining => get('extensions_remaining');


  // Community
  String get communityTitle => get('community_title');
  String get community => get('community');
  String get communitySubtitle => get('community_subtitle');
  String get channels => get('channels');
  String get typeMessage => get('type_message');
  String get members => get('members');
  String get general => get('general');

  // Community - Collaborative List
  String get selectUnitHint => get('select_unit_hint');
  String get viewList => get('view_list');
  String get addYourEntry => get('add_your_entry');
  String get addEntry => get('add_entry');
  String get editEntry => get('edit_entry');
  String get noEntriesYet => get('no_entries_yet');
  String get editListStructure => get('edit_list_structure');
  String get listTitle => get('list_title');
  String get columnsLabel => get('columns_label');
  String get addColumn => get('add_column');
  String get createList => get('create_list');
  String get createCollaborativeList => get('create_collaborative_list');
  String get columnsCommaSeparated => get('columns_comma_separated');
  String get columnsDataWarning => get('columns_data_warning');
  String get entries => get('entries');
  String get exportAsExcel => get('export_as_excel');
  String get exportAsCsv => get('export_as_csv');
  String get exportFailed => get('export_failed');
  String get excelExportFailed => get('excel_export_failed');
  String get editTitleColumns => get('edit_title_columns');
  String get fillAtLeastOneField => get('fill_at_least_one_field');
  String get enterListTitle => get('enter_list_title');
  String get provideAtLeastOneColumn => get('provide_at_least_one_column');

  // Community - Poll
  String get createPoll => get('create_poll');
  String get question => get('question');
  String get askSomething => get('ask_something');
  String get options => get('options');
  String get addOption => get('add_option');
  String get allowMultipleAnswers => get('allow_multiple_answers');
  String get enterQuestion => get('enter_question');
  String get provideAtLeastTwoOptions => get('provide_at_least_two_options');
  String get poll => get('poll');
  String get newPoll => get('new_poll');
  String get votes => get('votes');
  String get vote => get('vote');
  String get voted => get('voted');

  // Community - Message Actions
  String get actionCopy => get('action_copy');
  String get actionReply => get('action_reply');
  String get actionPin => get('action_pin');
  String get actionEdit => get('action_edit');
  String get actionDelete => get('action_delete');
  String get actionInfo => get('action_info');
  String get close => get('close');
  String get pinned => get('pinned');
  String get unknown => get('unknown');
  String get you => get('you');
  String get user => get('user');
  String get clickToRemove => get('click_to_remove');
  String get all => get('all');
  String get userNotFound => get('user_not_found');

  // Community - Emoji Picker
  String get searchEmoji => get('search_emoji');
  String get noEmojisFound => get('no_emojis_found');

  // Community - Attachments
  String get documentLabel => get('document_label');
  String get listLabel => get('list_label');
  String get newList => get('new_list');
  String get columnHint => get('column_hint');
  String get optionHint => get('option_hint');

  // PFTCV - Public Fund Transparency
  String get publicFunds => get('public_funds');
  String get publicFundsSubtitle => get('public_funds_subtitle');

  // Performance Analytics
  String get performanceAnalytics => get('performance_analytics');
  String get performanceSubtitle => get('performance_subtitle');
  String get resolutionRate => get('resolution_rate');
  String get avgResponseTime => get('avg_response_time');
  String get escalationRate => get('escalation_rate');
  String get overdueCases => get('overdue_cases');
  String get weeklyPerformance => get('weekly_performance');
  String get newVsResolved => get('new_vs_resolved');
  String get casesByCategory => get('cases_by_category');
  String get regionalBreakdown => get('regional_breakdown');
  String get timeRange => get('time_range');
  String get allLocations => get('all_locations');
  String get allCategories => get('all_categories');
  String get exportReport => get('export_report');
  String get target => get('target');
  String get exceededSla => get('exceeded_sla');
  String get failingResolution => get('failing_resolution');
  String get newCases => get('new_cases');
  String get noDataAvailable => get('no_data_available');
  String get noActivityLastWeek => get('no_activity_last_week');
  String get onTrack => get('on_track');
  String get atRisk => get('at_risk');
  String get region => get('region');
  String get totalCases => get('total_cases');
  String get resRate => get('res_rate');
  String get avgTime => get('avg_time');

  // Case Edit
  String get editCase => get('edit_case');
  String get editCaseTitle => get('edit_case_title');
  String get editCaseDescription => get('edit_case_description');
  String get caseUpdatedSuccess => get('case_updated_success');
  String get cannotEditCase => get('cannot_edit_case');
  String get caseMustBeOpen => get('case_must_be_open');

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
    'status_closed': 'Cyafunzwe',
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
    'invalid_email': 'Imeli ntabwo ariyo',
    'nid_required': 'Indangamuntu irakenewe',
    'nid_length_error': 'Igomba kuba imibare 16',
    'phone_required': 'Telefoni irakenewe',
    'invalid_phone': 'Nimero ntabwo ariyo (urugero: 078...)',
    // User Management RW
    'user_management': 'Imicungire y\'Abakoresha',
    'register_leader': 'Kwinjiza Umuyobozi',
    'banks': 'Amabanki',
    'bank_management': 'Imicungire y\'Amabanki',
    'financial_services': 'Serivisi z\'Imari',
    'secure_banking_support': 'Ubufasha mu by\'Imari',
    'banking_support_desc': 'Tanga ikibazo ufite muri banki yawe binyuze kuri Imboni.',
    'select_bank': 'Hitamo Banki',
    'banking_complaints': 'Ibibazo bya Banki',
    'financial_help': 'Ubufasha mu by\'Imari',
    'my_recent_complaints': 'Ibibazo biheruka',
    'bank_complaint': 'Ikirego cya Banki',
    'status_received': 'Iyakiriwe',
    'status_under_review': 'Irasuzumwa',
    'status_investigation': 'Irakurikiranwa',
    'search_users_hint': 'Shakisha izina, imeri, cyangwa inshingano...',
    'no_users_found': 'Nta mukoresha ubonetse',
    'all_users': 'Bose',
    'leaders': 'Abayobozi',
    'citizens': 'Abaturage',
    'name': 'Izina',
    'status': 'Status',
    'actions': 'Ibikorwa',
    'imboni_admin': 'Admin',
    'register_new_bank': 'Kwandika Banki Nshya',
    'add_bank': 'Ongeraho Banki',
    'bank_name': 'Izina rya Banki',
    'bank_code': 'Icode ya Banki',
    'head_office_location': 'Icyicaro Gikuru',
    'contact_email': 'Imeri yo kuvugana',
    'contact_phone': 'Telefoni yo kuvugana',
    'total_banks': 'Amabanki Yose',
    'active_branches': 'Amashami Akora',
    'no_banks_yet': 'Nta banki zanditswe ziraboneka.',
    'add_bank_hint': 'Kanda "Ongeraho Banki" kugirango utangire.',
    'bank_code_label': 'Icode',
    'fill_all_fields': 'Uzuza imyanya yose',
    'submission_failed': 'Kohereza byanze',
    'complaint_submitted_success': 'Ikirego cyoherejwe neza',
    'reference_code': 'Nimero y\'ikirego',
    'back_to_home:': 'Subira Ahabanza',
    'report_to': 'Tanga ikirego kuri',
    'bank_case_details': 'Ibigize ikirego cya banki',
    'select_branch': 'Hitamo Ishami',
    'service_category': 'Icyiciro cya Serivisi',
    'describe_issue_hint': 'Andika ibyabaye...',
    'branch_name': 'Izina ry\'Ishami',
    'service_example_hint': 'Urugero: ATM, Konti...',
    'enter_details_hint': 'Andika ibisobanuro hano...',
    'submit_complaint': 'Ohereza Ikirego',
    'add_bank_service': 'Ongeraho Serivisi',
    'service_name_hint': 'Izina rya Serivisi (urugero: ATM Dispute)',
    'add_btn': 'Ongeraho',
    'register_new_branch': 'Kwinjiza Ishami Rishya',
    'detailed_address': 'Aderese Imbere',
    'branch_phone': 'Telefoni y\'Ishami',
    'branches_list': 'Urutonde rw\'Amashami',
    'services_list': 'Urutonde rwa Serivisi',
    'no_branches_hint': 'Nta mashami yanditswe.',
    'no_services_hint': 'Nta serivisi zanditswe.',
    'branches_tab': 'Amashami',
    'service_catalog_tab': 'Serivisi',
    'authorized_branches': 'Amashami Yemewe',
    'new_branch_btn': 'Ishami Rishya',
    'registered_services': 'Serivisi Zanditswe',
    'hq_label': 'Icyicaro',
    'no_description': 'Nta bisobanuro',
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
    'jurisdiction': 'urwego',
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
    'assigned_to': 'Yatanzwe kuri',

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
    'open': 'Biracyakora',
    // resolved and closed defined above
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
    // case_escalated defined above
    // case_resolved defined above
    'case_viewed': 'Cyarebwe',
    'case_assigned': 'Cyatanzwe',
    'case_accepted': 'Cyemejwe',
    'case_status_update': 'Ivugururwa rya Status',
    'case_assignment': 'Igikorwa cyo Gutanga',

    'take_case': 'Fata Iyi Dosiye',
    'resolve_case': 'Kemura Burundu',
    'escalate': 'Ohereza hejuru',
    'escalate_reason': 'Tanga impamvu iki kibazo kigomba koherezwa kurwego rwisumbuye:',
    'escalate_hint': 'Urugero: Nta bubasha dufite...',
    'action_success': 'Igikorwa cyagenze neza',
    'case_resolved_success': 'Ikibazo cyakemuwe!',
    'case_escalated_success': 'Ikibazo cyoherejwe hejuru!',
    'status_update': 'Ivugurura',
    'resolution': 'Umwanzuro',
    'confirm_resolution_content': 'Urahamya ko iki kibazo cyakemutse? Ibi ntibizasubizwa inyuma.',
    'reason_for_dispute': 'Impamvu yo kuregera',
    'pending_confirmation': 'Hakenewe kwemeza umwanzuro',
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
    'escalation_in': 'Kizazamurwa mu',
    'overdue': 'Cyarengeje igihe',
    'resolution_action_desc': 'Umuyobozi yagaragaje ko iki kibazo cyakemutse. Niba mwanyuzwe, muremeze. Niba bitara kemuka, mushobora kuregera.',
    'status_changed_to': 'Imiterere yahindutse ikaba',
    // Community RW
    'community_title': 'Ihuza ry\'Abaturage',
    'community': 'Abaturage',
    'community_subtitle': 'Huza n\'abaturanyi',
    'channels': 'Imiyoboro',
    'type_message': 'Andika ubutumwa...',
    'members': 'Abanyamuryango',
    'general': 'Rusange',
    
    // Community - Collaborative List RW
    'select_unit_hint': 'Hitamo urwego ibumoso kugirango urebe ibiganiro',
    'view_list': 'Reba Urutonde',
    'add_your_entry': 'Ongeraho Umurongo Wawe',
    'add_entry': 'Ongeraho Umurongo',
    'edit_entry': 'Hindura Umurongo',
    'no_entries_yet': 'Nta murongo uriho',
    'edit_list_structure': 'Hindura Imiterere y\'Urutonde',
    'list_title': 'Izina ry\'Urutonde',
    'columns_label': 'Inkingi',
    'add_column': 'Ongeraho Inkingi',
    'create_list': 'Kora Urutonde',
    'create_collaborative_list': 'Kora Urutonde rw\'Ubufatanye',
    'columns_comma_separated': 'Inkingi (zitandukanywa na koma)',
    'columns_data_warning': 'Guhindura inkingi bishobora kugira ingaruka ku makuru ahari',
    'entries': 'imirongo',
    'export_as_excel': 'Kuramo nka Excel',
    'export_as_csv': 'Kuramo nka CSV',
    'export_failed': 'Gukuramo byanze',
    'excel_export_failed': 'Gukuramo Excel byanze',
    'edit_title_columns': 'Hindura Izina/Inkingi',
    'fill_at_least_one_field': 'Uzuza nibura umurongo umwe',
    'enter_list_title': 'Andika izina ry\'urutonde',
    'provide_at_least_one_column': 'Tanga nibura inkingi imwe',

    // Community - Poll RW
    'create_poll': 'Kora Itora',
    'question': 'Ikibazo',
    'ask_something': 'Baza ikintu...',
    'options': 'Amahitamo',
    'add_option': 'Ongeraho Ihitamo',
    'allow_multiple_answers': 'Emera ibisubizo byinshi',
    'enter_question': 'Andika ikibazo',
    'provide_at_least_two_options': 'Tanga nibura amahitamo abiri',
    'poll': 'Itora',
    'new_poll': 'Itora Rishya',
    'votes': 'amajwi',
    'vote': 'Tora',
    'voted': 'Watowe',

    // Community - Message Actions RW
    'action_copy': 'Gukoporora',
    'action_reply': 'Gusubiza',
    'action_pin': 'Gufatanisha',
    'action_edit': 'Guhindura',
    'action_delete': 'Gusiba',
    'action_info': 'Amakuru',
    'close': 'Funga',
    'pinned': 'Byafatanishijwe',
    'unknown': 'Kitazwi',
    'you': 'Wowe',
    'user': 'Umukoresha',
    'click_to_remove': 'Kanda kugirango ukureho',
    'all': 'Byose',
    'user_not_found': 'Umukoresha ntabonetse',

    // Community - Emoji Picker RW
    'search_emoji': 'Shakisha emoji',
    'no_emojis_found': 'Nta emoji yabonetse',

    // Community - Attachments RW
    'document_label': 'Inyandiko',
    'list_label': 'Urutonde',
    'new_list': 'Urutonde Rushya',
    'column_hint': 'Inkingi',
    'option_hint': 'Ihitamo',

    // PFTCV RW
    'public_funds': 'Imari ya Leta',
    'public_funds_subtitle': 'Genzura imishinga ya Leta',
    // Assignment Dialog RW
    'assign_case_title': 'Gutanga Ikibazo',
    'select_leader_label': 'Hitamo Umuyobozi',
    'choose_leader_hint': 'Hitamo umuyobozi muri uru rwego',
    'set_deadline_label': 'Hitamo Igihe Ntarengwa',
    'no_active_leaders_error': 'Nta muyobozi wabonetse muri uru rwego',
    'assign_btn': 'Tanga',
    'select_date_time': 'Hitamo Itariki n\'Igihe',

    // Extend Deadline RW
    'extend_deadline': 'Kongera Igihe',
    'extend_deadline_title': 'Kongera Igihe Ntarengwa',
    'days_label': 'Iminsi (Max 3)',
    'extension_limit_error': 'Ntushobora kongera igihe kurenza inshuro 2',
    'extension_success': 'Igihe cyongerewe neza',
    'extension_reason_label': 'Impamvu yo kongera',
    'extension_reason_hint': 'Sobanura impamvu ukeneye kongera igihe...',

    'note_manual_assignment': 'Yatanzwe n\'umuyobozi',
    'note_deadline_extended': 'Igihe cyongereweho iminsi',
    'note_reason': 'Impamvu',
    'note_extension_count': 'Inshuro',

    'day_singular': 'Umunsi',
    'day_plural': 'Iminsi',
    'assign_to_staff': 'Ohereza ku mukozi',
    'extensions_remaining': 'Inshuro zisigaye',

    // Performance Analytics RW
    'performance_analytics': 'Isesengura ry\'Imikorere',
    'performance_subtitle': 'Ibipimo by\'imikorere n\'ubushobozi bw\'abayobozi',
    'resolution_rate': 'Igipimo cy\'Ibisobanuro',
    'avg_response_time': 'Igihe cy\'Igisubizo',
    'escalation_rate': 'Igipimo cy\'Izamura',
    'overdue_cases': 'Ibibazo Byarenze',
    'weekly_performance': 'Imikorere y\'Icyumweru',
    'new_vs_resolved': 'Bishya vs Byakemutse',
    'cases_by_category': 'Ibibazo ku Cyiciro',
    'regional_breakdown': 'Isesengura ry\'Uturere',
    'time_range': 'Igihe',
    'all_locations': 'Ahantu hose',
    'all_categories': 'Ibyiciro byose',
    'export_report': 'Kuramo Raporo',
    'target': 'Intego',
    'exceeded_sla': 'Byarenze igihe',
    'failing_resolution': 'Bitakemuka',
    'new_cases': 'Ibibazo bishya',
    'no_data_available': 'Nta makuru ahari',
    'no_activity_last_week': 'Nta bikorwa muri iki cyumweru',
    'on_track': 'Bigenda neza',
    'at_risk': 'Biri mu kaga',
    'region': 'Akarere',
    'total_cases': 'Ibibazo byose',
    'res_rate': 'Igipimo',
    'avg_time': 'Igihe',
    // Case Edit
    'edit_case': 'Hindura Ikibazo',
    'edit_case_title': 'Hindura Umutwe',
    'edit_case_description': 'Hindura Ibisobanuro',
    'case_updated_success': 'Ikibazo cyahinduwe neza',
    'cannot_edit_case': 'Ntushobora guhindura iki kibazo',
    'case_must_be_open': 'Ikibazo kigomba kuba gifunguye kugirango uhindure',

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
    'status_closed': 'Closed',
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
    'invalid_email': 'Invalid email address',
    'nid_required': 'N.I.D is Required',
    'nid_length_error': 'Must be exactly 16 digits',
    'phone_required': 'Phone number is Required',
    'invalid_phone': 'Invalid Rwanda number (e.g. 078...)',
    // User Management EN
    'user_management': 'User Management',
    'register_leader': 'Register Leader',
    'banks': 'Banks',
    'bank_management': 'Bank Management',
    'financial_services': 'Financial Services',
    'secure_banking_support': 'Secure Banking Support',
    'banking_support_desc': 'Submit and track issues with your bank directly through Imboni.',
    'select_bank': 'Select Bank',
    'banking_complaints': 'Banking Complaints',
    'financial_help': 'Financial Help',
    'my_recent_complaints': 'My Recent Complaints',
    'bank_complaint': 'Bank Complaint',
    'status_received': 'Received',
    'status_under_review': 'Under Review',
    'status_investigation': 'Investigation',
    'search_users_hint': 'Search by name, email, or role...',
    'no_users_found': 'No users found',
    'all_users': 'All Users',
    'leaders': 'Leaders',
    'citizens': 'Citizens',
    'name': 'Name',
    'status': 'Status',
    'actions': 'Actions',
    'imboni_admin': 'Admin',
    'register_new_bank': 'Register New Bank',
    'add_bank': 'Add Bank',
    'bank_name': 'Bank Name',
    'bank_code': 'Bank Code',
    'head_office_location': 'Head Office Location',
    'contact_email': 'Contact Email',
    'contact_phone': 'Contact Phone',
    'total_banks': 'Total Banks',
    'active_branches': 'Active Branches',
    'no_banks_yet': 'No bank partners registered yet.',
    'add_bank_hint': 'Click "Add Bank" to begin onboarding financial partners.',
    'bank_code_label': 'Code',
    'fill_all_fields': 'Please fill all fields',
    'submission_failed': 'Submission failed',
    'complaint_submitted_success': 'Complaint Submitted Successfully',
    'reference_code': 'Reference Code',
    'back_to_home': 'Back to Home',
    'report_to': 'Report to',
    'bank_case_details': 'Bank Case Details',
    'select_branch': 'Select Branch',
    'service_category': 'Service Category',
    'describe_issue_hint': 'Describe the issue...',
    'branch_name': 'Branch Name',
    'service_example_hint': 'Example: ATM, Account...',
    'enter_details_hint': 'Enter details here...',
    'submit_complaint': 'Submit Complaint',
    'add_bank_service': 'Add Bank Service',
    'service_name_hint': 'Service Name (e.g. ATM Dispute)',
    'add_btn': 'Add',
    'register_new_branch': 'Register New Branch',
    'detailed_address': 'Detailed Address',
    'branch_phone': 'Branch Phone',
    'branches_list': 'Branches List',
    'services_list': 'Services List',
    'no_branches_hint': 'No branches registered.',
    'no_services_hint': 'No services registered.',
    'branches_tab': 'Branches',
    'service_catalog_tab': 'Service Catalog',
    'authorized_branches': 'Authorized Branches',
    'new_branch_btn': 'New Branch',
    'registered_services': 'Registered Services',
    'hq_label': 'HQ',
    'no_description': 'No description',
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
    // resolved defined above
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
    // case_escalated defined above
    // case_resolved defined above
    'case_viewed': 'Viewed',
    'case_assigned': 'Assigned',
    'case_accepted': 'Accepted',
    'case_status_update': 'Status Update',
    'case_assignment': 'Assignment',

    'take_case': 'Take This Case',
    'resolve_case': 'Mark Resolved',
    'escalate': 'Escalate',
    'escalate_reason': 'Provide a reason for escalation:',
    'escalate_hint': 'Example: We do not have authority...',
    'action_success': 'Action completed successfully',
    'case_resolved_success': 'Case has been resolved!',
    'case_escalated_success': 'Case has been escalated!',
    'status_update': 'Status Update',
    'resolution': 'Resolution',
    'confirm_resolution_content': 'Are you sure this case is resolved? This cannot be undone.',
    'reason_for_dispute': 'Reason for dispute',
    'pending_confirmation': 'Resolution Confirmation Required',
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
    'escalation_in': 'Escalates in',
    'overdue': 'Overdue',
    'resolution_action_desc': 'The leader has marked this case as resolved. Please confirm if you are satisfied with the resolution, or dispute it if the issue persists.',
    'status_changed_to': 'Status changed to',
    // Community EN
    'community_title': 'Civic Connect',
    'community': 'Community',
    'community_subtitle': 'Connect with neighbors',
    'channels': 'Channels',
    'type_message': 'Type a message...',
    'members': 'members',
    'general': 'General',
    
    // Community - Collaborative List EN
    'select_unit_hint': 'Select a unit from the left to view discussions',
    'view_list': 'View List',
    'add_your_entry': 'Add Your Entry',
    'add_entry': 'Add Entry',
    'edit_entry': 'Edit Entry',
    'save_changes': 'Save Changes',
    'no_entries_yet': 'No entries yet',
    'edit_list_structure': 'Edit List Structure',
    'list_title': 'List Title',
    'columns_label': 'Columns',
    'add_column': 'Add Column',
    'create_list': 'Create List',
    'create_collaborative_list': 'Create Collaborative List',
    'columns_comma_separated': 'Columns (comma separated)',
    'columns_data_warning': 'Changing columns may affect existing data display',
    'entries': 'entries',
    'export_as_excel': 'Export as Excel',
    'export_as_csv': 'Export as CSV',
    'export_failed': 'Export failed',
    'excel_export_failed': 'Excel export failed',
    'edit_title_columns': 'Edit Title/Columns',
    'fill_at_least_one_field': 'Please fill at least one field',
    'enter_list_title': 'Please enter a list title',
    'provide_at_least_one_column': 'Please provide at least one column',

    // Community - Poll EN
    'create_poll': 'Create Poll',
    'question': 'Question',
    'ask_something': 'Ask something...',
    'options': 'Options',
    'add_option': 'Add Option',
    'allow_multiple_answers': 'Allow multiple answers',
    'enter_question': 'Please enter a question',
    'provide_at_least_two_options': 'Please provide at least 2 options',
    'poll': 'Poll',
    'new_poll': 'New Poll',
    'votes': 'votes',
    'vote': 'Vote',
    'voted': 'Voted',

    // Community - Message Actions EN
    'action_copy': 'Copy',
    'action_reply': 'Reply',
    'action_pin': 'Pin',
    'action_edit': 'Edit',
    'action_delete': 'Delete',
    'action_info': 'Info',
    'close': 'Close',
    'pinned': 'Pinned',
    'unknown': 'Unknown',
    'you': 'You',
    'user': 'User',
    'click_to_remove': 'Click to remove',
    'all': 'All',
    'user_not_found': 'User not found',

    // Community - Emoji Picker EN
    'search_emoji': 'Search emoji',
    'no_emojis_found': 'No emojis found',

    // Community - Attachments EN
    'document_label': 'Document',
    'list_label': 'List',
    'new_list': 'New List',
    'column_hint': 'Column',
    'option_hint': 'Option',

    'registered_on': 'Registered on',
    'residence_location': 'Residence Location',
    'edit_profile': 'Edit Profile',
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
    'assigned_to': 'Assigned To',

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
    // PFTCV EN
    'public_funds': 'Public Funds',
    'public_funds_subtitle': 'Verify government projects',
    // Assignment Dialog EN
    'assign_case_title': 'Assign Case',
    'select_leader_label': 'Select Leader',
    'choose_leader_hint': 'Choose a leader from this unit',
    'set_deadline_label': 'Set Deadline',
    'no_active_leaders_error': 'No active leaders found in this unit',
    'assign_btn': 'Assign',
    'select_date_time': 'Select Date & Time',

    // Extend Deadline EN
    'extend_deadline': 'Extend Deadline',
    'extend_deadline_title': 'Extend Deadline',
    'days_label': 'Days (Max 3)',
    'extension_limit_error': 'Cannot extend more than 2 times',
    'extension_success': 'Deadline extended successfully',
    'extension_reason_label': 'Reason for extension',
    'extension_reason_hint': 'Explain why you need more time...',

    'note_manual_assignment': 'Manually assigned to specific leader',
    'note_deadline_extended': 'Deadline extended by',
    'note_reason': 'Reason',
    'note_extension_count': 'Extension',

    'day_singular': 'Day',
    'day_plural': 'Days',
    'assign_to_staff': 'Assign to Staff',
    'extensions_remaining': 'Extensions Remaining',

    // Performance Analytics EN
    'performance_analytics': 'Performance Analytics',
    'performance_subtitle': 'System-wide metrics and leader effectiveness',
    'resolution_rate': 'Resolution Rate',
    'avg_response_time': 'Avg Response Time',
    'escalation_rate': 'Escalation Rate',
    'overdue_cases': 'Overdue Cases',
    'weekly_performance': 'Weekly Performance',
    'new_vs_resolved': 'New vs Resolved cases',
    'cases_by_category': 'Cases by Category',
    'regional_breakdown': 'Regional Breakdown',
    'time_range': 'Time Range',
    'all_locations': 'All Locations',
    'all_categories': 'All Categories',
    'export_report': 'Export Report',
    'target': 'Target',
    'exceeded_sla': 'Exceeded SLA',
    'failing_resolution': 'Failing Resolution',
    'new_cases': 'New Cases',
    'no_data_available': 'No data available',
    'no_activity_last_week': 'No activity in last 7 days',
    'on_track': 'On Track',
    'at_risk': 'At Risk',
    'region': 'Region',
    'total_cases': 'Total Cases',
    'res_rate': 'Res. Rate',
    'avg_time': 'Avg Time',
    // Case Edit
    'edit_case': 'Edit Case',
    'edit_case_title': 'Edit Title',
    'edit_case_description': 'Edit Description',
    'case_updated_success': 'Case updated successfully',
    'cannot_edit_case': 'Cannot edit this case',
    'case_must_be_open': 'Case must be open to edit',

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
    'register_leader': 'Inscrire un Chef',
    'banks': 'Banques',
    'bank_management': 'Gestion des Banques',
    'financial_services': 'Services Financiers',
    'secure_banking_support': 'Support Bancaire Sécurisé',
    'banking_support_desc': 'Soumettez et suivez vos problèmes bancaires directement via Imboni.',
    'select_bank': 'Sélectionner une Banque',
    'banking_complaints': 'Plaintes Bancaires',
    'financial_help': 'Aide Financière',
    'my_recent_complaints': 'Mes Plaintes Récentes',
    'bank_complaint': 'Plainte Bancaire',
    'status_received': 'Reçu',
    'status_under_review': 'En cours d\'examen',
    'status_investigation': 'Enquête',
    'search_users_hint': 'Rechercher par nom, email ou rôle...',
    'no_users_found': 'Aucun utilisateur trouvé',
    'all_users': 'Tous',
    'leaders': 'Chefs',
    'citizens': 'Citoyens',
    'name': 'Nom',
    'status': 'Statut',
    'actions': 'Actions',
    'imboni_admin': 'Admin',
    'register_new_bank': 'Enregistrer une nouvelle banque',
    'add_bank': 'Ajouter une banque',
    'bank_name': 'Nom de la banque',
    'bank_code': 'Code de la banque',
    'head_office_location': 'Lieu du siège social',
    'contact_email': 'Email de contact',
    'contact_phone': 'Téléphone de contact',
    'total_banks': 'Total des banques',
    'active_branches': 'Agences actives',
    'no_banks_yet': 'Aucun partenaire bancaire enregistré.',
    'add_bank_hint': 'Cliquez sur "Ajouter une banque" pour commencer.',
    'bank_code_label': 'Code',
    'fill_all_fields': 'Veuillez remplir tous les champs',
    'submission_failed': 'Échec de l\'envoi',
    'complaint_submitted_success': 'Plainte envoyée avec succès',
    'reference_code': 'Code de référence',
    'back_to_home': 'Retour à l\'accueil',
    'report_to': 'Signaler à',
    'bank_case_details': 'Détails du dossier bancaire',
    'select_branch': 'Sélectionner l\'agence',
    'service_category': 'Catégorie de service',
    'describe_issue_hint': 'Décrire le problème...',
    'branch_name': 'Nom de l\'agence',
    'service_example_hint': 'Exemple: ATM, Compte...',
    'enter_details_hint': 'Entrez les détails ici...',
    'submit_complaint': 'Soumettre la plainte',
    'add_bank_service': 'Ajouter un service bancaire',
    'service_name_hint': 'Nom du service (ex: Litige ATM)',
    'add_btn': 'Ajouter',
    'register_new_branch': 'Enregistrer une nouvelle agence',
    'detailed_address': 'Adresse détaillée',
    'branch_phone': 'Téléphone de l\'agence',
    'branches_list': 'Liste des agences',
    'services_list': 'Liste des services',
    'no_branches_hint': 'Aucune agence enregistrée.',
    'no_services_hint': 'Aucun service enregistré.',
    'branches_tab': 'Agences',
    'service_catalog_tab': 'Catalogue des services',
    'authorized_branches': 'Agences autorisées',
    'new_branch_btn': 'Nouvelle agence',
    'registered_services': 'Services enregistrés',
    'hq_label': 'Siège',
    'no_description': 'Aucune description',
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
    // case_escalated defined below
    // case_resolved defined below
    'case_viewed': 'Consulté',
    'case_assigned': 'Assigné',
    'case_accepted': 'Accepté',
    'case_status_update': 'Mise à jour du statut',
    'case_assignment': 'Assignation',

    'take_case': 'Prendre ce Cas',
    'resolve_case': 'Marquer Résolu',
    'escalate': 'Escalader',
    'escalate_reason': 'Indiquez la raison de l\'escalade:',
    'escalate_hint': 'Exemple: Nous n\'avons pas l\'autorité...',
    'action_success': 'Action effectuée avec succès',
    'case_resolved_success': 'Le cas a été résolu!',
    'case_escalated_success': 'Le cas a été escaladé!',
    'status_update': 'Mise à jour du statut',
    'resolution': 'Résolution',
    'confirm_resolution_content': 'Êtes-vous sûr que ce cas est résolu ? Cela ne peut pas être annulé.',
    'reason_for_dispute': 'Motif de la contestation',
    'pending_confirmation': 'Confirmation de résolution requise',
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
    // save defined above
    'submit': 'Soumettre',
    // resolved defined above
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
    // Assignment Dialog FR
    'assign_case_title': 'Assigner le Cas',
    'select_leader_label': 'Sélectionner un Chef',
    'choose_leader_hint': 'Choisir un chef de cette unité',
    'set_deadline_label': 'Définir l\'échéance',
    'no_active_leaders_error': 'Aucun chef actif trouvé dans cette unité',
    'assign_btn': 'Assigner',
    'select_date_time': 'Sélectionner Date et Heure',

    // Extend Deadline FR
    'extend_deadline': 'Prolonger le délai',
    'extend_deadline_title': 'Prolonger l\'échéance',
    'days_label': 'Jours (Max 3)',
    'extension_limit_error': 'Impossible de prolonger plus de 2 fois',
    'extension_success': 'Délai prolongé avec succès',
    'extension_reason_label': 'Raison de la prolongation',
    'extension_reason_hint': 'Expliquez pourquoi vous avez besoin de plus de temps...',

    'note_manual_assignment': 'Assigné manuellement à un chef spécifique',
    'note_deadline_extended': 'Délai prolongé de',
    'note_reason': 'Raison',
    'note_extension_count': 'Extension',

    'day_singular': 'Jour',
    'day_plural': 'Jours',
    'assign_to_staff': 'Assigner au Personnel',
    'extensions_remaining': 'Extensions restantes',

    // Performance Analytics FR
    'performance_analytics': 'Analyse de Performance',
    'performance_subtitle': 'Métriques du système et efficacité des leaders',
    'resolution_rate': 'Taux de Résolution',
    'avg_response_time': 'Temps de Réponse Moyen',
    'escalation_rate': 'Taux d\'Escalade',
    'overdue_cases': 'Affaires en Retard',
    'weekly_performance': 'Performance Hebdomadaire',
    'new_vs_resolved': 'Nouveaux vs Résolus',
    'cases_by_category': 'Affaires par Catégorie',
    'regional_breakdown': 'Répartition Régionale',
    'time_range': 'Période',
    'all_locations': 'Tous les Emplacements',
    'all_categories': 'Toutes les Catégories',
    'export_report': 'Exporter le Rapport',
    'target': 'Objectif',
    'exceeded_sla': 'SLA Dépassé',
    'failing_resolution': 'Échec de Résolution',
    'new_cases': 'Nouvelles Affaires',
    'no_data_available': 'Aucune donnée disponible',
    'no_activity_last_week': 'Aucune activité les 7 derniers jours',
    'on_track': 'En bonne voie',
    'at_risk': 'À risque',
    'region': 'Région',
    'total_cases': 'Total Affaires',
    'res_rate': 'Taux Rés.',
    'avg_time': 'Temps Moyen',
    // Community - Collaborative List FR
    'view_list': 'Voir la Liste',
    'add_your_entry': 'Ajouter Votre Entrée',
    'add_entry': 'Ajouter une Entrée',
    'edit_entry': 'Modifier l\'Entrée',
    'no_entries_yet': 'Aucune entrée pour le moment',
    'edit_list_structure': 'Modifier la Structure de la Liste',
    'list_title': 'Titre de la Liste',
    'columns_label': 'Colonnes',
    'add_column': 'Ajouter une Colonne',
    'create_list': 'Créer la Liste',
    'create_collaborative_list': 'Créer une Liste Collaborative',
    'columns_comma_separated': 'Colonnes (séparées par des virgules)',
    'columns_data_warning': 'La modification des colonnes peut affecter l\'affichage des données existantes',
    'entries': 'entrées',
    'export_as_excel': 'Exporter en Excel',
    'export_as_csv': 'Exporter en CSV',
    'export_failed': 'Échec de l\'exportation',
    'excel_export_failed': 'Échec de l\'exportation Excel',
    'edit_title_columns': 'Modifier Titre/Colonnes',
    'fill_at_least_one_field': 'Veuillez remplir au moins un champ',
    'enter_list_title': 'Veuillez entrer un titre de liste',
    'provide_at_least_one_column': 'Veuillez fournir au moins une colonne',

    // Community - Poll FR
    'create_poll': 'Créer un Sondage',
    'question': 'Question',
    'ask_something': 'Posez une question...',
    'options': 'Options',
    'add_option': 'Ajouter une Option',
    'allow_multiple_answers': 'Autoriser plusieurs réponses',
    'enter_question': 'Veuillez entrer une question',
    'provide_at_least_two_options': 'Veuillez fournir au moins 2 options',
    'poll': 'Sondage',
    'new_poll': 'Nouveau Sondage',
    'votes': 'votes',
    'vote': 'Voter',
    'voted': 'Voté',

    // Community - Message Actions FR
    'action_copy': 'Copier',
    'action_reply': 'Répondre',
    'action_pin': 'Épingler',
    'action_edit': 'Modifier',
    'action_delete': 'Supprimer',
    'action_info': 'Infos',
    'close': 'Fermer',
    'pinned': 'Épinglé',
    'unknown': 'Inconnu',
    'you': 'Vous',
    'user': 'Utilisateur',
    'click_to_remove': 'Cliquez pour supprimer',
    'all': 'Tous',
    'user_not_found': 'Utilisateur introuvable',

    // Community - Emoji Picker FR
    'search_emoji': 'Rechercher un emoji',
    'no_emojis_found': 'Aucun emoji trouvé',

    // Community - Attachments FR
    'document_label': 'Document',
    'list_label': 'Liste',
    'new_list': 'Nouvelle Liste',
    'column_hint': 'Colonne',
    'option_hint': 'Option',

    // Case Edit
    'edit_case': 'Modifier l\'Affaire',
    'edit_case_title': 'Modifier le Titre',
    'edit_case_description': 'Modifier la Description',
    'case_updated_success': 'Affaire modifiée avec succès',
    'cannot_edit_case': 'Impossible de modifier cette affaire',
    'case_must_be_open': 'L\'affaire doit être ouverte pour la modifier',

    // Community FR
    'community_title': 'Connexion Civique',
    'community': 'Communauté',
    'community_subtitle': 'Connectez-vous avec vos voisins',
    'channels': 'Chaînes',
    'select_unit_hint': 'Sélectionnez une unité à gauche pour voir les discussions',
  },
};
