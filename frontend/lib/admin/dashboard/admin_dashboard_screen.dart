import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/rwanda_map/rwanda_map.dart';
import '../../shared/widgets/dashboard/stat_card.dart';
import '../../shared/widgets/dashboard/status_chips.dart';
import '../../shared/widgets/forms/register_leader_form.dart';
import '../users/user_management_screen.dart';
import 'widgets/province_cases_widget.dart';
import 'settings/admin_settings_screen.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/admin_units_service.dart';
import '../../bank/views/bank_management_screen.dart';
import '../../institutions/views/institution_management_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// For professional Web Routing without breaking Desktop:
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.io) 'package:imboni/shared/stubs/html_stub.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminDashboardScreen({super.key, required this.onLogout});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  List<Widget>? _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens here once
    _screens = [
      const _AdminHome(),
      const UserManagementScreen(), 
      const RegisterLeaderForm(), // Index 2
      const AdminSettingsScreen(), // Index 3
      const BankManagementScreen(), // Index 4 - Bank Module
      const InstitutionManagementScreen(), // Index 5 - Institutions Module
    ];
  }

  String _getSafeTitle() {
    try {
      final l10n = AppLocalizations.of(context);
      if (_currentIndex == 0) return l10n.dashboard;
      if (_currentIndex == 1) return l10n.userManagement;
      if (_currentIndex == 2) return l10n.registerLeader;
      if (_currentIndex == 4) return l10n.bankManagement;
      if (_currentIndex == 5) return 'Institutions';
      return l10n.settings;
    } catch (_) {
      if (_currentIndex == 4) return 'Bank Management';
      if (_currentIndex == 5) return 'Institutions';
      return 'Admin Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final screens = _screens ?? [const Center(child: CircularProgressIndicator())];
    
    return isDesktop ? _buildDesktop(theme, screens) : _buildMobile(theme, screens);
  }

  Widget _buildMobile(ThemeData theme, List<Widget> screens) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getSafeTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (kIsWeb) {
            final hash = i == 0 ? 'dashboard' : 
                         i == 1 ? 'users' :
                         i == 2 ? 'leaders' :
                         i == 3 ? 'settings' :
                         i == 4 ? 'banks' : 'institutions';
            html.window.location.hash = hash;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.users,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_add_outlined),
            selectedIcon: const Icon(Icons.person_add),
            label: l10n.register,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(Icons.account_balance),
            label: l10n.banks,
          ),
          const NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Institutions',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop(ThemeData theme, List<Widget> screens) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(right: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ImboniColors.primary, ImboniColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).imboniAdmin,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildNavItem(theme, Icons.dashboard_outlined, AppLocalizations.of(context).dashboard, 0),
                _buildNavItem(theme, Icons.people_outline, AppLocalizations.of(context).userManagement, 1),
                _buildNavItem(theme, Icons.person_add_outlined, AppLocalizations.of(context).registerLeader, 2),
                _buildNavItem(theme, Icons.settings_outlined, AppLocalizations.of(context).settings, 3),
                _buildNavItem(theme, Icons.account_balance, AppLocalizations.of(context).banks, 4),
                _buildNavItem(theme, Icons.business, 'Institutions', 5),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getSafeTitle(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: ImboniColors.primary,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Material(
                    color: theme.scaffoldBackgroundColor,
                    child: _screens == null 
                      ? const Center(child: CircularProgressIndicator())
                      : IndexedStack(
                          index: _currentIndex,
                          children: _screens!,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(ThemeData theme, IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? ImboniColors.primary.withAlpha(isDark ? 50 : 25) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? ImboniColors.primary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() => _currentIndex = index);
          if (kIsWeb) {
            final hash = index == 0 ? 'dashboard' : 
                         index == 1 ? 'users' :
                         index == 2 ? 'leaders' :
                         index == 3 ? 'settings' :
                         index == 4 ? 'banks' : 'institutions';
            html.window.location.hash = hash;
          }
        },
      ),
    );
  }
}

class _AdminHome extends StatefulWidget {
  const _AdminHome();

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
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
    final locationService = AdminUnitsService.instance;
    
    for (final c in _assignedCases) {
      final district = locationService.extractDistrict(c.currentLevel);
      if (district != null) {
        map[district] = (map[district] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<String, dynamic> _globalStats = {};

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (!AdminUnitsService.instance.isLoaded) {
        await AdminUnitsService.instance.load();
      }

      final results = await Future.wait([
        caseService.getAllCases(limit: 50),
        caseService.getGlobalStats(),
        caseService.getEscalationAlerts(),
      ]);
      if (mounted) {
        setState(() {
          _assignedCases = (results[0].data as List?)?.cast<CaseModel>() ?? [];
          _globalStats = (results[1].data as Map<String, dynamic>?) ?? {};
          _escalationAlerts = (results[2].data as List?)?.cast<CaseModel>() ?? [];
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

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: _isLoading && _assignedCases.isEmpty 
          ? const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                 _buildStatsRow(theme),
                 const SizedBox(height: 32),
                 if (isDesktop)
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start, 
                     children: [
                       // Left: Rwanda Map
                       Expanded(
                         flex: 5,
                         child: ConstrainedBox(
                           constraints: const BoxConstraints(maxHeight: 600, minHeight: 400),
                           child: _buildMapSafe(),
                         ),
                       ),
                       const SizedBox(width: 24),
                       // Right: Province Cases Stats
                       Expanded(
                         flex: 3,
                         child: ProvinceCasesWidget(
                           cases: _assignedCases,
                           isLoading: _isLoading,
                         ),
                       ),
                     ],
                   )
                 else ...[
                   _buildMapSafe(),
                   const SizedBox(height: 24),
                   ProvinceCasesWidget(cases: _assignedCases, isLoading: _isLoading),
                 ],
                 const SizedBox(height: 32),
                 _buildSearchAndTable(theme, isDark),
              ],
            ),
            ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    String urgentLabel = 'Urgent';
    String activeLabel = 'Active';
    String escalatedLabel = 'Escalated';
    
    try {
      final l10n = AppLocalizations.of(context);
      urgentLabel = l10n.urgent;
      activeLabel = l10n.active;
      escalatedLabel = l10n.escalated;
    } catch (_) {}

    return SizedBox(
      height: 120,
      child: Row(children: [
        Expanded(child: StatCard(icon: Icons.assignment_late, iconColor: ImboniColors.urgencyEmergency, label: urgentLabel, value: '${_globalStats['urgent'] ?? 0}')),
        const SizedBox(width: 12),
        Expanded(child: StatCard(icon: Icons.radio_button_checked, iconColor: ImboniColors.info, label: activeLabel, value: '${_globalStats['active'] ?? 0}')),
        const SizedBox(width: 12),
        Expanded(child: StatCard(icon: Icons.warning_amber, iconColor: ImboniColors.warning, label: escalatedLabel, value: '${_globalStats['escalated'] ?? 0}')),
      ]),
    );
  }

  Widget _buildSearchAndTable(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildDataTable(theme, isDark),
      ]),
    );
  }

  Widget _buildMapSafe() {
    try {
      return RwandaMapWidget(
        casesByDistrict: _casesByDistrict,
        onDistrictSelected: (d) => debugPrint('Selected District: $d'),
      );
    } catch (e) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Map currently unavailable')),
      );
    }
  }

  Widget _buildDataTable(ThemeData theme, bool isDark) {
    final cases = _filteredCases;
    if (cases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text('No cases found', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? theme.cardColor : Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Ref')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Urgency')),
        ],
        rows: cases.take(10).map((c) => DataRow(
          cells: [
            DataCell(Text(c.caseReference, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(c.title, overflow: TextOverflow.ellipsis)),
            DataCell(StatusChip(status: c.status)),
            DataCell(UrgencyChip(urgency: c.urgency)),
          ],
        )).toList(),
      ),
    );
  }
}
