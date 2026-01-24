import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/community_models.dart';

class AttachmentPreviewList extends StatelessWidget {
  final List<CommunityAttachment> attachments;
  final Function(CommunityAttachment) onRemove;

  const AttachmentPreviewList({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120, // Increased height to prevent overflow and improve touch targets
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildPreviewItem(context, attachment),
              Positioned(
                top: -8,
                right: -8,
                child: Material(
                  color: Colors.transparent,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: GestureDetector(
                    onTap: () => onRemove(attachment),
                    child: Container(
                      padding: const EdgeInsets.all(6), // Larger touch target
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewItem(BuildContext context, CommunityAttachment attachment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color accentColor;
    IconData icon;
    String typeLabel;
    String detailText;

    switch (attachment.type) {
      case AttachmentType.image:
        return _buildMediaPreview(attachment, isVideo: false, theme: theme);
      case AttachmentType.video:
        return _buildMediaPreview(attachment, isVideo: true, theme: theme);
      case AttachmentType.document:
        accentColor = Colors.orange;
        icon = Icons.description;
        typeLabel = 'Document';
        detailText = attachment.name;
        break;
      case AttachmentType.poll:
        accentColor = Colors.green;
        icon = Icons.bar_chart_rounded;
        typeLabel = 'Poll';
        detailText = (attachment.metadata?['question'] as String?) ?? 'New Poll';
        break;
      case AttachmentType.collaborativeList:
        accentColor = Colors.indigo;
        icon = Icons.checklist_rounded;
        typeLabel = 'List';
        detailText = (attachment.metadata?['title'] as String?) ?? 'New List';
        break;
    }

    return Container(
      width: 140, // Wider card for better text fit
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Band
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: accentColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Content Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Text(
                  detailText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(CommunityAttachment attachment, {required bool isVideo, required ThemeData theme}) {
     return Container(
      width: 100, // Media stays square-ish
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
         image: (kIsWeb && attachment.bytes != null) || (!kIsWeb && attachment.path.isNotEmpty)
            ? DecorationImage(
                image: (kIsWeb 
                    ? MemoryImage(attachment.bytes!) 
                    : FileImage(File(attachment.path))) as ImageProvider,
                fit: BoxFit.cover,
                onError: (_, __) {}, // Handle error silently or show placeholder
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
           if (isVideo)
             Container(
               color: Colors.black26, 
               child: const Center(
                 child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
               ),
             ),
           // Fallback if no image loaded
           if (!kIsWeb && attachment.path.isEmpty && attachment.bytes == null)
             const Center(child: Icon(Icons.image, color: Colors.grey)),
        ],
      ),
    );
  }
}
