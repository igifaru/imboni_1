import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/case_service.dart';
import '../../shared/models/models.dart';
import '../report_case/submit_case_screen.dart';
import '../profile/profile_screen.dart';
import '../my_cases/my_cases_screen.dart';
import '../../leader/dashboard/widgets/professional_case_card.dart';
import '../../features/community/screens/community_home_screen.dart';

/// Citizen Home Screen - Professional design with theme support
class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  List<CaseModel> _recentCases = [];
  List<CaseModel> _allCases = [];
  bool _isLoading = true;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all user cases for accurate counts
      final allResponse = await caseService.getUserCases(limit: 100);
      if (mounted) {
        final cases = allResponse.isSuccess && allResponse.data != null ? allResponse.data! : <CaseModel>[];
        setState(() {
          _isLoading = false;
          _allCases = cases;
          _recentCases = cases.take(3).toList();
          // Notification count = pending cases (open or in progress)
          _notificationCount = cases.where((c) => c.status == 'OPEN' || c.status == 'IN_PROGRESS').length;
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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
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
          ),
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
            isLabelVisible: _notificationCount > 0,
            label: Text('$_notificationCount'),
            child: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
          ),
          onPressed: () => _navigateTo(const MyCasesScreen()),
          tooltip: AppLocalizations.of(context).notificationsLabel,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: user?.profilePicture == null ? ImboniColors.primary : Colors.transparent,
              backgroundImage: user?.profilePicture != null 
                  ? NetworkImage(user!.profilePicture!)
                  : null,
              child: user?.profilePicture == null 
                  ? Text(
                      user?.initials ?? 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, AppLocalizations l10n, bool isDark) {
    final totalCount = _allCases.length;
    final resolvedCount = _allCases.where((c) => c.status == 'RESOLVED' || c.status == 'CLOSED').length;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ImboniColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ImboniColors.primary.withValues(alpha: isDark ? 1.0 : 0.9),
                      ImboniColors.primaryDark.withValues(alpha: isDark ? 1.0 : 0.9),
                      ImboniColors.primary.withValues(alpha: isDark ? 0.9 : 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Decorative Background Circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: 50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideBanner = constraints.maxWidth > 650;
                  
                  return Flex(
                    direction: isWideBanner ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: isWideBanner ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWideBanner ? 1 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.welcomeMessage,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.welcomeSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isWideBanner ? 20 : 0,
                        height: isWideBanner ? 0 : 20,
                      ),
                      
                      // Glassmorphic Stats Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatItem(Icons.folder_copy_rounded, '$totalCount', l10n.yourCases, true),
                              Container(
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              _buildStatItem(Icons.verified_rounded, '$resolvedCount', l10n.resolvedCases, true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label, bool isBanner) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileQuickActions(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Column(children: [
      Row(children: [
        Expanded(child: _QuickActionCard(icon: Icons.add_circle_outline, label: l10n.submitCase, subtitle: l10n.submitCaseSubtitle, color: ImboniColors.primary, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen()))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.search, label: l10n.trackCase, subtitle: l10n.trackCaseSubtitle, color: ImboniColors.secondary, theme: theme, onTap: _showTrackCaseDialog)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _QuickActionCard(icon: Icons.warning_amber_rounded, label: l10n.emergency, subtitle: l10n.emergencySubtitle, color: ImboniColors.urgencyEmergency, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen(isEmergency: true)))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.folder_copy_outlined, label: l10n.myCasesTitle, subtitle: l10n.myCasesSubtitle, color: ImboniColors.info, theme: theme, onTap: () => _navigateTo(const MyCasesScreen()))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _QuickActionCard(icon: Icons.people_outline, label: 'Community', subtitle: 'Connect with neighbors', color: ImboniColors.categorySocial, theme: theme, onTap: () => _navigateTo(const CommunityHomeScreen()))),
      ]),
    ]);
  }

  Widget _buildWideQuickActions(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Row(children: [
      Expanded(child: _QuickActionCard(icon: Icons.add_circle_outline, label: l10n.submitCase, subtitle: l10n.submitCaseSubtitle, color: ImboniColors.primary, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen()))),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.search, label: l10n.trackCase, subtitle: l10n.trackCaseSubtitle, color: ImboniColors.secondary, theme: theme, onTap: _showTrackCaseDialog)),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.warning_amber_rounded, label: l10n.emergency, subtitle: l10n.emergencySubtitle, color: ImboniColors.urgencyEmergency, theme: theme, onTap: () => _navigateTo(const SubmitCaseScreen(isEmergency: true)))),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.folder_copy_outlined, label: l10n.myCasesTitle, subtitle: l10n.myCasesSubtitle, color: ImboniColors.info, theme: theme, onTap: () => _navigateTo(const MyCasesScreen()))),
      const SizedBox(width: 16),
      Expanded(child: _QuickActionCard(icon: Icons.people_outline, label: 'Community', subtitle: 'Connect with neighbors', color: ImboniColors.categorySocial, theme: theme, onTap: () => _navigateTo(const CommunityHomeScreen()))),
    ]);
  }

  Widget _buildRecentCasesSection(ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l10n.recentCases, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (_recentCases.isNotEmpty) TextButton(onPressed: () => _navigateTo(const MyCasesScreen()), child: Text('${l10n.viewAllCases} →')),
      ]),
      const SizedBox(height: 16),
      if (_isLoading)
        Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: CircularProgressIndicator()),
        )
      else if (_recentCases.isEmpty)
        _buildEmptyState(theme, isDark, l10n)
    else
      LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentCases.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 250,
            ),
            itemBuilder: (context, index) {
              final c = _recentCases[index];
              return ProfessionalCaseCard(
                caseData: c,
                onTap: () => _navigateTo(CitizenCaseDetailsScreen(caseModel: c)),
              );
            },
          );
        }
      ),
    ]);
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, AppLocalizations l10n) {
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
          decoration: BoxDecoration(color: ImboniColors.primary.withValues(alpha: isDark ? 0.2 : 0.1), shape: BoxShape.circle),
          child: Icon(Icons.folder_open_outlined, size: 48, color: ImboniColors.primary.withValues(alpha: isDark ? 0.8 : 0.6)),
        ),
        const SizedBox(height: 20),
        Text(l10n.noCasesYet, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.useSumbitCaseHint, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
      ]),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      // Refresh data when returning from any screen
      _loadData();
    });
  }

  void _showTrackCaseDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final controller = TextEditingController();
    String? error;
    bool loading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.cancel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          Future<void> performTrack() async {
            final ref = controller.text.trim();
            if (ref.isEmpty) return;

            setStateDialog(() {
              loading = true;
              error = null;
            });

            try {
              final result = await caseService.trackCase(ref);
              
              if (!ctx.mounted || !mounted) return;

              setStateDialog(() {
                loading = false;
              });

              if (result.isSuccess && result.data != null) {
                Navigator.pop(ctx);
                Navigator.push(
                  this.context, 
                  MaterialPageRoute(builder: (_) => CitizenCaseDetailsScreen(caseModel: result.data!))
                );
              } else {
                 setStateDialog(() {
                   error = l10n.caseNotFound;
                 });
              }
            } catch (e) {
              if (ctx.mounted) {
                setStateDialog(() {
                  loading = false;
                  error = l10n.caseNotFound;
                });
              }
            }
          }

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                  border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ImboniColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, size: 32, color: ImboniColors.primary),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(l10n.trackCase, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(l10n.trackCaseSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    
                    // Input
                    TextField(
                      controller: controller,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: l10n.enterReference,
                        filled: true,
                        fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ImboniColors.primary, width: 2)),
                        errorText: error,
                        prefixIcon: const Icon(Icons.tag, color: ImboniColors.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !loading,
                      onSubmitted: (_) => performTrack(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: theme.colorScheme.onSurfaceVariant,
                            ),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: loading ? null : performTrack,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ImboniColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: loading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(l10n.search, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
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
            border: Border.all(color: isDark ? theme.dividerColor : color.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12)),
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

