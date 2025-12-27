import 'package:flutter/material.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/services/admin_units_service.dart';

/// Profile Screen - User profile management (Theme Compliant)
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = authService.currentUser;
    if (user != null) {
      _namesController.text = user.phone ?? '';
    }
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
                // Desktop: 3-column layout
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
                // Mobile: Single column
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
            // Avatar row
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
            const SizedBox(height: 16),
            const Divider(),
            _buildActionTile(theme, colorScheme, 'Hindura Umwirondoro', Icons.edit_outlined, () => setState(() => _isEditing = true)),
            _buildActionTile(theme, colorScheme, 'Hindura Ijambo ry\'Ibanga', Icons.lock_outlined, () {}),
            _buildActionTile(theme, colorScheme, 'Umutekano', Icons.security_outlined, () {}),
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
            _buildDropdownRow(theme, colorScheme, 'Ururimi', Icons.language_outlined, 'Kinyarwanda', ['Kinyarwanda', 'English', 'Français']),
            const SizedBox(height: 12),
            _buildSwitchRow(theme, colorScheme, 'Menyesha', Icons.notifications_outlined, null),
            _buildSwitchRow(theme, colorScheme, 'Imeli', null, true, indent: true),
            _buildSwitchRow(theme, colorScheme, 'SMS', null, false, indent: true),
            const SizedBox(height: 12),
            _buildSwitchRow(theme, colorScheme, 'Insanganyamatsiko', Icons.dark_mode_outlined, null),
            _buildSwitchRow(theme, colorScheme, 'Light Mode', null, true, indent: true),
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
            _buildActionTile(theme, colorScheme, 'Amategeko n\'Amabwiriza', Icons.description_outlined, () {}),
            _buildActionTile(theme, colorScheme, 'Ubufasha', Icons.help_outline, () {}),
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

  Widget _buildActionTile(ThemeData theme, ColorScheme colorScheme, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primary.withAlpha(25), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDropdownRow(ThemeData theme, ColorScheme colorScheme, String label, IconData icon, String value, List<String> options) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: theme.textTheme.bodySmall))).toList(),
              onChanged: (v) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(ThemeData theme, ColorScheme colorScheme, String label, IconData? icon, bool? value, {bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 34 : 0, top: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
          ],
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          if (value != null)
            Switch(value: value, onChanged: (v) {}, activeColor: colorScheme.primary),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? true) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Umwirondoro wabitswe!'), backgroundColor: Theme.of(context).colorScheme.primary),
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
