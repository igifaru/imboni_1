// Citizen Verification Screen - Professional Premium Design
import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';

class VerificationScreen extends StatefulWidget {
  final Project project;
  const VerificationScreen({super.key, required this.project});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  DeliveryStatus _selectedStatus = DeliveryStatus.notStarted;
  int _completionPercent = 0;
  int _qualityRating = 3;
  final _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await pftcvService.submitVerification(
        projectId: widget.project.id,
        deliveryStatus: _selectedStatus.name.toUpperCase(),
        completionPercent: _completionPercent,
        qualityRating: _qualityRating,
        comment: _commentController.text,
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Igenzura ryoherejwe neza!')]),
              backgroundColor: ImboniColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Habaye ikibazo. Ongera ugerageze.'),
              backgroundColor: ImboniColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ikosa: $e'),
            backgroundColor: ImboniColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Genzura Umushinga'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final maxWidth = isWide ? 900.0 : double.infinity;
          final padding = isWide ? 32.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    // Project Info Header Card
                    _buildProjectHeader(theme, colorScheme, isDark),
                    const SizedBox(height: 32),

                    // Two-column layout for wide screens
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLeftColumn(theme, colorScheme, isDark)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildRightColumn(theme, colorScheme, isDark)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildLeftColumn(theme, colorScheme, isDark),
                          const SizedBox(height: 24),
                          _buildRightColumn(theme, colorScheme, isDark),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Comment Section - Full Width
                    _buildCommentSection(theme, colorScheme, isDark),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(theme, colorScheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectHeader(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
            ),
            child: Icon(widget.project.sector.icon, size: 36, color: ImboniColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.project.projectCode,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: ImboniColors.primary),
                  ),
                ),
                if (widget.project.locationName != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(widget.project.locationName!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Delivery Status Card
        _buildSectionCard(
          theme: theme,
          colorScheme: colorScheme,
          isDark: isDark,
          icon: Icons.local_shipping,
          title: 'Imirimo yagezweho ite?',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: DeliveryStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedStatus = status),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? ImboniColors.primary : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ImboniColors.primary : colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: ImboniColors.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Completion Percentage Card
        _buildSectionCard(
          theme: theme,
          colorScheme: colorScheme,
          isDark: isDark,
          icon: Icons.trending_up,
          title: "Igipimo cy'Imirimo yarangiye",
          child: Column(
            children: [
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: ImboniColors.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  thumbColor: ImboniColors.primary,
                  overlayColor: ImboniColors.primary.withAlpha(30),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                ),
                child: Slider(
                  value: _completionPercent.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => setState(() => _completionPercent = v.round()),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ImboniColors.primary.withAlpha(30), ImboniColors.secondary.withAlpha(20)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_completionPercent%',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Quality Rating Card
        _buildSectionCard(
          theme: theme,
          colorScheme: colorScheme,
          isDark: isDark,
          icon: Icons.star_rate,
          title: "Igipimo cy'Ubuziranenge",
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _qualityRating = rating),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        rating <= _qualityRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: rating <= _qualityRating ? Colors.amber : Colors.grey[400],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_qualityRating / 5',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Anonymous Toggle in right column
        _buildAnonymousToggle(theme, colorScheme),
      ],
    );
  }

  Widget _buildCommentSection(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return _buildSectionCard(
      theme: theme,
      colorScheme: colorScheme,
      isDark: isDark,
      icon: Icons.comment,
      title: 'Ibitekerezo (Ntibisabwa)',
      child: TextField(
        controller: _commentController,
        maxLines: 4,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Andika ibitekerezo byawe hano...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: colorScheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildAnonymousToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isAnonymous ? ImboniColors.primary.withAlpha(30) : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.privacy_tip_rounded, color: _isAnonymous ? ImboniColors.primary : Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ohereza mu ibanga', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Izina ryawe ntabwo rizerekanwa', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAnonymous,
            onChanged: (v) => setState(() => _isAnonymous = v),
            activeTrackColor: ImboniColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: ImboniColors.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [ImboniColors.primary, ImboniColors.primaryDark]),
        boxShadow: [BoxShadow(color: ImboniColors.primary.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitVerification,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Ohereza Igenzura', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
