import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/widgets/dashboard/status_chips.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _currentFilter = 'ALL'; // ALL, LEADER, CITIZEN

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0: _currentFilter = 'ALL'; break;
      case 1: _currentFilter = 'LEADER,ADMIN'; break;
      case 2: _currentFilter = 'CITIZEN'; break;
    }
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final role = _currentFilter == 'ALL' ? null : _currentFilter;
    final users = await adminService.getUsers(role: role, query: _searchController.text);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(UserModel user) async {
    final newStatus = user.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final success = await adminService.updateUserStatus(user.id, newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user.displayName} updated to $newStatus'), backgroundColor: Colors.green),
      );
      _loadUsers(); // Reload to refresh list
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    // Common padding
    final padding = EdgeInsets.all(isDesktop ? 24 : 16);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: ImboniColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: ImboniColors.primary,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Leaders'),
            Tab(text: 'Citizens'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: padding,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUsers,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
              onSubmitted: (_) => _loadUsers(),
            ),
          ),

          // User List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            adminService.error ?? 'No users found',
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                          ),
                          if (adminService.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: FilledButton.tonal(
                                onPressed: _loadUsers,
                                child: const Text('Retry'),
                              ),
                            ),
                        ],
                      ),
                    )
                  : _buildUserTable(theme, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable(ThemeData theme, bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(theme.cardColor),
          columnSpacing: isDesktop ? 40 : 20,
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _users.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (user.email != null) 
                        Text(user.email!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isLeader ? Colors.purple.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role, 
                      style: TextStyle(
                        color: user.isLeader ? Colors.purple : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      )
                    ),
                  ),
                ),
                DataCell(
                  StatusChip(status: user.status),
                ),
                DataCell(
                  IconButton(
                    icon: Icon(
                      user.status == 'ACTIVE' ? Icons.block : Icons.check_circle_outline,
                      color: user.status == 'ACTIVE' ? Colors.red : Colors.green,
                    ),
                    tooltip: user.status == 'ACTIVE' ? 'Deactivate' : 'Activate',
                    onPressed: () => _toggleStatus(user),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
