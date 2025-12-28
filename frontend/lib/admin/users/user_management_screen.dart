import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/localization/app_localizations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _currentFilter = 'ALL'; // ALL, LEADER, CITIZEN
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int? page}) async {
    setState(() => _isLoading = true);
    final targetPage = page ?? _currentPage;
    
    // Convert generic filter to API role parameter if needed
    // Assuming backend takes comma separated roles or single
    String? roleParam;
    if (_currentFilter == 'LEADER') roleParam = 'LEADER,VILLAGE_LEADER,CELL_LEADER,SECTOR_LEADER,DISTRICT_LEADER,PROVINCE_LEADER';
    else if (_currentFilter == 'CITIZEN') roleParam = 'CITIZEN';
    
    final response = await adminService.getUsers(
      role: roleParam, 
      query: _searchController.text,
      page: targetPage,
      limit: _limit,
    );

    if (mounted) {
      setState(() {
        _users = response.data;
        _totalItems = response.total;
        _currentPage = response.page;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(UserModel user) async {
    final newStatus = user.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final success = await adminService.updateUserStatus(user.id, newStatus);
    if (success && mounted) {
      _loadUsers(page: _currentPage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated to $newStatus'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).userManagement,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: theme.textTheme.bodyMedium,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context).searchUsersHint,
                                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _loadUsers(page: 1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.transparent) // Removed explicit border for cleaner look
                            ),
                            child: IconButton(
                              icon: Icon(Icons.filter_list, color: theme.colorScheme.onSurfaceVariant),
                              onPressed: () {
                                setState(() {
                                    if (_currentFilter == 'ALL') _currentFilter = 'LEADER';
                                    else if (_currentFilter == 'LEADER') _currentFilter = 'CITIZEN';
                                    else _currentFilter = 'ALL';
                                    _loadUsers(page: 1);
                                });
                              },
                              tooltip: 'Filter: $_currentFilter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                        border: Border(
                          top: BorderSide(color: theme.dividerColor),
                          bottom: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: _buildHeader(AppLocalizations.of(context).name, theme)),
                          Expanded(flex: 3, child: _buildHeader('Email', theme)),
                          Expanded(flex: 2, child: _buildHeader(AppLocalizations.of(context).role, theme)),
                          Expanded(flex: 2, child: _buildHeader(AppLocalizations.of(context).status, theme)),
                          Expanded(flex: 1, child: _buildHeader(AppLocalizations.of(context).actions, theme, align: TextAlign.end)),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context).noUsersFound,
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _users.length,
                              separatorBuilder: (c, i) => Divider(height: 1, color: theme.dividerColor),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  color: index % 2 == 0 ? theme.cardColor : theme.colorScheme.surfaceContainerHighest.withAlpha(30), 
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2, 
                                        child: Text(
                                          user.displayName, 
                                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
                                        )
                                      ),
                                      Expanded(
                                        flex: 3, 
                                        child: Text(
                                          user.email ?? '-', 
                                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                                        )
                                      ),
                                      Expanded(
                                        flex: 2, 
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildRoleBadge(user),
                                        )
                                      ),
                                      Expanded(
                                        flex: 2, 
                                        child: _buildStatusIndicator(user.status)
                                      ),
                                      Expanded(
                                        flex: 1, 
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: PopupMenuButton<String>(
                                            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                                            color: theme.cardColor,
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'toggle',
                                                child: Text(
                                                  user.status == 'ACTIVE' ? 'Deactivate' : 'Activate',
                                                  style: TextStyle(color: theme.colorScheme.onSurface),
                                                ),
                                              ),
                                            ],
                                            onSelected: (v) {
                                              if (v == 'toggle') _toggleStatus(user);
                                            },
                                          ),
                                        )
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Pagination Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: theme.dividerColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'Page $_currentPage of $_totalPages',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildPageButton('Previous', _currentPage > 1, () => _loadUsers(page: _currentPage - 1), theme),
                              const SizedBox(width: 8),
                              _buildPageButton('Next', _currentPage < _totalPages, () => _loadUsers(page: _currentPage + 1), theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text, ThemeData theme, {TextAlign align = TextAlign.start}) {
    return Text(
      text,
      textAlign: align,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    Color bg;
    Color text;
    IconData icon;
    String label;

    if (user.role == 'ADMIN') {
      bg = Colors.blue.withAlpha(50);
      text = Colors.blue;
      icon = Icons.shield_outlined;
      label = AppLocalizations.of(context).imboniAdmin; // 'Admin'
      // Fallback if key missing or too long, maybe just hardcode 'Admin' for now or add specific key
       if (label.length > 10) label = 'Admin'; 
    } else if (user.isLeader) {
      bg = Colors.green.withAlpha(50);
      text = Colors.green;
      icon = Icons.verified_outlined;
      label = 'Leader'; 
      // Localization for leader could be tricky if we want specific titles, but generic 'Leader' is fine for badge
      // Or use AppLocalizations.of(context).leaders (plural) -> singular? 
      // Let's stick to English 'Leader' for badge or add 'role_leader' key.
      // Actually, let's use the raw string from backend if meaningful, or map it.
    } else {
      bg = Colors.grey.withAlpha(50);
      text = Colors.grey;
      icon = Icons.person_outline;
      label = AppLocalizations.of(context).citizens; // Plural? 'Citizen'
      if (label == 'Abaturage') label = 'Umuturage'; // Hacky singular for now
      else if (label == 'Citizens') label = 'Citizen';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    final isActive = status == 'ACTIVE';
    final color = isActive ? Colors.green : Colors.red;
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? AppLocalizations.of(context).active : AppLocalizations.of(context).inactive,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildPageButton(String text, bool enabled, VoidCallback onTap, ThemeData theme) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        disabledForegroundColor: theme.colorScheme.onSurface.withAlpha(100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: theme.dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(text),
    );
  }
}
