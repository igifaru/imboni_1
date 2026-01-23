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

    final allEvidence = caseModel.evidence ?? [];
    
    // Separate evidence by purpose
    final citizenEvidence = allEvidence.where((e) => e.purpose == null || e.purpose == 'SUBMISSION').toList();
    final leaderEvidence = allEvidence.where((e) => e.purpose == 'RESOLUTION').toList();
    
    // Fallback for cases where resolution might still have evidence attached directly (backward compatibility)
    if (caseModel.resolution?.evidence != null) {
      final resEvidence = caseModel.resolution!.evidence!;
      if (!leaderEvidence.any((e) => e.id == resEvidence.id)) {
        leaderEvidence.add(resEvidence);
      }
    }

    final hasCitizenEvidence = citizenEvidence.isNotEmpty;
    final hasLeaderEvidence = leaderEvidence.isNotEmpty;

    return CaseDetailCard(
      title: l10n.evidence,
      icon: Icons.attach_file,
      backgroundColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DEBUG: Remove in production
          /*
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'DEBUG: Total: ${allEvidence.length} | Citizen: ${citizenEvidence.length} (First: ${citizenEvidence.isNotEmpty ? citizenEvidence.first.purpose : "N/A"}) | Leader: ${leaderEvidence.length}',
              style: const TextStyle(fontSize: 10, color: Colors.blue),
            ),
          ),
          */
          
          // Citizen Evidence Section
          _buildSectionHeader(
            context, 
            "Ibimenyetso by'Umuturage", 
            Icons.person_outline,
            isDark,
          ),
          const SizedBox(height: 8),
          if (!hasCitizenEvidence)
            _buildNoEvidence(context, l10n.noEvidenceProvided, isDark)
          else
            _buildEvidenceGrid(context, citizenEvidence, isDark),

          // Leader Resolution Evidence Section (only if leader has uploaded evidence or resolution exists)
          if (hasLeaderEvidence || caseModel.resolution != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildSectionHeader(
              context, 
              "Ibimenyetso by'Umuyobozi", 
              Icons.admin_panel_settings_outlined,
              isDark,
            ),
            const SizedBox(height: 8),
            
            // Show resolution notes if they exist
            if (caseModel.resolution?.notes != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(5) : Colors.grey.withAlpha(5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(30)),
                ),
                clipBehavior: Clip.hardEdge,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 3,
                        color: ImboniColors.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            caseModel.resolution!.notes,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (hasLeaderEvidence)
              _buildEvidenceGrid(context, leaderEvidence, isDark)
            else if (caseModel.resolution?.notes == null)
               _buildNoEvidence(context, "Nta bimenyetso by'umuyobozi byatanzwe", isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ImboniColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildNoEvidence(BuildContext context, String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 36,
              color: isDark ? Colors.white24 : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceGrid(BuildContext context, List<EvidenceModel> evidence, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: evidence.map((e) {
        final ext = e.fileName.contains('.') ? e.fileName.split('.').last.toLowerCase() : '';
        
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext) || e.mimeType.startsWith('image/');
        final isAudio = ['mp3', 'wav', 'aac', 'm4a', 'flac'].contains(ext) || e.mimeType.startsWith('audio/');
        final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext) || e.mimeType.startsWith('video/');
        final isPdf = ext == 'pdf' || e.mimeType == 'application/pdf';
        final isWord = ['doc', 'docx'].contains(ext) || e.mimeType.contains('word');
        
        final url = '${ApiClient.storageUrl}${e.url}';
        
        // Display Label
        String displayLabel = ext.toUpperCase();
        if (displayLabel.isEmpty) displayLabel = 'FILE';
        if (displayLabel.length > 4) displayLabel = displayLabel.substring(0, 4);

        // Map icon and color
        IconData icon;
        Color iconColor;
        
        if (isImage) {
          icon = Icons.image;
          iconColor = ImboniColors.primary;
        } else if (isAudio) {
          icon = Icons.audiotrack;
          iconColor = ImboniColors.secondary; // Distinct color for audio
        } else if (isVideo) {
          icon = Icons.play_circle_fill_rounded;
          iconColor = Colors.redAccent;
        } else if (isPdf) {
          icon = Icons.picture_as_pdf;
          iconColor = Colors.red[700]!;
        } else if (isWord) {
          icon = Icons.description;
          iconColor = Colors.blue[700]!;
        } else {
          icon = Icons.insert_drive_file;
          iconColor = isDark ? Colors.white54 : Colors.grey[600]!;
        }

        return GestureDetector(
          onTap: () => onEvidenceTap(e),
          child: SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(50)),
                    borderRadius: BorderRadius.circular(10),
                    color: isDark ? Colors.white.withAlpha(12) : Colors.grey.withAlpha(15),
                  ),
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
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
                              size: 24,
                              color: iconColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayLabel,
                              style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
                if (e.description != null && e.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
