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
            icon: Icons.photo_camera_rounded,
            label: l10n.takePhoto,
            color: Colors.blue,
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(width: 8),
          _AttachmentButton(
            icon: Icons.photo_library_rounded,
            label: l10n.gallery,
            color: Colors.teal,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 8),
          _AttachmentButton(
            icon: Icons.videocam_rounded,
            label: l10n.video,
            color: Colors.purple,
            onTap: _pickVideo,
          ),
          const SizedBox(width: 8),
          _AttachmentButton(
            icon: Icons.description_rounded,
            label: l10n.document,
            color: colorScheme.primary,
            onTap: _pickDocument,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGrid(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 50 : 30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: attachment.getColor(colorScheme).withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: attachment.getColor(colorScheme).withAlpha(100)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(attachment.icon, size: 28, color: attachment.getColor(colorScheme)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  attachment.name,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                attachment.sizeFormatted,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        // Remove button
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeAttachment(attachment),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 12, color: colorScheme.onError),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(50), style: BorderStyle.solid),
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
      color: color.withAlpha(25),
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
