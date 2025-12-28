import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../shared/models/models.dart';
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
  String? _errorMessage;
  String _currentFilter = 'ALL';
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final targetPage = page ?? _currentPage;
    
    String? roleParam;
    if (_currentFilter == 'LEADER') {
      roleParam = 'LEADER';
    } else if (_currentFilter == 'CITIZEN') {
      roleParam = 'CITIZEN';
    } else if (_currentFilter == 'ADMIN') {
      roleParam = 'ADMIN';
    }
    
    try {
      final response = await adminService.getUsers(
        role: roleParam, 
        query: _searchController.text,
        page: targetPage,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          _users = response.data;
          _currentPage = response.page;
          _totalPages = response.totalPages;
          _totalItems = response.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleStatus(UserModel user) async {
    final newStatus = user.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final l10n = AppLocalizations.of(context);
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating user status...'), duration: Duration(seconds: 1)),
    );
    
    final success = await adminService.updateUserStatus(user.id, newStatus);
    if (mounted) {
      if (success) {
        _loadUsers(page: _currentPage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${user.displayName} - ${newStatus == 'ACTIVE' ? l10n.active : l10n.inactive}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to update user status'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.userManagement,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (!_isLoading && _errorMessage == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 18, color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalItems ${l10n.users}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Search and Filter Row
            _buildSearchBar(theme, l10n, isDark),
            const SizedBox(height: 20),
            
            // Main Content Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withAlpha(50)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 8),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildContent(theme, l10n),
              ),
            ),
            
            // Pagination
            const SizedBox(height: 16),
            _buildPagination(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.searchUsersHint,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers(page: 1);
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _loadUsers(page: 1),
              onChanged: (value) => setState(() {}), // To show/hide clear button
            ),
          ),
          const SizedBox(width: 16),
          
          // Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withAlpha(50)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentFilter,
                icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.cardColor,
                items: [
                  _buildDropdownItem('ALL', l10n.allUsers, Icons.people_outline, theme),
                  _buildDropdownItem('LEADER', l10n.leaders, Icons.verified_user_outlined, theme),
                  _buildDropdownItem('CITIZEN', l10n.citizens, Icons.person_outline, theme),
                  _buildDropdownItem('ADMIN', 'Admin', Icons.admin_panel_settings_outlined, theme),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _currentFilter = value);
                    _loadUsers(page: 1);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Refresh Button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.refresh,
                color: theme.colorScheme.onPrimary,
              ),
              onPressed: _isLoading ? null : () => _loadUsers(page: 1),
              tooltip: l10n.retry,
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label, IconData icon, ThemeData theme) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load users',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _loadUsers(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noUsersFound,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search or filter criteria',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withAlpha(180)),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              _buildHeaderCell(l10n.name, Icons.person_outline, 3, theme),
              const SizedBox(width: 8),
              _buildHeaderCell('Email', Icons.email_outlined, 4, theme),
              const SizedBox(width: 12),
              _buildHeaderCell(l10n.role, Icons.badge_outlined, 2, theme),
              const SizedBox(width: 12),
              _buildHeaderCell(l10n.status, Icons.toggle_on_outlined, 2, theme),
              const SizedBox(width: 8),
              _buildHeaderCell(l10n.actions, Icons.more_horiz, 1, theme, align: TextAlign.center),
            ],
          ),
        ),
        
        // Table Body
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final isEven = index % 2 == 0;
              
              return Container(
                decoration: BoxDecoration(
                  color: isEven ? Colors.transparent : theme.colorScheme.surfaceContainerHighest.withAlpha(30),
                  border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(50))),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showUserDetails(user),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          // Name with Avatar
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                _buildAvatar(user, theme),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Email
                          Expanded(
                            flex: 4,
                            child: Text(
                              user.email ?? '-',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Role Badge
                          Expanded(
                            flex: 2,
                            child: _buildRoleBadge(user, theme, l10n),
                          ),
                          const SizedBox(width: 12),
                          
                          // Status Badge
                          Expanded(
                            flex: 2,
                            child: _buildStatusBadge(user.status, theme, l10n),
                          ),
                          const SizedBox(width: 8),
                          
                          // Actions
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: theme.cardColor,
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility_outlined, size: 18, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        const Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          user.status == 'ACTIVE' ? Icons.block : Icons.check_circle_outline,
                                          size: 18,
                                          color: user.status == 'ACTIVE' ? Colors.orange : Colors.green,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(user.status == 'ACTIVE' ? 'Deactivate' : 'Activate'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'toggle') _toggleStatus(user);
                                  if (value == 'view') _showUserDetails(user);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, IconData icon, int flex, ThemeData theme, {TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: align == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user, ThemeData theme) {
    Color bgColor;
    IconData icon;
    
    if (user.role == 'ADMIN') {
      bgColor = Colors.blue;
      icon = Icons.admin_panel_settings;
    } else if (user.isLeader) {
      bgColor = Colors.green;
      icon = Icons.verified;
    } else {
      bgColor = Colors.grey;
      icon = Icons.person;
    }
    
    return CircleAvatar(
      radius: 18,
      backgroundColor: bgColor.withAlpha(40),
      child: Icon(icon, size: 18, color: bgColor),
    );
  }

  Widget _buildRoleBadge(UserModel user, ThemeData theme, AppLocalizations l10n) {
    Color color;
    IconData icon;
    String label;
    
    if (user.role == 'ADMIN') {
      color = Colors.blue;
      icon = Icons.shield_outlined;
      label = 'Admin';
    } else if (user.isLeader) {
      color = Colors.green;
      icon = Icons.verified_outlined;
      label = l10n.leaders;
    } else {
      color = Colors.grey;
      icon = Icons.person_outline;
      label = l10n.citizens;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme, AppLocalizations l10n) {
    final isActive = status == 'ACTIVE';
    final color = isActive ? Colors.green : Colors.orange;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          isActive ? l10n.active : l10n.inactive,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Info
          Text(
            'Showing ${((_currentPage - 1) * _limit) + 1}-${(_currentPage * _limit).clamp(0, _totalItems)} of $_totalItems',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          
          // Page Controls
          Row(
            children: [
              _buildPageButton(
                icon: Icons.first_page,
                enabled: _currentPage > 1,
                onTap: () => _loadUsers(page: 1),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () => _loadUsers(page: _currentPage - 1),
                theme: theme,
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildPageButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < _totalPages,
                onTap: () => _loadUsers(page: _currentPage + 1),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.last_page,
                enabled: _currentPage < _totalPages,
                onTap: () => _loadUsers(page: _totalPages),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: enabled ? theme.colorScheme.surfaceContainerHighest : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _buildAvatar(user, theme),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName),
                  Text(
                    user.email ?? 'No email',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(Icons.badge_outlined, l10n.role, user.role, theme),
            _buildDetailRow(Icons.toggle_on_outlined, l10n.status, user.status, theme),
            _buildDetailRow(Icons.calendar_today_outlined, 'User ID', user.id.substring(0, 8), theme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _toggleStatus(user);
            },
            icon: Icon(user.status == 'ACTIVE' ? Icons.block : Icons.check_circle),
            label: Text(user.status == 'ACTIVE' ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
