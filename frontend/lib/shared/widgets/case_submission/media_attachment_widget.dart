import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../localization/app_localizations.dart';

/// Attachment model for case evidence
class CaseAttachment {
  final String id;
  final String path;
  final String name;
  final AttachmentType type;
  final int size;
  final Uint8List? bytes; // For web

  const CaseAttachment({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    required this.size,
    this.bytes,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get icon => switch (type) {
    AttachmentType.image => Icons.image_outlined,
    AttachmentType.video => Icons.videocam_outlined,
    AttachmentType.audio => Icons.mic_outlined,
    AttachmentType.document => Icons.description_outlined,
  };

  Color getColor(ColorScheme colorScheme) => switch (type) {
    AttachmentType.image => Colors.blue,
    AttachmentType.video => Colors.purple,
    AttachmentType.audio => Colors.orange,
    AttachmentType.document => colorScheme.primary,
  };
}

enum AttachmentType { image, video, audio, document }

/// Premium Media Attachment Widget for case evidence
class MediaAttachmentWidget extends StatefulWidget {
  final List<CaseAttachment> attachments;
  final ValueChanged<List<CaseAttachment>> onChanged;
  final int maxAttachments;
  final int maxFileSizeMB;

  const MediaAttachmentWidget({
    super.key,
    required this.attachments,
    required this.onChanged,
    this.maxAttachments = 10,
    this.maxFileSizeMB = 25,
  });

  @override
  State<MediaAttachmentWidget> createState() => _MediaAttachmentWidgetState();
}

class _MediaAttachmentWidgetState extends State<MediaAttachmentWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Row(
          children: [
            Icon(Icons.attach_file_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.attachEvidence,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.attachments.length}/${widget.maxAttachments}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Attachment type buttons
        _buildAttachmentButtons(theme, colorScheme, l10n),
        const SizedBox(height: 16),

        // Attachments grid
        if (widget.attachments.isNotEmpty) ...[
          _buildAttachmentsGrid(theme, colorScheme, isDark),
        ] else
          _buildEmptyState(theme, colorScheme),

        // Info text
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${l10n.maxFileSize}: ${widget.maxFileSizeMB}MB',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentButtons(ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AttachmentButton(
            icon: Icons.camera_alt,
            label: l10n.takePhoto,
            color: const Color(0xFF2196F3), // Blue
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 8),
          _AttachmentButton(
            icon: Icons.photo_library,
            label: l10n.gallery,
            color: const Color(0xFF009688), // Teal
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 8),
          _AttachmentButton(
            icon: Icons.videocam,
            label: l10n.video,
            color: const Color(0xFF9C27B0), // Purple
            onTap: _pickVideo,
          ),
          const SizedBox(width: 8),
          _AttachmentButton(
            icon: Icons.description,
            label: l10n.document,
            color: const Color(0xFF4CAF50), // Green for doc
            onTap: _pickDocument,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGrid(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150, // Responsive: fits columns based on width
          childAspectRatio: 0.8,   // Taller than wide for preview + info
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: widget.attachments.length,
        itemBuilder: (context, index) {
          final attachment = widget.attachments[index];
          return _buildAttachmentTile(attachment, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildAttachmentTile(CaseAttachment attachment, ThemeData theme, ColorScheme colorScheme) {
    final isImage = attachment.type == AttachmentType.image;
    
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (isImage) {
              _showImagePreview(context, attachment);
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview Area
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: attachment.getColor(colorScheme).withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: isImage
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Hero(
                                tag: 'image_${attachment.id}',
                                child: _buildImagePreview(attachment),
                              ),
                            )
                          : Icon(attachment.icon, size: 32, color: attachment.getColor(colorScheme)),
                    ),
                  ),
                ),
                
                // Info Area
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            attachment.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 11, // Slightly smaller font
                            ),
                            maxLines: 1, // Limit lines strictly
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          attachment.sizeFormatted,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _removeAttachment(attachment),
            child: Container(
              padding: const EdgeInsets.all(6), // Larger touch target
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2), // White border for separation
                  boxShadow: [
                     BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                  ],
                ),
                child: Icon(Icons.close, size: 12, color: colorScheme.onError),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImagePreview(BuildContext context, CaseAttachment attachment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Backdrop
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black87),
            ),
            // Image
            InteractiveViewer(
               panEnabled: true,
               minScale: 0.5,
               maxScale: 4,
               child: Hero(
                 tag: 'image_${attachment.id}',
                 child: _buildImagePreview(attachment),
               ),
            ),
            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
            // Name label
             Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Text(
                attachment.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(CaseAttachment attachment) {
    if (kIsWeb && attachment.bytes != null) {
      return Image.memory(attachment.bytes!, fit: BoxFit.cover, width: double.infinity);
    } else if (!kIsWeb && attachment.path.isNotEmpty) {
      return Image.file(
        File(attachment.path), 
        fit: BoxFit.cover, 
        width: double.infinity,
        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image_rounded, size: 30, color: Colors.grey),
      );
    }
    return const Icon(Icons.image, size: 32);
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).noAttachments,
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (widget.attachments.length >= widget.maxAttachments) {
      _showLimitError();
      return;
    }

    // On Desktop/Linux, ImageSource.camera is often not supported directly by image_picker.
    // Use native ffmpeg capture
    if (!kIsWeb && Platform.isLinux && source == ImageSource.camera) {
       await _captureLinuxPhoto();
       return;
    }

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS)) {
      if (source == ImageSource.camera) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cameraNotSupported)),
        );
        return;
      }
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (_validateSize(bytes.length)) {
          _addAttachment(CaseAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: image.path,
            name: image.name,
            type: AttachmentType.image,
            size: bytes.length,
            bytes: kIsWeb ? bytes : null,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _captureLinuxPhoto() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dir = Directory.systemTemp.createTempSync();
      final path = '${dir.path}/photo_$timestamp.jpg';
      
      // Use ffmpeg to capture a single frame from the default video device
      // -f video4linux2: format
      // -i /dev/video0: input device (usually default webcam)
      // -vframes 1: capture 1 frame
      // -y: overwrite
      final result = await Process.run('ffmpeg', [
        '-f', 'video4linux2',
        '-s', '1280x720', // Try HD resolution
        '-i', '/dev/video0', 
        '-vframes', '1', 
        '-y', 
        path
      ]);

      if (result.exitCode == 0) {
        final file = File(path);
        if (await file.exists()) {
           final bytes = await file.readAsBytes();
           if (_validateSize(bytes.length)) {
            _addAttachment(CaseAttachment(
              id: timestamp.toString(),
              path: path,
              name: 'photo_$timestamp.jpg',
              type: AttachmentType.image,
              size: bytes.length,
            ));
           }
        } else {
           throw Exception('Photo file not created');
        }
      } else {
        throw Exception('ffmpeg failed: ${result.stderr}');
      }
    } catch (e) {
      debugPrint('Error capturing linux photo: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not capture photo. Ensure webcam is available.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    if (widget.attachments.length >= widget.maxAttachments) {
      _showLimitError();
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        final bytes = await video.readAsBytes();
        if (_validateSize(bytes.length)) {
          _addAttachment(CaseAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: video.path,
            name: video.name,
            type: AttachmentType.video,
            size: bytes.length,
            bytes: kIsWeb ? bytes : null,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _pickDocument() async {
    if (widget.attachments.length >= widget.maxAttachments) {
      _showLimitError();
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (_validateSize(file.size)) {
          _addAttachment(CaseAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: file.path ?? '',
            name: file.name,
            type: AttachmentType.document,
            size: file.size,
            bytes: file.bytes,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  bool _validateSize(int sizeBytes) {
    final maxBytes = widget.maxFileSizeMB * 1024 * 1024;
    if (sizeBytes > maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).fileTooLarge} (${widget.maxFileSizeMB}MB max)'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }
    return true;
  }

  void _addAttachment(CaseAttachment attachment) {
    widget.onChanged([...widget.attachments, attachment]);
  }

  void _removeAttachment(CaseAttachment attachment) {
    widget.onChanged(widget.attachments.where((a) => a.id != attachment.id).toList());
  }

  void _showLimitError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context).maxAttachmentsReached} (${widget.maxAttachments})'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Attachment action button
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
