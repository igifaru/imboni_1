import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/location_selector.dart';
import '../../shared/services/admin_units_service.dart';

/// Profile Screen - User profile management
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
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Umwirondoro wanjye'),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 24),
            // Avatar
            Stack(
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.primaryDark]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: ImboniColors.primary.withAlpha(75), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: Text(
                      user?.phone?.substring(0, 2).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: ImboniColors.secondary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(user?.phone ?? 'Umukiriya', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Text(user?.isCitizen == true ? 'Umuturage' : 'Umuyobozi', style: const TextStyle(color: ImboniColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const SizedBox(height: 32),

            // Profile sections
            _buildSectionCard(theme, 'Amakuru y\'umuntu', [
              _buildInfoRow(theme, 'Telefoni', user?.phone ?? '-', Icons.phone_outlined, editable: false),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                _buildEditableField('Amazina yombi', _namesController, Icons.person_outlined),
                const SizedBox(height: 16),
                _buildEditableField('Imeli', _emailController, Icons.email_outlined),
              ] else ...[
                if (user?.email != null) _buildInfoRow(theme, 'Imeli', user!.email!, Icons.email_outlined),
              ],
            ]),
            const SizedBox(height: 16),

            _buildSectionCard(theme, 'Aho ntuye', [
              if (_isEditing)
                LocationSelector(initialSelection: _location, onLocationChanged: (loc) => setState(() => _location = loc), showVillage: true)
              else
                _buildInfoRow(theme, 'Aderesi', _location.isComplete ? _location.fullAddress : 'Ntiyuzuzwa', Icons.location_on_outlined),
            ]),
            const SizedBox(height: 16),

            _buildSectionCard(theme, 'Ibyerekeye konti', [
              _buildInfoRow(theme, 'Yafunguwe', '-', Icons.calendar_today_outlined),
              _buildInfoRow(theme, 'Imimerere', user?.status ?? 'ACTIVE', Icons.verified_outlined, color: ImboniColors.success),
            ]),
            const SizedBox(height: 24),

            // Actions
            Card(
              child: Column(children: [
                _buildActionTile(theme, 'Hindura ijambo ry\'ibanga', Icons.lock_outlined, () {}),
                const Divider(height: 1),
                _buildActionTile(theme, 'Ubutumwa', Icons.notifications_outlined, () {}, badge: 3),
                const Divider(height: 1),
                _buildActionTile(theme, 'Ubufasha', Icons.help_outline, () {}),
                const Divider(height: 1),
                _buildActionTile(theme, 'Sohoka', Icons.logout, _logout, isDestructive: true),
              ]),
            ),
            const SizedBox(height: 32),

            Text('Imboni v1.0.0', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 48),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, IconData icon, {bool editable = true, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (color ?? ImboniColors.primary).withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color ?? ImboniColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _buildActionTile(ThemeData theme, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false, int? badge}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (isDestructive ? ImboniColors.error : ImboniColors.primary).withAlpha(25), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isDestructive ? ImboniColors.error : ImboniColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? ImboniColors.error : null)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: ImboniColors.error, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Umwirondoro wabitswe!'), backgroundColor: ImboniColors.success));
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
            style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.error),
            child: const Text('Yego, sohoka'),
          ),
        ],
      ),
    );
  }
}
