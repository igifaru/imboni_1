import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/community_models.dart';

class FileAttachmentWidget extends StatelessWidget {
  final CommunityAttachment attachment;
  final bool isOwnMessage;

  const FileAttachmentWidget({
    super.key,
    required this.attachment,
    this.isOwnMessage = false,
  });

  Future<void> _openFile() async {
    final path = attachment.path;
    if (path.isEmpty) return;

    try {
      final uri = Uri.tryParse(path);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          debugPrint('Could not launch $uri');
        }
      } else {
        // Local file
        // On mobile, OpenFile package is usually used. 
        // For simplified Flutter map/IO, we might need a specific viewer or just rely on platform capabilities if uri scheme is file://
        // But url_launcher supports file: schemes too sometimes or we just print for now if not web.
         if (!await launchUrl(Uri.file(path))) {
            debugPrint('Could not launch file $path');
         }
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  IconData _getIconForType() {
    final ext = attachment.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': 
      case 'docx': return Icons.description;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      case 'txt': return Icons.text_snippet;
      case 'zip': return Icons.folder_zip;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getColorForType(bool isDark) {
    if (isOwnMessage) return Colors.white;
    final ext = attachment.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Colors.red;
      case 'doc': 
      case 'docx': return Colors.blue;
      case 'xls':
      case 'xlsx': return Colors.green;
      case 'zip': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = isOwnMessage 
        ? colorScheme.onPrimary 
        : colorScheme.onSurface;

    final backgroundColor = isOwnMessage
        ? Colors.white.withOpacity(0.2)
        : colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return InkWell(
      onTap: _openFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOwnMessage 
                ? Colors.white.withOpacity(0.3) 
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOwnMessage ? Colors.white.withOpacity(0.2) : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForType(),
                color: _getColorForType(isDark),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatSize(attachment.size),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              color: textColor.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.bitLength - 1) ~/ 10; // log2(bytes) / 10 approx
    // Simplified manually for dart
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
