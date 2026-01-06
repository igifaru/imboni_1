// Project Detail Screen - Professional Premium Design
import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';
import 'verification_screen.dart';
import 'project_verifications_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final bool embedded;
  final VoidCallback? onBack;
  const ProjectDetailScreen({super.key, required this.projectId, this.embedded = false, this.onBack});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    try {
      final project = await pftcvService.getProjectById(widget.projectId);
      if (mounted) setState(() => _project = project);
    } catch (e) {
      debugPrint('Error loading project: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerificationScreen(project: _project!)),
    );
    if (result == true) _loadProject();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return widget.embedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    if (_project == null) {
      return widget.embedded
          ? const Center(child: Text('Umushinga ntabwo ubonetse'))
          : Scaffold(appBar: AppBar(), body: const Center(child: Text('Umushinga ntabwo ubonetse')));
    }

    final p = _project!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          
          return CustomScrollView(
            slivers: [
              // Header with back button and title on same row
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
                  child: Stack(
                    children: [
                      // Background icon
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(p.sector.icon, size: 100, color: colorScheme.primary.withAlpha(15)),
                      ),
                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button and title row
                          Row(
                            children: [
                              Material(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: widget.embedded && widget.onBack != null ? widget.onBack : () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface, size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

              // Content
              SliverPadding(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          // Status Row
                          _buildStatusRow(theme, colorScheme, p),
                          const SizedBox(height: 24),

                          // Two-column layout for wide screens
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildLeftColumn(theme, colorScheme, isDark, p)),
                                const SizedBox(width: 24),
                                Expanded(child: _buildRightColumn(theme, colorScheme, isDark, p)),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildBudgetCard(theme, colorScheme, isDark, p),
                                const SizedBox(height: 16),
                                _buildLocationCard(theme, colorScheme, isDark, p),
                                const SizedBox(height: 16),
                                _buildDetailsCard(theme, colorScheme, isDark, p),
                                const SizedBox(height: 16),
                                _buildVerificationCard(theme, colorScheme, isDark, p),
                              ],
                            ),

                          const SizedBox(height: 100), // Space for FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildVerifyButton(colorScheme),
    );
  }

  Widget _buildStatusRow(ThemeData theme, ColorScheme colorScheme, Project p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          _StatusChip(label: p.status.label, color: p.status.color, icon: Icons.flag_rounded),
          const SizedBox(width: 12),
          _StatusChip(label: p.riskLevel.label, color: p.riskLevel.color, icon: Icons.shield_rounded),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.projectCode,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(ThemeData theme, ColorScheme colorScheme, bool isDark, Project p) {
    return Column(
      children: [
        _buildBudgetCard(theme, colorScheme, isDark, p),
        const SizedBox(height: 20),
        _buildLocationCard(theme, colorScheme, isDark, p),
      ],
    );
  }

  Widget _buildRightColumn(ThemeData theme, ColorScheme colorScheme, bool isDark, Project p) {
    return Column(
      children: [
        _buildDetailsCard(theme, colorScheme, isDark, p),
        const SizedBox(height: 20),
        _buildVerificationCard(theme, colorScheme, isDark, p),
      ],
    );
  }

  Widget _buildBudgetCard(ThemeData theme, ColorScheme colorScheme, bool isDark, Project p) {
    return _SectionCard(
      isDark: isDark,
      colorScheme: colorScheme,
      icon: Icons.account_balance_wallet_rounded,
      title: 'Imari',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yemewe', style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
                  const SizedBox(height: 4),
                  Text(p.budgetFormatted, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Yatanzwe', style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
                  const SizedBox(height: 4),
                  Text(p.releasedFormatted, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p.releaseRatio.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(ImboniColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Igice cyatanzwe', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ImboniColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(p.releaseRatio * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme, ColorScheme colorScheme, bool isDark, Project p) {
    return _SectionCard(
      isDark: isDark,
      colorScheme: colorScheme,
      icon: Icons.location_on_rounded,
      title: 'Ahantu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.locationName != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ImboniColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.place, size: 20, color: ImboniColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p.locationName!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          if (p.gpsLatitude != null && p.gpsLongitude != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: colorScheme.onSurface.withAlpha(180)),
                  const SizedBox(width: 8),
                  Text(
                    '${p.gpsLatitude!.toStringAsFixed(5)}, ${p.gpsLongitude!.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme, ColorScheme colorScheme, bool isDark, Project p) {
    return _SectionCard(
      isDark: isDark,
      colorScheme: colorScheme,
      icon: Icons.info_rounded,
      title: 'Amakuru',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.description != null) ...[
            Text(p.description!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant.withAlpha(80)),
            const SizedBox(height: 12),
          ],
          if (p.implementingAgency != null)
            _DetailRow(icon: Icons.apartment, label: 'Ishami', value: p.implementingAgency!),
          if (p.fundingSource != null)
            _DetailRow(icon: Icons.payments, label: 'Inkomoko', value: p.fundingSource!),
          if (p.expectedOutputs != null)
            _DetailRow(icon: Icons.checklist, label: 'Ibizakorwa', value: p.expectedOutputs!),
          if (p.startDate != null)
            _DetailRow(icon: Icons.calendar_today, label: 'Itangira', value: _formatDate(p.startDate!)),
          if (p.endDate != null)
            _DetailRow(icon: Icons.event_available, label: 'Irangira', value: _formatDate(p.endDate!)),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(ThemeData theme, ColorScheme colorScheme, bool isDark, Project p) {
    return _SectionCard(
      isDark: isDark,
      colorScheme: colorScheme,
      icon: Icons.verified_user_rounded,
      title: "Igenzura ry'Abaturage",
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectVerificationsScreen(projectId: p.id, projectName: p.name)),
      ),
      child: Row(
        children: [
          Expanded(child: _StatBox(value: '${p.verificationCount}', label: 'Bagenzuye', color: ImboniColors.info)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox(value: '${p.verifiedPercentage}%', label: 'Byemejwe', color: ImboniColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox(value: '${p.riskScore}', label: 'Imiterere', color: p.riskLevel.color)),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.primaryDark]),
        boxShadow: [BoxShadow(color: ImboniColors.primary.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openVerification,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Genzura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.isDark,
    required this.colorScheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 20, color: ImboniColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurface.withAlpha(100)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurface.withAlpha(180)),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
        ],
      ),
    );
  }
}
