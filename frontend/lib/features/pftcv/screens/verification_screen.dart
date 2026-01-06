// Citizen Verification Screen - Professional Premium Design
import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/services/api_client.dart';
import '../models/pftcv_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pftcv_service.dart';

class VerificationScreen extends StatefulWidget {
  final Project project;
  final CitizenVerification? existingVerification;
  const VerificationScreen({super.key, required this.project, this.existingVerification});

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
  final List<Map<String, dynamic>> _evidence = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingVerification != null) {
      _selectedStatus = widget.existingVerification!.deliveryStatus;
      _completionPercent = widget.existingVerification!.completionPercent;
      _qualityRating = widget.existingVerification!.qualityRating ?? 3;
      _commentController.text = widget.existingVerification!.comment ?? '';
      _isAnonymous = widget.existingVerification!.isAnonymous;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    try {
      final result = widget.existingVerification != null
          ? await pftcvService.updateVerification(
              projectId: widget.project.id,
              deliveryStatus: switch (_selectedStatus) {
                DeliveryStatus.fullyDelivered => 'FULLY_DELIVERED',
                DeliveryStatus.partiallyDelivered => 'PARTIALLY_DELIVERED',
                DeliveryStatus.notDelivered => 'NOT_DELIVERED',
                DeliveryStatus.notStarted => 'NOT_STARTED',
              },
              completionPercent: _completionPercent,
              qualityRating: _qualityRating,
              comment: _commentController.text,
              isAnonymous: _isAnonymous,
              evidence: _evidence,
              gpsLatitude: widget.existingVerification?.gpsLatitude,
              gpsLongitude: widget.existingVerification?.gpsLongitude,
            )
          : await pftcvService.submitVerification(
              projectId: widget.project.id,
              deliveryStatus: switch (_selectedStatus) {
                DeliveryStatus.fullyDelivered => 'FULLY_DELIVERED',
                DeliveryStatus.partiallyDelivered => 'PARTIALLY_DELIVERED',
                DeliveryStatus.notDelivered => 'NOT_DELIVERED',
                DeliveryStatus.notStarted => 'NOT_STARTED',
              },
              completionPercent: _completionPercent,
              qualityRating: _qualityRating,
              comment: _commentController.text,
              isAnonymous: _isAnonymous,
              evidence: _evidence,
            );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text(widget.existingVerification != null ? 'Igenzura ryavuguruwe!' : 'Igenzura ryoherejwe neza!')]),
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
    } catch (e, stackTrace) {
      debugPrint('Error submitting/updating verification: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        // Assuming showCustomSnackBar and SnackBarType are defined elsewhere or imported
        // For this example, I'll use a standard SnackBar as showCustomSnackBar is not provided.
        // If showCustomSnackBar is a custom widget, it needs to be defined or imported.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Habaye ikibazo. Ongera ugerageze. Error: $e'),
            backgroundColor: ImboniColors.error, // Assuming ImboniColors.error is the equivalent of SnackBarType.error
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: Text(widget.existingVerification != null ? 'Vugurura Igenzura' : 'Genzura Umushinga'),
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
                    const SizedBox(height: 24),

                    // Evidence Upload Section
                    _buildEvidenceSection(theme, colorScheme),
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

  Widget _buildEvidenceSection(ThemeData theme, ColorScheme colorScheme) {
    return _buildSectionCard(
      theme: theme,
      colorScheme: colorScheme,
      isDark: false, // Force light shadow for consistency or pass proper isDark
      icon: Icons.attach_file,
      title: 'Ibimenyetso (Amafoto/Video)',
      child: Column(
        children: [
          if (_evidence.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _evidence.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _evidence[index];
                  if (item['url'] == null) return const SizedBox();
                  
                  final isImage = item['type'] == 'IMAGE';
                  final url = ApiClient.baseUrl.replaceAll('/api', '') + item['url'];
                    
                  IconData icon;
                  Color iconColor;
                  String label;

                  switch (item['type']) {
                    case 'VIDEO':
                      icon = Icons.play_circle_fill;
                      iconColor = Colors.white;
                      label = 'Video';
                      break;
                    case 'AUDIO':
                      icon = Icons.audiotrack;
                      iconColor = Colors.white;
                      label = 'Audio';
                      break;
                    case 'DOCUMENT':
                      icon = Icons.description;
                      iconColor = Colors.white;
                      label = 'Inyandiko';
                      break;
                    default:
                      icon = Icons.insert_drive_file;
                      iconColor = Colors.white;
                      label = 'File';
                  }

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _viewMedia(item),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: colorScheme.surfaceContainerHighest,
                            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (isImage)
                                Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(Icons.broken_image_rounded, color: colorScheme.onSurfaceVariant),
                                  ),
                                )
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.black26, 
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: iconColor, size: 32),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _evidence.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUploadButton(
                  icon: Icons.camera_alt,
                  label: 'Ifoto',
                  onTap: () => _pickMedia(FileType.image),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _buildUploadButton(
                  icon: Icons.attach_file,
                  label: 'File',
                  onTap: () => _pickMedia(FileType.any),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _buildUploadButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () => _pickMedia(FileType.video),
                  colorScheme: colorScheme,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withAlpha(100)),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(FileType type) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        
        final uploadResult = await pftcvService.uploadEvidence(result.files.single.path!);
        
        if (uploadResult != null) {
          setState(() {
            _evidence.add(uploadResult);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload file')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _viewMedia(Map<String, dynamic> item) {
    final url = ApiClient.baseUrl.replaceAll('/api', '') + item['url'];
    final isImage = item['type'] == 'IMAGE';

    if (isImage) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: Image.network(url),
              ),
              Positioned(
                top: 40, 
                right: 20, 
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30), 
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Open video/file in external app
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(widget.existingVerification != null ? 'Vugurura Igenzura' : 'Ohereza Igenzura', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
