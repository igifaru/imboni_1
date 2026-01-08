import 'package:flutter/material.dart';
import '../../shared/widgets/dashboard/stat_card.dart';
import '../../shared/widgets/dashboard/status_chips.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/rwanda_map/rwanda_map.dart';
import 'widgets/district_cases_widget.dart';
import '../../shared/widgets/forms/register_leader_form.dart';
import 'assigned_cases/assigned_cases_screen.dart';
import 'escalation_alerts/escalation_alerts_screen.dart';
import 'performance/performance_screen.dart';
import 'settings/leader_settings_screen.dart';
import '../../admin/services/admin_service.dart';
import '../../shared/localization/app_localizations.dart';
import '../case_management/case_details_screen.dart';
import '../../shared/services/auth_service.dart';

import '../../features/community/screens/community_home_screen.dart';
import '../../features/pftcv/pftcv.dart';

/// Leader Dashboard Screen - Professional responsive design
class LeaderDashboardScreen extends StatefulWidget {
  const LeaderDashboardScreen({super.key});

  @override
  State<LeaderDashboardScreen> createState() => _LeaderDashboardScreenState();
}

class _LeaderDashboardScreenState extends State<LeaderDashboardScreen> {
  int _currentIndex = 0;
  String? _currentLevel;
  bool _isLevelLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLevel();
  }

  Future<void> _fetchLevel() async {
      try {
        final context = await adminService.getMyJurisdiction();
        if (mounted) {
          setState(() {
            if (context != null) {
              _currentLevel = context['level'];
            }
            _isLevelLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLevelLoading = false);
      }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLevelLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    const showRegister = true; // Enabled for all levels including VILLAGE (for staff)

    final screens = [
      _DashboardHome(
        currentLevel: _currentLevel,
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const CommunityHomeScreen(), // Community Tab 
      const PftcvHomeScreen(), // PFTCV Tab
      const AssignedCasesScreen(),
      const EscalationAlertsScreen(),
      const PerformanceScreen(),
      if (showRegister) const RegisterLeaderForm()
    ];

    // Ensure index doesn't go out of bounds if tab was removed
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return isDesktop ? _buildDesktop(theme, screens, showRegister) : _buildMobile(screens, showRegister);
  }

  Widget _buildMobile(List<Widget> screens, bool showRegister) => Scaffold(
    body: screens[_currentIndex],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: [
        NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: AppLocalizations.of(context).dashboard),
        NavigationDestination(icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people), label: AppLocalizations.of(context).communityTitle),
        NavigationDestination(icon: const Icon(Icons.account_balance_outlined), selectedIcon: const Icon(Icons.account_balance), label: AppLocalizations.of(context).publicFunds),
        NavigationDestination(icon: const Icon(Icons.folder_outlined), selectedIcon: const Icon(Icons.folder), label: AppLocalizations.of(context).myCases),
        NavigationDestination(icon: const Icon(Icons.warning_amber_outlined), selectedIcon: const Icon(Icons.warning_amber), label: AppLocalizations.of(context).alerts),
        NavigationDestination(icon: const Icon(Icons.analytics_outlined), selectedIcon: const Icon(Icons.analytics), label: AppLocalizations.of(context).performance),
        if (showRegister) NavigationDestination(icon: const Icon(Icons.person_add_outlined), selectedIcon: const Icon(Icons.person_add), label: AppLocalizations.of(context).registerNewLeader),
      ],
    ),
  );

  Widget _buildDesktop(ThemeData theme, List<Widget> screens, bool showRegister) {
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Row(children: [
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(right: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(l10n.appName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 8),
            ..._buildNavItems(theme, isDark, showRegister, l10n),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurfaceVariant, size: 22),
                title: Text(l10n.settings, style: TextStyle(color: theme.colorScheme.onSurface)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const LeaderSettingsScreen()),
                ),
              ),
            ),
            const Spacer(),
          ]),
        ),
        Expanded(child: screens[_currentIndex]),
      ]),
    );
  }

  List<Widget> _buildNavItems(ThemeData theme, bool isDark, bool showRegister, AppLocalizations l10n) {
    final items = [
      (Icons.dashboard, l10n.dashboard, 0),
      (Icons.people_outline, l10n.communityTitle, 1),
      (Icons.account_balance, l10n.publicFunds, 2),
      (Icons.folder, l10n.myCases, 3),
      (Icons.warning_amber, l10n.alerts, 4),
      (Icons.analytics, l10n.performance, 5),
      if (showRegister) (Icons.person_add, l10n.registerNewLeader, 6),
    ];

    return items.map((item) {
      final isSelected = _currentIndex == item.$3;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? ImboniColors.primary.withAlpha(isDark ? 50 : 25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(item.$1, color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurfaceVariant, size: 22),
          title: Text(item.$2, style: TextStyle(color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          selected: isSelected,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () => setState(() => _currentIndex = item.$3),
        ),
      );
    }).toList();
  }
}
class _DashboardHome extends StatefulWidget {
  final String? currentLevel;
  final void Function(int tabIndex)? onNavigateToTab;

  const _DashboardHome({this.currentLevel, this.onNavigateToTab});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  List<CaseModel> _assignedCases = [];
  // ignore: unused_field
  List<CaseModel> _escalationAlerts = [];
  PerformanceMetrics? _metrics;
  bool _isLoading = true;
  String _searchQuery = '';
  
  String? _selectedLocationId;
  String? _selectedLocationName;
  String? _rootLocationName; 
  final List<Map<String, String>> _drillHistory = [];
  
  String? _currentLevel;
  
  // Map focus scope (from user's jurisdiction path)
  String? _focusProvince;
  String? _focusDistrict;
  String? _focusSector;
  String? _focusCell;
  String? _focusVillage;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ... (keep _casesByDistrict same)

  Future<void> _fetchLevel() async {
      try {
        final context = await adminService.getMyJurisdiction();
        
        if (mounted && context != null) {
          _currentLevel = context['level'];
          final name = context['jurisdiction'];
          _rootLocationName = (_currentLevel == 'NATIONAL') ? 'National' : (name ?? 'National');
          
          // Extract path hierarchy for map focus
          final path = context['path'] as List<dynamic>?;
          if (path != null) {
            for (final item in path) {
              final itemMap = item as Map<String, dynamic>;
              final level = itemMap['level'] as String?;
              final unitName = itemMap['name'] as String?;
              
              switch (level?.toUpperCase()) {
                case 'PROVINCE':
                  _focusProvince = unitName;
                  break;
                case 'DISTRICT':
                  _focusDistrict = unitName;
                  break;
                case 'SECTOR':
                  _focusSector = unitName;
                  break;
                case 'CELL':
                  _focusCell = unitName;
                  break;
                case 'VILLAGE':
                  _focusVillage = unitName;
                  break;
              }
            }
          }
          debugPrint('MAP SCOPE: province=$_focusProvince, district=$_focusDistrict, sector=$_focusSector, cell=$_focusCell, village=$_focusVillage');
        }
      } catch (e) {
        debugPrint('Fetch level error: $e');
      }
  }

  Map<String, int> get _casesByDistrict {
    final map = <String, int>{};
    final locationService = LocationService();
    
    // Use metrics data if available, otherwise fallback to assigned cases (less accurate)
    if (_metrics != null && _metrics!.subUnitBreakdown.isNotEmpty) {
      for (final sub in _metrics!.subUnitBreakdown) {
         map[sub.unitName] = sub.totalCases;
      }
    } else {
      for (final c in _assignedCases) {
        final district = locationService.extractDistrict(c.currentLevel);
        if (district != null) {
          map[district] = (map[district] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
       // Fetch level first to ensure headers are correct
       await _fetchLevel();
       
       // Execute all loads but don't let one failure stop others
       await Future.wait([
        _loadLocationData(),
        // If a location is selected, or user is ADMIN, load all cases (filtered by location).
        // Otherwise (Leader at root), load assigned cases.
        (_selectedLocationId != null || authService.currentUser?.role == 'ADMIN') 
            ? _loadAllCases() 
            : _loadAssignedCases(),
        _loadEscalationAlerts(),
        _loadPerformanceMetrics(),
      ]);
    } catch (e) {
       debugPrint('Dashboard Load Error: $e');
    }
    
    if (mounted) setState(() => _isLoading = false);
  }


  Future<void> _loadLocationData() async {
    try {
      await LocationService().load();
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> _loadAllCases() async {
    final response = await caseService.getAllCases(
      query: _searchQuery, 
      locationId: _selectedLocationId
    );
    if (response.isSuccess) {
      if (mounted) {
        setState(() {
          _assignedCases = response.data ?? []; 
        });
      }
    } else {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: ${response.error}')));
    }
  }

  Future<void> _loadAssignedCases() async {
    try {
      final response = await caseService.getAssignedCases(limit: 50);
      if (mounted && response.isSuccess && response.data != null) {
        setState(() => _assignedCases = response.data!);
      }
    } catch (e) {
      debugPrint('Assigned Cases Error: $e');
    }
  }

  Future<void> _loadEscalationAlerts() async {
    try {
      final response = await caseService.getEscalationAlerts();
      if (mounted && response.isSuccess && response.data != null) {
        setState(() => _escalationAlerts = response.data!);
      }
    } catch (e) {
      debugPrint('Escalation Alerts Error: $e');
    }
  }

  List<CaseModel> get _filteredCases {
    if (_searchQuery.isEmpty) return _assignedCases;
    return _assignedCases.where((c) => c.caseReference.toLowerCase().contains(_searchQuery.toLowerCase()) || c.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      final response = await caseService.getPerformanceMetrics(locationId: _selectedLocationId);
      if (mounted && response.isSuccess && response.data != null) {
        setState(() => _metrics = response.data);
      }
    } catch (e) {
      debugPrint('Performance Metrics Error: $e');
    }
  }

  void _handleUnitSelected(String unitId, String unitName) {
    setState(() {
      // Use _rootLocationName for the root fallback instead of hardcoded 'National'
      _drillHistory.add({'id': _selectedLocationId ?? 'root', 'name': _selectedLocationName ?? _rootLocationName ?? 'National'});
      _selectedLocationId = unitId;
      _selectedLocationName = unitName;
    });
    _loadDashboardData();
  }

  void _jumpToBreadcrumb(int index) {
      if (index < 0) {
        // Reset to root (National or Jurisdiction)
        setState(() {
           _drillHistory.clear();
           _selectedLocationId = null;
           _selectedLocationName = null;
        });
      } else {
         final targetState = _drillHistory[index];
         
         setState(() {
           _selectedLocationId = targetState['id'] == 'root' ? null : targetState['id'];
           // Use root location name if 'National' is stored but we have a custom root
           final isRootTarget = targetState['name'] == 'National' || targetState['name'] == (_rootLocationName ?? 'National');
           _selectedLocationName = isRootTarget ? null : targetState['name'];
           
           _drillHistory.removeRange(index, _drillHistory.length);
         });
      }
      _loadDashboardData();
  }

  Widget _buildBreadcrumbs(ThemeData theme) {
    final List<Widget> crumbs = [];
    
    // 1. Root Item
    final bool isRoot = _selectedLocationId == null;
    // Use the fetched root location name (e.g. "Northern Province") or fallback
    final rootLabel = _rootLocationName ?? 'National';
    
    crumbs.add(_buildBreadcrumbItem(theme, rootLabel, isRoot ? null : () => _jumpToBreadcrumb(-1), isValid: true));
    
    // 2. History Items
    for (int i = 0; i < _drillHistory.length; i++) {
        final item = _drillHistory[i];
        if (item['id'] == 'root') continue; 
        
        crumbs.add(_buildChevron(theme));
        crumbs.add(_buildBreadcrumbItem(theme, item['name']!, () => _jumpToBreadcrumb(i), isValid: true));
    }
    
    // 3. Current Item (if not root)
    if (_selectedLocationName != null) {
        crumbs.add(_buildChevron(theme));
        crumbs.add(_buildBreadcrumbItem(theme, _selectedLocationName!, null, isValid: false, isCurrent: true));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: crumbs),
    );
  }
  
  Widget _buildChevron(ThemeData theme) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4), 
          child: Icon(Icons.chevron_right, size: 16, color: theme.disabledColor)
      );
  }

  Widget _buildBreadcrumbItem(ThemeData theme, String label, VoidCallback? onTap, {bool isValid = true, bool isCurrent = false}) {
     final color = isCurrent ? theme.colorScheme.primary : (onTap != null ? theme.colorScheme.onSurface : theme.disabledColor);
     final weight = isCurrent ? FontWeight.bold : FontWeight.normal;
     
     return InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(4),
         child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
             child: Text(label, style: TextStyle(color: color, fontWeight: weight, fontSize: 14)),
         ),
     );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final padding = Responsive.horizontalPadding(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppLocalizations.of(context).dashboard, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildStatsRow(theme, isDark),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Left: Rwanda Map + Case Table below it
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RwandaMapWidget(
                              casesByDistrict: _casesByDistrict,
                              onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                              mapTitle: _selectedLocationName ?? _rootLocationName ?? 'National "God View" Dashboard',
                              focusProvince: _focusProvince,
                              focusDistrict: _focusDistrict,
                              focusSector: _focusSector,
                              focusCell: _focusCell,
                              focusVillage: _focusVillage,
                              allowFullMapToggle: _currentLevel != 'NATIONAL' && _currentLevel != 'PROVINCE',
                            ),
                            const SizedBox(height: 16),
                            // Case search and table UNDER the map
                            _buildSearchAndTable(theme, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right: Districts/Sectors/Cells list (scrollable independently)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildBreadcrumbs(theme),
                            ),
                            DistrictCasesWidget(
                              subUnitStats: _metrics?.subUnitBreakdown ?? [],
                              isDashboardLoading: _isLoading,
                              currentLevel: _metrics?.currentLevel ?? widget.currentLevel ?? '',
                              onUnitSelected: _handleUnitSelected,
                              currentMetrics: _metrics, // Pass metrics
                            ),
                          ],
                        ),
                      ),
                    ])
                  else ...[
                   // Mobile Layout
                    RwandaMapWidget(
                      casesByDistrict: _casesByDistrict,
                      onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                      mapTitle: _selectedLocationName ?? _rootLocationName ?? 'National "God View" Dashboard',
                      focusProvince: _focusProvince,
                      focusDistrict: _focusDistrict,
                      focusSector: _focusSector,
                      focusCell: _focusCell,
                      focusVillage: _focusVillage,
                      allowFullMapToggle: _currentLevel != 'NATIONAL' && _currentLevel != 'PROVINCE',
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildBreadcrumbs(theme),
                    ),
                    DistrictCasesWidget(
                      subUnitStats: _metrics?.subUnitBreakdown ?? [],
                      isDashboardLoading: _isLoading,
                      currentLevel: _metrics?.currentLevel ?? widget.currentLevel ?? '',
                      onUnitSelected: _handleUnitSelected,
                      currentMetrics: _metrics, // Pass metrics for mobile too
                    ),
                    const SizedBox(height: 16),
                    // Case search and table for mobile
                    _buildSearchAndTable(theme, isDark),
                  ],
                ]),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: SizedBox(
        height: 44,
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search cases...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface), onPressed: _loadDashboardData),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.secondary]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    // Use metrics from backend for accuracy across entire jurisdiction
    final urgentCount = _metrics?.urgentCases ?? 0;
    final activeCount = _metrics?.pendingCases ?? 0;
    final escalatedCount = _metrics?.escalatedCases ?? 0;

    // Tab index 3 is AssignedCasesScreen (Ibibazo)
    void navigateToCases() {
      widget.onNavigateToTab?.call(3);
    }

    return Row(children: [
      Expanded(child: StatCard(
        icon: Icons.warning_amber_rounded, 
        iconColor: ImboniColors.urgencyEmergency, 
        label: 'Urgent (+24h):', 
        value: '$urgentCount',
        onTap: navigateToCases,
      )),
      const SizedBox(width: 24),
      Expanded(child: StatCard(
        icon: Icons.cases_outlined, 
        iconColor: ImboniColors.info, 
        label: 'Active Cases:', 
        value: '$activeCount',
        onTap: navigateToCases,
      )),
      const SizedBox(width: 24),
      Expanded(child: StatCard(
        icon: Icons.trending_up, 
        iconColor: ImboniColors.warning, 
        label: 'Escalated:', 
        value: '$escalatedCount',
        onTap: navigateToCases,
      )),
    ]);
  }

  Widget _buildSearchAndTable(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            // Show dynamic title based on selection
            _selectedLocationName != null 
                ? 'Cases in $_selectedLocationName' 
                : 'Cases in ${_rootLocationName ?? 'National'}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
          ),
        ),
        _buildDataTable(theme, isDark),
      ]),
    );
  }

  void _openCaseDetails(CaseModel caseData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeaderCaseDetailsScreen(caseData: caseData)),
    );
    _loadDashboardData(); // Refresh list on return
  }

  Widget _buildDataTable(ThemeData theme, bool isDark) {
    final cases = _filteredCases;
    if (cases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text('Nta kibazo kiraboneka', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        headingRowColor: WidgetStateProperty.all(isDark ? theme.cardColor : Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Ref', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Urgency', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: cases.take(10).map((c) => DataRow(
          onSelectChanged: (_) => _openCaseDetails(c),
          color: WidgetStateProperty.resolveWith((states) {
            if (c.urgency == 'EMERGENCY') return ImboniColors.urgencyEmergency.withAlpha(isDark ? 30 : 15);
            return null;
          }),
          cells: [
            DataCell(Text(c.caseReference, style: const TextStyle(color: ImboniColors.info, fontWeight: FontWeight.w500))),
            DataCell(Text(c.title, overflow: TextOverflow.ellipsis)),
            DataCell(StatusChip(status: c.status)),
            DataCell(UrgencyChip(urgency: c.urgency)),
            DataCell(Text('${DateTime.now().difference(c.createdAt).inHours}h', style: theme.textTheme.bodySmall)),
          ],
        )).toList(),
      ),
    );
  }
}
