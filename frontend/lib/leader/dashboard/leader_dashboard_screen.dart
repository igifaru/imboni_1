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
    final showRegister = _currentLevel != 'VILLAGE';

    final screens = [
      const _DashboardHome(),
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
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurfaceVariant),
              title: Text(l10n.settings, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LeaderSettingsScreen()),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
        Expanded(child: screens[_currentIndex]),
      ]),
    );
  }

  List<Widget> _buildNavItems(ThemeData theme, bool isDark, bool showRegister, AppLocalizations l10n) {
    final items = [
      (Icons.dashboard, l10n.dashboard, 0),
      (Icons.folder, l10n.myCases, 1),
      (Icons.warning_amber, l10n.alerts, 2),
      (Icons.analytics, l10n.performance, 3),
      if (showRegister) (Icons.person_add, l10n.registerNewLeader, 4),
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
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  List<CaseModel> _assignedCases = [];
  List<CaseModel> _escalationAlerts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }


  Map<String, int> get _casesByDistrict {
    final map = <String, int>{};
    final locationService = LocationService();
    
    for (final c in _assignedCases) {
      final district = locationService.extractDistrict(c.currentLevel);
      if (district != null) {
        map[district] = (map[district] ?? 0) + 1;
      }
    }
    return map;
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load map data first to ensure parsing works
      await LocationService().load();

      final results = await Future.wait([
        caseService.getAssignedCases(limit: 50),
        caseService.getEscalationAlerts(),
      ]);
      if (mounted) {
        setState(() {
          _assignedCases = results[0].data ?? [];
          _escalationAlerts = results[1].data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CaseModel> get _filteredCases {
    if (_searchQuery.isEmpty) return _assignedCases;
    return _assignedCases.where((c) => c.caseReference.toLowerCase().contains(_searchQuery.toLowerCase()) || c.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
                      // Left: Rwanda Map
                      Expanded(
                        flex: 5,
                        child: RwandaMapWidget(
                          casesByDistrict: _casesByDistrict,
                          onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right: Districts in Province with case counts
                      Expanded(
                        flex: 3,
                        child: DistrictCasesWidget(cases: _assignedCases, isDashboardLoading: _isLoading),
                      ),
                    ])
                  else ...[
                    RwandaMapWidget(
                      casesByDistrict: _casesByDistrict,
                      onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                    ),
                    const SizedBox(height: 24),
                    DistrictCasesWidget(cases: _assignedCases, isDashboardLoading: _isLoading),
                  ],
                  const SizedBox(height: 32),
                  // Case search and table below
                  _buildSearchAndTable(theme, isDark),
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
    final urgentCount = _assignedCases.where((c) => c.urgency == 'EMERGENCY' || c.urgency == 'HIGH').length;
    return Row(children: [
      Expanded(child: StatCard(icon: Icons.circle, iconColor: ImboniColors.urgencyEmergency, label: 'Urgent (+24h):', value: '$urgentCount')),
      const SizedBox(width: 24),
      Expanded(child: StatCard(icon: Icons.circle, iconColor: ImboniColors.info, label: 'Active:', value: '${_assignedCases.length}')),
      const SizedBox(width: 24),
      Expanded(child: StatCard(icon: Icons.circle, iconColor: ImboniColors.warning, label: 'Escalated:', value: '${_escalationAlerts.length}')),
    ]);
  }

  Widget _buildSearchAndTable(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildDataTable(theme, isDark),
      ]),
    );
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
        headingRowColor: WidgetStateProperty.all(isDark ? theme.cardColor : Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Active', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Tags', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Beeline', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: cases.take(10).map((c) => DataRow(
          color: WidgetStateProperty.resolveWith((states) {
            if (c.urgency == 'EMERGENCY') return ImboniColors.urgencyEmergency.withAlpha(isDark ? 30 : 15);
            return null;
          }),
          cells: [
            DataCell(Text(c.caseReference, style: TextStyle(color: ImboniColors.info, fontWeight: FontWeight.w500))),
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
