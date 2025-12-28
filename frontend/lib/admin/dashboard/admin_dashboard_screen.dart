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

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminDashboardScreen({super.key, required this.onLogout});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    
    // Screens for each navigation item
    final screens = [
      const _AdminHome(),
      const UserManagementScreen(),
      const RegisterLeaderForm(), // Index 2
      const AdminSettingsScreen(), // Index 3
    ];

    return isDesktop ? _buildDesktop(theme, screens) : _buildMobile(theme, screens);
  }

  Widget _buildMobile(ThemeData theme, List<Widget> screens) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add),
            label: 'Register',
          ),
          NavigationDestination(
             icon: Icon(Icons.settings_outlined),
             selectedIcon: Icon(Icons.settings),
             label: 'Settings',
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
                          'Imboni Admin',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildNavItem(theme, Icons.dashboard_outlined, 'Dashboard', 0),
                _buildNavItem(theme, Icons.people_outline, 'User Management', 1),
                _buildNavItem(theme, Icons.person_add_outlined, 'Register Leader', 2),
                _buildNavItem(theme, Icons.settings_outlined, 'Settings', 3),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                // Desktop App Bar (optional, or just header)
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
                        _currentIndex == 0 ? 'Dashboard' : 
                        _currentIndex == 1 ? 'User Management' : 'Register Leader',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                Expanded(child: screens[_currentIndex]),
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
        onTap: () => setState(() => _currentIndex = index),
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
    final locationService = LocationService();
    
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
    setState(() => _isLoading = true);
    try {
      await LocationService().load();
      final results = await Future.wait([
        caseService.getAllCases(limit: 50),
        caseService.getGlobalStats(),
        caseService.getEscalationAlerts(),
      ]);
      if (mounted) {
        setState(() {
          _assignedCases = (results[0].data as List).cast<CaseModel>();
          _globalStats = results[1].data as Map<String, dynamic>;
          _escalationAlerts = (results[2].data as List).cast<CaseModel>();
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
      appBar: _buildAppBar(theme, isDesktop),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildStatsRow(theme),
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
                      // Right: Province Cases Stats
                      Expanded(
                        flex: 3,
                        child: ProvinceCasesWidget(
                          cases: _assignedCases,
                          isLoading: _isLoading,
                        ),
                      ),
                    ])
                  else ...[
                    RwandaMapWidget(
                      casesByDistrict: _casesByDistrict,
                      onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                    ),
                    const SizedBox(height: 24),
                    ProvinceCasesWidget(cases: _assignedCases, isLoading: _isLoading),
                  ],
                  const SizedBox(height: 32),
                  // Case search and table below
                  _buildSearchAndTable(theme, isDark),
                ]),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDesktop) {
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
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(children: [
      Expanded(child: StatCard(icon: Icons.assignment_late, iconColor: ImboniColors.urgencyEmergency, label: 'Urgent', value: '${_globalStats['urgent'] ?? 0}')),
      const SizedBox(width: 12),
      Expanded(child: StatCard(icon: Icons.radio_button_checked, iconColor: ImboniColors.info, label: 'Active', value: '${_globalStats['active'] ?? 0}')),
      const SizedBox(width: 12),
      Expanded(child: StatCard(icon: Icons.warning_amber, iconColor: ImboniColors.warning, label: 'Escalated', value: '${_globalStats['escalated'] ?? 0}')),
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
