import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'verification_screen.dart';

class ProjectVerificationsScreen extends StatefulWidget {
  final Project project;

  const ProjectVerificationsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectVerificationsScreen> createState() => _ProjectVerificationsScreenState();
}

class _ProjectVerificationsScreenState extends State<ProjectVerificationsScreen> {
  List<CitizenVerification> _verifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() => _isLoading = true);
    try {
      final verifications = await pftcvService.getProjectVerifications(widget.project.id);
      if (mounted) setState(() => _verifications = verifications);
    } catch (e) {
      debugPrint('Error loading verifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text("Igenzura ry'Abaturage"),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _verifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_outlined, size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Nta bitekerezo biratangwa',
                        style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _verifications.length,
                  itemBuilder: (context, index) {
                    final verification = _verifications[index];
                    return _VerificationCard(
                      verification: verification,
                      theme: theme,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      isOwner: authService.currentUser?.id == verification.verifierId,
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerificationScreen(
                              project: widget.project,
                              existingVerification: verification,
                            ),
                          ),
                        );
                        if (result == true) _loadVerifications();
                      },
                    );
                  },
                ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final CitizenVerification verification;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isOwner;
  final VoidCallback? onEdit;

  const _VerificationCard({
    required this.verification,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
    this.isOwner = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: ImboniColors.primary.withAlpha(30),
                    child: Icon(
                      verification.isAnonymous ? Icons.person_outline : Icons.person,
                      size: 18,
                      color: ImboniColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    verification.isAnonymous ? 'Umuturage (Anonymous)' : 'Umuturage',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (verification.qualityRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${verification.qualityRating}/5',
                            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber[900]),
                          ),
                        ],
                      ),
                    ),
                  if (isOwner)
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: colorScheme.primary),
                      onPressed: onEdit,
                      tooltip: 'Vugurura',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (verification.comment != null && verification.comment!.isNotEmpty) ...[
            Text(
              verification.comment!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
          ],
          
          if (verification.evidence.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: verification.evidence.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = verification.evidence[index];
                  if (item['url'] == null) return const SizedBox();
                  debugPrint('Rendering Evidence Item: type=${item['type']}, url=${item['url']}, mime=${item['mimeType']}');
                  
                  final isImage = item['type'] == 'IMAGE';
                  final url = ApiClient.baseUrl.replaceAll('/api', '') + item['url'];
                  
                  return GestureDetector(
                    onTap: () {
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
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black12,
                        image: isImage ? DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: !isImage ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70)) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          Divider(color: colorScheme.outlineVariant.withAlpha(80)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: verification.deliveryStatus),
              Text(
                '${verification.completionPercent}% birangiye',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DeliveryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case DeliveryStatus.fullyDelivered:
        color = ImboniColors.success;
        break;
      case DeliveryStatus.partiallyDelivered:
        color = ImboniColors.warning;
        break;
      case DeliveryStatus.notDelivered:
        color = ImboniColors.error;
        break;
      case DeliveryStatus.notStarted:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
