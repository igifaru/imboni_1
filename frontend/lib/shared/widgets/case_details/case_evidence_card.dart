import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/services/api_client.dart';
import 'case_detail_card.dart';

class CaseEvidenceCard extends StatelessWidget {
  final CaseModel caseModel;
  final Function(EvidenceModel) onEvidenceTap;

  const CaseEvidenceCard({
    super.key,
    required this.caseModel,
    required this.onEvidenceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;

    final hasEvidence = caseModel.evidence != null && caseModel.evidence!.isNotEmpty;

    return CaseDetailCard(
      title: l10n.evidence,
      icon: Icons.attach_file,
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasEvidence)
             Center(
               child: Column(
                 children: [
                   Icon(
                     Icons.folder_off_outlined,
                     size: 40,
                     color: isDark ? Colors.white24 : Colors.grey[400],
                   ),
                   const SizedBox(height: 8),
                   Text(
                     l10n.noEvidenceProvided,
                     style: TextStyle(
                       color: isDark ? Colors.white38 : Colors.grey[500],
                       fontSize: 13,
                     ),
                   ),
                 ],
               ),
             )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: caseModel.evidence!.map((e) {
                final isImage = e.mimeType.startsWith('image/');
                final isAudio = e.mimeType.startsWith('audio/');
                final isVideo = e.mimeType.startsWith('video/');
                final isPdf = e.mimeType == 'application/pdf';
                
                final url = '${ApiClient.storageUrl}${e.url}';
                
                // Extract extension for label
                String ext = 'FILE';
                if (e.fileName.contains('.')) {
                  ext = e.fileName.split('.').last.toUpperCase();
                  if (ext.length > 4) ext = 'FILE'; 
                }

                // Map icon and color
                 IconData icon;
                 Color iconColor;
                 if (isImage) {
                   icon = Icons.image;
                   iconColor = ImboniColors.primary;
                 } else if (isAudio) {
                   icon = Icons.audiotrack;
                   iconColor = ImboniColors.secondary;
                 } else if (isVideo) {
                   icon = Icons.play_circle_outline;
                   iconColor = Colors.red;
                 } else {
                   icon = isPdf ? Icons.picture_as_pdf : Icons.description;
                   iconColor = isDark ? Colors.white54 : Colors.grey[600]!;
                 }

                return GestureDetector(
                  onTap: () => onEvidenceTap(e),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(50)),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(15),
                    ),
                    child: isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 28,
                                color: iconColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAudio ? 'Audio' : ext, // Show extension for files/video
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
