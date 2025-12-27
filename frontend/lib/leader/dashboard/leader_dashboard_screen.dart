import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/case_service.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/api_client.dart';

import '../../shared/models/models.dart';
import '../../shared/widgets/rwanda_map/rwanda_map.dart';
import 'assigned_cases/assigned_cases_screen.dart';
import 'escalation_alerts/escalation_alerts_screen.dart';
import 'performance/performance_screen.dart';

/// Leader Dashboard Screen - Professional responsive design
class LeaderDashboardScreen extends StatefulWidget {
  const LeaderDashboardScreen({super.key});

  @override
  State<LeaderDashboardScreen> createState() => _LeaderDashboardScreenState();
}

class _LeaderDashboardScreenState extends State<LeaderDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final screens = [const _DashboardHome(), const AssignedCasesScreen(), const EscalationAlertsScreen(), const PerformanceScreen()];

    return isDesktop ? _buildDesktop(theme, screens) : _buildMobile(screens);
  }

  Widget _buildMobile(List<Widget> screens) => Scaffold(
    body: screens[_currentIndex],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Intangiriro'),
        NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Ibibazo'),
        NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: 'Imburira'),
        NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Imikorere'),
      ],
    ),
  );

  Widget _buildDesktop(ThemeData theme, List<Widget> screens) {
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
                Text('Imboni', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 8),
            ..._buildNavItems(theme, isDark),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurfaceVariant),
              title: Text('Settings', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ]),
        ),
        Expanded(child: screens[_currentIndex]),
      ]),
    );
  }

  List<Widget> _buildNavItems(ThemeData theme, bool isDark) {
    final items = [
      (Icons.dashboard, 'Dashboard', 0),
      (Icons.folder, 'Ibibazo', 1),
      (Icons.warning_amber, 'Imburira', 2),
      (Icons.analytics, 'Imikorere', 3),
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
  PerformanceMetrics _metrics = PerformanceMetrics.empty();
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedProvince;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Map<String, int> get _casesByProvince {
    final map = {'Kigali': 0, 'North': 0, 'South': 0, 'East': 0, 'West': 0};
    final locationService = LocationService();
    
    for (final c in _assignedCases) {
      // 1. Try to get precise district first
      final district = locationService.extractDistrict(c.currentLevel);
      if (district != null) {
        final province = locationService.getProvinceForDistrict(district);
        if (province != null) {
          map[province] = (map[province] ?? 0) + 1;
          continue;
        }
      }

      // 2. Fallback to fuzzy matching if district not found
      final level = c.currentLevel.toUpperCase();
      if (level.contains('KIGALI')) map['Kigali'] = (map['Kigali'] ?? 0) + 1;
      else if (level.contains('NORTH')) map['North'] = (map['North'] ?? 0) + 1;
      else if (level.contains('SOUTH')) map['South'] = (map['South'] ?? 0) + 1;
      else if (level.contains('EAST')) map['East'] = (map['East'] ?? 0) + 1;
      else if (level.contains('WEST')) map['West'] = (map['West'] ?? 0) + 1;
      else map['Kigali'] = (map['Kigali'] ?? 0) + 1; // default
    }
    return map;
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
        caseService.getPerformanceMetrics(),
      ]);
      if (mounted) {
        setState(() {
          _assignedCases = (results[0] as ApiResponse<List<CaseModel>>).data ?? [];
          _escalationAlerts = (results[1] as ApiResponse<List<CaseModel>>).data ?? [];
          _metrics = (results[2] as ApiResponse<PerformanceMetrics>).data ?? PerformanceMetrics.empty();
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
                  Text('Dashboard', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildStatsRow(theme, isDark),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        flex: 3,
                        child: RwandaMapWidget(
                          casesByDistrict: _casesByDistrict,
                          onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildSearchAndTable(theme, isDark)),
                    ])
                  else ...[
                    RwandaMapWidget(
                      casesByDistrict: _casesByDistrict,
                      onDistrictSelected: (d) => debugPrint('Selected District: $d'),
                    ),
                    const SizedBox(height: 24),
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
      title: Responsive.isDesktop(context) ? null : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.primaryDark]), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text('Imboni Admin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        Container(
          width: 200,
          height: 40,
          margin: const EdgeInsets.only(right: 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Q Search',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.dividerColor)),
              filled: true,
              fillColor: theme.cardColor,
            ),
          ),
        ),
        IconButton(icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface), onPressed: () {}),
        IconButton(icon: Icon(Icons.help_outline, color: theme.colorScheme.onSurface), onPressed: () {}),
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
      _StatCard(icon: Icons.circle, iconColor: ImboniColors.urgencyEmergency, label: 'Urgent (+24h):', value: '$urgentCount', theme: theme),
      const SizedBox(width: 24),
      _StatCard(icon: Icons.circle, iconColor: ImboniColors.info, label: 'Active:', value: '${_assignedCases.length}', theme: theme),
      const SizedBox(width: 24),
      _StatCard(icon: Icons.circle, iconColor: ImboniColors.warning, label: 'Escalated:', value: '${_escalationAlerts.length}', theme: theme),
    ]);
  }

  Widget _buildSearchAndTable(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Q Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('View Queue'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
            ),
          ]),
        ),
        const Divider(height: 1),
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
            DataCell(_buildStatusChip(c.status, theme)),
            DataCell(_buildUrgencyChip(c.urgency, theme)),
            DataCell(Text('${DateTime.now().difference(c.createdAt).inHours}h', style: theme.textTheme.bodySmall)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    final color = ImboniColors.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildUrgencyChip(String urgency, ThemeData theme) {
    final color = ImboniColors.getUrgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
      child: Text(urgency, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final ThemeData theme;

  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: iconColor, size: 16),
      const SizedBox(width: 8),
      Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(width: 8),
      Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}
