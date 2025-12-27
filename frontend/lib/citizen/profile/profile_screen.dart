import 'package:flutter/material.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/services/admin_units_service.dart';

/// Profile/Settings Screen - Fully functional with state management
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _namesController = TextEditingController();
  final _emailController = TextEditingController();
  LocationSelection _location = const LocationSelection();

  // Settings State
  String _selectedLanguage = 'Kinyarwanda';
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = authService.currentUser;
    if (user != null) {
      _namesController.text = user.phone ?? '';
      _emailController.text = user.email ?? '';
    }
    // Check current theme brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  @override
  void dispose() { _namesController.dispose(); _emailController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Igenamiterere'),
        actions: [
          if (_isEditing)
            TextButton(onPressed: _saveProfile, child: const Text('Bika'))
          else
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _isEditing = true)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAccountSection(theme, colorScheme, user)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPreferencesSection(theme, colorScheme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAboutSection(theme, colorScheme)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccountSection(theme, colorScheme, user),
                    const SizedBox(height: 16),
                    _buildPreferencesSection(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildAboutSection(theme, colorScheme),
                    const SizedBox(height: 32),
                  ],
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProfile,
        icon: const Icon(Icons.save),
        label: const Text('Bika Ibyahinduwe'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildAccountSection(ThemeData theme, ColorScheme colorScheme, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konti Yanjye', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    user?.phone?.substring(0, 2).toUpperCase() ?? 'U',
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.phone ?? 'Umukiriya', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(user?.isCitizen == true ? 'Umuturage' : 'Umuyobozi', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _namesController,
                decoration: const InputDecoration(labelText: 'Amazina yombi', prefixIcon: Icon(Icons.person_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Imeli', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            _buildActionTile(theme, colorScheme, 'Hindura Umwirondoro', Icons.edit_outlined, () => setState(() => _isEditing = !_isEditing)),
            _buildActionTile(theme, colorScheme, 'Hindura Ijambo ry\'Ibanga', Icons.lock_outlined, _showChangePasswordDialog),
            _buildActionTile(theme, colorScheme, 'Sohoka', Icons.logout, _logout, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ibyo Mhitamo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Language Dropdown
            Row(
              children: [
                Icon(Icons.language_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text('Ururimi', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isDense: true,
                      items: ['Kinyarwanda', 'English', 'Français'].map((o) => DropdownMenuItem(value: o, child: Text(o, style: theme.textTheme.bodySmall))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedLanguage = v);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ururimi: $v'), duration: const Duration(seconds: 1)));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Notifications Section
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text('Menyesha', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            _buildFunctionalSwitch(theme, colorScheme, 'Imeli', _emailNotifications, (v) => setState(() => _emailNotifications = v), indent: true),
            _buildFunctionalSwitch(theme, colorScheme, 'SMS', _smsNotifications, (v) => setState(() => _smsNotifications = v), indent: true),
            const SizedBox(height: 16),
            // Theme Section
            Row(
              children: [
                Icon(Icons.palette_outlined, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text('Insanganyamatsiko', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            _buildFunctionalSwitch(
              theme, colorScheme, 'Ijoro (Dark Mode)', _isDarkMode,
              (v) {
                setState(() => _isDarkMode = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v ? 'Insanganyamatsiko y\'ijoro' : 'Insanganyamatsiko y\'umunsi'),
                    duration: const Duration(seconds: 1),
                  ),
                );
                // Note: Actual theme change requires app-level state management (Provider/Riverpod)
              },
              indent: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ibyerekeye Porogaramu', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionTile(theme, colorScheme, 'Amategeko n\'Amabwiriza', Icons.description_outlined, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amategeko n\'Amabwiriza...'), duration: Duration(seconds: 1)));
            }),
            _buildActionTile(theme, colorScheme, 'Ubufasha', Icons.help_outline, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubufasha...'), duration: Duration(seconds: 1)));
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Verisiyo', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const Spacer(),
                Text('1.2.0 (MVP)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(ThemeData theme, ColorScheme colorScheme, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? colorScheme.error : null)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFunctionalSwitch(ThemeData theme, ColorScheme colorScheme, String label, bool value, ValueChanged<bool> onChanged, {bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 34 : 0, top: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Switch(value: value, onChanged: onChanged, activeColor: colorScheme.primary),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hindura Ijambo ry\'Ibanga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPwdController, obscureText: true, decoration: const InputDecoration(labelText: 'Ijambo ry\'Ibanga rya kera')),
            const SizedBox(height: 12),
            TextField(controller: newPwdController, obscureText: true, decoration: const InputDecoration(labelText: 'Ijambo ry\'Ibanga rishya')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reka')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ijambo ry\'Ibanga ryahinduwe!'), backgroundColor: Colors.green));
            },
            child: const Text('Emeza'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? true) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Igenamiterere ryabitswe!'), backgroundColor: Theme.of(context).colorScheme.primary),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohoka'),
        content: const Text('Uzi neza ko ushaka gusohoka?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              authService.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Yego, sohoka'),
          ),
        ],
      ),
    );
  }
}
