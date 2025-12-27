import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/case_card.dart';
import '../report_case/submit_case_screen.dart';
import '../track_case/track_case_screen.dart';
import '../profile/profile_screen.dart';
import '../my_cases/my_cases_screen.dart';

/// Citizen Home Screen - Professional design with theme support
class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  List<CaseModel> _recentCases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentCases();
  }

  Future<void> _loadRecentCases() async {
    setState(() => _isLoading = true);
    try {
      final response = await caseService.getUserCases(limit: 3);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _recentCases = response.isSuccess && response.data != null ? response.data! : [];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = Responsive.isTablet(context) || Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark),
      body: RefreshIndicator(
        onRefresh: _loadRecentCases,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildWelcomeBanner(theme, l10n, isDark),
            const SizedBox(height: 24),
            if (isWide) _buildWideQuickActions(context, l10n, theme) else _buildMobileQuickActions(context, l10n, theme),
            const SizedBox(height: 32),
            _buildRecentCasesSection(theme, isDark),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    final user = authService.currentUser;
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.primaryDark]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shield, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text('Imboni', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ]),
      actions: [
        IconButton(
          icon: Badge(
            label: const Text('1'),
            child: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user?.phone?.substring(0, 2).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, AppLocalizations l10n, bool isDark) {
    final resolvedCount = _recentCases.where((c) => c.status == 'RESOLVED' || c.status == 'CLOSED').length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [ImboniColors.primaryDark.withAlpha(200), ImboniColors.primary.withAlpha(150)]
              : [ImboniColors.primary.withAlpha(30), ImboniColors.secondary.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isDark ? null : Border.all(color: ImboniColors.primary.withAlpha(50)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Murakaza neza kuri Imboni.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : ImboniColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanga ikibazo cyawe, tugufashemo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : ImboniColors.textSecondary,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(20) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            _buildStatItem(Icons.folder_outlined, '${_recentCases.length}', 'Ibibazo byawe', isDark),
            Container(width: 1, height: 40, color: isDark ? Colors.white24 : theme.dividerColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
            _buildStatItem(Icons.check_circle_outline, '$resolvedCount', 'Byakemutse', isDark),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label, bool isDark) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: isDark ? Colors.white70 : ImboniColors.textSecondary),
        const SizedBox(width: 6),
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : ImboniColors.textPrimary)),
      ]),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : ImboniColors.textSecondary)),
    ]);
  }

  Widget _buildMobileQuickActions(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Column(children: [
      Row(children: [
        Expanded(child: _QuickActionCard(icon: Icons.add_circle_outline, label: l10n.submitCase, subtitle: 'Tanga Ikibazo gishya', color: ImboniColors.primary, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen()))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.search, label: l10n.trackCase, subtitle: 'Kurikirana Ikibazo', color: ImboniColors.secondary, theme: theme, onTap: () => _navigateTo(const TrackCaseScreen()))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _QuickActionCard(icon: Icons.warning_amber_rounded, label: l10n.emergency, subtitle: 'Ubutabazi bwihuse', color: ImboniColors.urgencyEmergency, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen(isEmergency: true)))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.folder_copy_outlined, label: 'Ibibazo byanjye', subtitle: 'Reba Ibibazo byawe', color: ImboniColors.info, theme: theme, onTap: () => _navigateTo(const MyCasesScreen()))),
      ]),
    ]);
  }

  Widget _buildWideQuickActions(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Row(children: [
      Expanded(child: _QuickActionCard(icon: Icons.add_circle_outline, label: l10n.submitCase, subtitle: 'Tanga Ikibazo gishya', color: ImboniColors.primary, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen()))),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.search, label: l10n.trackCase, subtitle: 'Kurikirana Ikibazo', color: ImboniColors.secondary, theme: theme, onTap: () => _navigateTo(const TrackCaseScreen()))),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.warning_amber_rounded, label: l10n.emergency, subtitle: 'Ubutabazi bwihuse', color: ImboniColors.urgencyEmergency, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen(isEmergency: true)))),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.folder_copy_outlined, label: 'Ibibazo byanjye', subtitle: 'Reba Ibibazo byawe', color: ImboniColors.info, theme: theme, onTap: () => _navigateTo(const MyCasesScreen()))),
    ]);
  }

  Widget _buildRecentCasesSection(ThemeData theme, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Ibibazo byawe vuba', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (_recentCases.isNotEmpty) TextButton(onPressed: () => _navigateTo(const MyCasesScreen()), child: const Text('Reba byose →')),
      ]),
      const SizedBox(height: 16),
      if (_isLoading)
        Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: CircularProgressIndicator()),
        )
      else if (_recentCases.isEmpty)
        _buildEmptyState(theme, isDark)
      else
        ..._recentCases.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CaseCard(caseReference: c.caseReference, title: c.title, category: c.category, status: c.status, urgency: c.urgency, currentLevel: c.currentLevel, createdAt: c.createdAt, onTap: () {}),
        )),
    ]);
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(isDark ? 50 : 25), shape: BoxShape.circle),
          child: Icon(Icons.folder_open_outlined, size: 48, color: ImboniColors.primary.withAlpha(isDark ? 200 : 150)),
        ),
        const SizedBox(height: 20),
        Text('Nta kibazo ufite', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Koresha "Submit Case" hejuru kugirango utange ikibazo cyawe', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
      ]),
    );
  }

  void _navigateTo(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final ThemeData theme;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? theme.dividerColor : color.withAlpha(50)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(isDark ? 50 : 25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
