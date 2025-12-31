import 'package:flutter/material.dart';

import '../../../../shared/theme/responsive.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/settings_service.dart';
import '../../../../shared/widgets/dialogs/change_password_dialog.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../../main.dart'; // For logout navigation

import '../../../../shared/localization/app_localizations.dart';

class LeaderSettingsScreen extends StatefulWidget {
  const LeaderSettingsScreen({super.key});

  @override
  State<LeaderSettingsScreen> createState() => _LeaderSettingsScreenState();
}

class _LeaderSettingsScreenState extends State<LeaderSettingsScreen> {
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = authService.currentUser;
      if (mounted) setState(() => _user = user);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings), 
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildAccountSection(theme, colorScheme)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPreferencesSection(theme, colorScheme)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSupportSection(theme, colorScheme)),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAccountSection(theme, colorScheme),
                      const SizedBox(height: 16),
                      _buildPreferencesSection(theme, colorScheme),
                      const SizedBox(height: 16),
                      _buildSupportSection(theme, colorScheme),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildAccountSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).myAccount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary,
                  backgroundImage: _user?.profilePicture != null ? NetworkImage(_user!.profilePicture!) : null,
                  child: _user?.profilePicture == null
                      ? Text(
                          _user?.name?.substring(0, 1).toUpperCase() ?? '?',
                          style: TextStyle(fontSize: 20, color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.name ?? 'Leader Name',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _user?.roleDisplayName ?? 'Leader',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _buildInfoRow(theme, colorScheme, Icons.verified_user_outlined, AppLocalizations.of(context).role, _user?.roleDisplayName ?? '-'),
            _buildInfoRow(theme, colorScheme, Icons.location_on_outlined, AppLocalizations.of(context).jurisdiction, _user?.fullLocation ?? '-'),
            const SizedBox(height: 16),
            const Divider(),
            _buildActionTile(theme, colorScheme, AppLocalizations.of(context).changePassword, Icons.lock_outline_rounded, () => showDialog(context: context, builder: (_) => const ChangePasswordDialog())),
            _buildActionTile(theme, colorScheme, AppLocalizations.of(context).logOut, Icons.logout, _logout, isDestructive: true),
          ],
        ),
      ),
    );
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
              Text(AppLocalizations.of(context).preferences, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
               // Language
              Row(
                children: [
                  Icon(Icons.language_outlined, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context).language, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settingsService.language,
                        isDense: true,
                        items: ['English', 'Kinyarwanda', 'Français'].map((o) => DropdownMenuItem(value: o, child: Text(o, style: theme.textTheme.bodySmall))).toList(),
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
              Row(children: [Icon(Icons.notifications_outlined, color: colorScheme.primary, size: 22), const SizedBox(width: 12), Text(AppLocalizations.of(context).notifications, style: theme.textTheme.bodyMedium)]),
              _buildSwitch(AppLocalizations.of(context).emailNotifications, settingsService.emailNotifications, (v) => settingsService.setEmailNotifications(v), theme, colorScheme),
              _buildSwitch(AppLocalizations.of(context).smsAlerts, settingsService.smsNotifications, (v) => settingsService.setSmsNotifications(v), theme, colorScheme),
              const SizedBox(height: 16),
              // Theme
              Row(children: [Icon(Icons.palette_outlined, color: colorScheme.primary, size: 22), const SizedBox(width: 12), Text(AppLocalizations.of(context).theme, style: theme.textTheme.bodyMedium)]),
              _buildSwitch(AppLocalizations.of(context).darkMode, settingsService.isDarkMode, (v) => settingsService.setDarkMode(v), theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).supportAbout, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionTile(theme, colorScheme, AppLocalizations.of(context).helpCenter, Icons.help_outline_rounded, () {}),
            _buildActionTile(theme, colorScheme, AppLocalizations.of(context).privacyPolicy, Icons.privacy_tip_outlined, () {}),
            _buildActionTile(theme, colorScheme, AppLocalizations.of(context).aboutImboni, Icons.info_outline_rounded, () => _showAboutDialog(context)),
            const SizedBox(height: 16),
            Row(children: [Text(AppLocalizations.of(context).version, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)), const Spacer(), Text('1.2.0 (Build 45)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))]),
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
      child: Row(children: [Expanded(child: Text(label, style: theme.textTheme.bodyMedium)), Switch(value: value, onChanged: onChanged, activeThumbColor: colorScheme.primary)]),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Imboni',
        applicationVersion: '1.2.0',
        applicationIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.shield, color: Colors.white),
        ),
        children: const [
          Text('Imboni is a comprehensive dashboard for Rwandan leaders to monitor and manage cases effectively.'),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: AppLocalizations.of(context).logoutConfirmTitle,
        content: AppLocalizations.of(context).logoutConfirmContent,
        confirmText: AppLocalizations.of(context).logOut,
        cancelText: AppLocalizations.of(context).cancel,
        icon: Icons.logout_rounded,
        isDestructive: true,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed == true) {
      await authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ImboniApp()),
          (route) => false,
        );
      }
    }
  }
}
