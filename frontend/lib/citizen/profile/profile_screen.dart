import 'package:flutter/material.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/settings_service.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/services/admin_units_service.dart';

/// Settings Screen - Fully functional with real backend integration
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  LocationSelection _location = const LocationSelection();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = authService.currentUser;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email ?? '';
      _nationalIdController.text = user.nationalId ?? '';
      _location = LocationSelection(
        province: user.province,
        district: user.district,
        sector: user.sector,
        cell: user.cell,
        village: user.village,
      );
    }
  }

  @override
  void dispose() { _nameController.dispose(); _phoneController.dispose(); _emailController.dispose(); _nationalIdController.dispose(); super.dispose(); }

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
            TextButton(onPressed: _isLoading ? null : _saveProfile, child: const Text('Bika'))
          else
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _isEditing = true)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    }
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
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveProfile,
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
                  backgroundImage: user?.profilePicture != null ? NetworkImage(user!.profilePicture!) : null,
                  child: user?.profilePicture == null ? Text(
                    user?.initials ?? 'U',
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Umukiriya', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(user?.roleDisplayName ?? 'Umuturage', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // User Details Section
            _buildInfoRow(theme, colorScheme, Icons.badge_outlined, 'Indangamuntu', user?.nationalId ?? 'Ntiyanditswe'),
            _buildInfoRow(theme, colorScheme, Icons.verified_user_outlined, 'Urwego', user?.roleDisplayName ?? '-'),
            _buildInfoRow(theme, colorScheme, Icons.check_circle_outlined, 'Imiterere', user?.statusDisplayName ?? '-'),
            _buildInfoRow(theme, colorScheme, Icons.calendar_today_outlined, 'Yiyandikishije', _formatDateTime(user?.createdAt)),
            _buildInfoRow(theme, colorScheme, Icons.location_on_outlined, 'Aho abarizwa', user?.fullLocation ?? 'Ntabwo yuzuye'),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Amazina yombi', prefixIcon: Icon(Icons.person_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefoni', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Imeli', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalIdController,
                decoration: const InputDecoration(labelText: 'Indangamuntu', prefixIcon: Icon(Icons.badge_outlined)),
                keyboardType: TextInputType.number,
                maxLength: 16,
              ),
              const SizedBox(height: 16),
              Text('Aho utuye', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              LocationSelector(
                initialSelection: _location,
                onLocationChanged: (loc) => setState(() => _location = loc),
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

  Widget _buildInfoRow(ThemeData theme, ColorScheme colorScheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    final d = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final t = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  Widget _buildPreferencesSection(ThemeData theme, ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ibyo Mhitamo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Language
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
                        value: settingsService.language,
                        isDense: true,
                        items: ['Kinyarwanda', 'English', 'Français'].map((o) => DropdownMenuItem(value: o, child: Text(o, style: theme.textTheme.bodySmall))).toList(),
                        onChanged: (v) {
                          if (v != null) settingsService.setLanguage(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Notifications
              Row(children: [Icon(Icons.notifications_outlined, color: colorScheme.primary, size: 22), const SizedBox(width: 12), Text('Menyesha', style: theme.textTheme.bodyMedium)]),
              _buildSwitch('Imeli', settingsService.emailNotifications, (v) => settingsService.setEmailNotifications(v), theme, colorScheme),
              _buildSwitch('SMS', settingsService.smsNotifications, (v) => settingsService.setSmsNotifications(v), theme, colorScheme),
              const SizedBox(height: 16),
              // Theme
              Row(children: [Icon(Icons.palette_outlined, color: colorScheme.primary, size: 22), const SizedBox(width: 12), Text('Insanganyamatsiko', style: theme.textTheme.bodyMedium)]),
              _buildSwitch('Ijoro (Dark Mode)', settingsService.isDarkMode, (v) => settingsService.setDarkMode(v), theme, colorScheme),
            ],
          ),
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
            Row(children: [Text('Verisiyo', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)), const Spacer(), Text('1.2.0 (MVP)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(ThemeData theme, ColorScheme colorScheme, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? colorScheme.error : colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: TextStyle(color: isDestructive ? colorScheme.error : null)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 34, top: 4),
      child: Row(children: [Expanded(child: Text(label, style: theme.textTheme.bodyMedium)), Switch(value: value, onChanged: onChanged, activeColor: colorScheme.primary)]),
    );
  }

  void _showChangePasswordDialog() {
    final oldPwd = TextEditingController();
    final newPwd = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hindura Ijambo ry\'Ibanga'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldPwd, obscureText: true, decoration: const InputDecoration(labelText: 'Ijambo ry\'Ibanga rya kera')),
          const SizedBox(height: 12),
          TextField(controller: newPwd, obscureText: true, decoration: const InputDecoration(labelText: 'Ijambo ry\'Ibanga rishya')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reka')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final result = await authService.changePassword(currentPassword: oldPwd.text, newPassword: newPwd.text);
              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.isSuccess ? 'Ijambo ry\'Ibanga ryahinduwe!' : result.error ?? 'Byanze'),
                  backgroundColor: result.isSuccess ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Emeza'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_isEditing || !(_formKey.currentState?.validate() ?? true)) return;
    setState(() => _isLoading = true);
    final result = await authService.updateProfile(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      nationalId: _nationalIdController.text.isNotEmpty ? _nationalIdController.text : null,
      province: _location.province,
      district: _location.district,
      sector: _location.sector,
      cell: _location.cell,
      village: _location.village,
    );
    setState(() { _isLoading = false; _isEditing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.isSuccess ? 'Umwirondoro wabitswe!' : result.error ?? 'Byanze'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ));
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
            onPressed: () { Navigator.pop(ctx); authService.logout(); Navigator.of(context).popUntil((route) => route.isFirst); },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Yego, sohoka'),
          ),
        ],
      ),
    );
  }
}
