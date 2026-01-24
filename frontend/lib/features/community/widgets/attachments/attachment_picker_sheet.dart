import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/community_models.dart';

class AttachmentPickerSheet extends StatelessWidget {
  final Function(CommunityAttachment) onAttachmentSelected;
  final VoidCallback onPollRequested;
  final VoidCallback onListRequested;

  const AttachmentPickerSheet({
    super.key,
    required this.onAttachmentSelected,
    required this.onPollRequested,
    required this.onListRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildOption(
                context,
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              _buildOption(
                context,
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.purple,
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              _buildOption(
                context,
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.orange,
                onTap: () => _pickVideo(context),
              ),
              _buildOption(
                context,
                icon: Icons.description,
                label: 'Document',
                color: Colors.teal,
                onTap: () => _pickDocument(context),
              ),
              _buildOption(
                context,
                icon: Icons.poll,
                label: 'Poll',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  onPollRequested();
                },
              ),
              _buildOption(
                context,
                icon: Icons.table_chart,
                label: 'List',
                color: Colors.indigo,
                onTap: () {
                  Navigator.pop(context);
                  onListRequested();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    // Linux workaround or check
    if (!kIsWeb && Platform.isLinux && source == ImageSource.camera) {
       // Using simple file picker for now on linux if camera not supported directly, or skip as per MediaAttachmentWidget
       // For this implementation, we'll try the standard picker
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final attachment = CommunityAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AttachmentType.image,
          path: image.path,
          name: image.name,
          size: bytes.length,
          bytes: bytes,
        );
        if (context.mounted) {
          Navigator.pop(context);
          onAttachmentSelected(attachment);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        final bytes = await video.readAsBytes();
        final attachment = CommunityAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AttachmentType.video,
          path: video.path,
          name: video.name,
          size: bytes.length,
          bytes: bytes,
        );
        if (context.mounted) {
          Navigator.pop(context);
          onAttachmentSelected(attachment);
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final attachment = CommunityAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AttachmentType.document,
          path: file.path ?? '',
          name: file.name,
          size: file.size,
          bytes: file.bytes,
        );
        if (context.mounted) {
          Navigator.pop(context);
          onAttachmentSelected(attachment);
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }
}
