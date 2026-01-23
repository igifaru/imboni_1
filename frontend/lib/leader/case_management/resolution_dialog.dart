import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/services/case_service.dart';
import 'package:imboni/shared/widgets/pdf_viewer_screen.dart';

class ResolutionDialog extends StatefulWidget {
  final String caseId;

  const ResolutionDialog({super.key, required this.caseId});

  @override
  State<ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<ResolutionDialog> {
  final _notesController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;

  // Allowed extensions
  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif', 'webp'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final validFiles = <PlatformFile>[];
      for (final file in result.files) {
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${file.name} irenze 5MB, ntiyakiriwe'), backgroundColor: ImboniColors.error),
            );
          }
          continue;
        }
        validFiles.add(file);
      }
      setState(() => _selectedFiles = [..._selectedFiles, ...validFiles]);
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  /// Preview local file before upload
  Future<void> _previewFile(PlatformFile file) async {
    final ext = (file.extension ?? '').toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    final isPdf = ext == 'pdf';
    final isDoc = ['doc', 'docx'].contains(ext);
    
    if (isImage && file.path != null) {
      // Show local image in dialog
      showDialog(
        context: context,
        builder: (_) => _LocalImagePreviewDialog(filePath: file.path!, fileName: file.name),
      );
    } else if (isPdf && file.path != null) {
      // Use internal PDF viewer for PDFs
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewerScreen(filePath: file.path!, fileName: file.name),
        ),
      );
    } else if (isDoc && file.path != null) {
      // Open DOC/DOCX with system default application
      final uri = Uri.file(file.path!);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nta porogaramu ibasha gufungura iyi nyandiko'), backgroundColor: ImboniColors.warning),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ntibibashije gufungura: $e'), backgroundColor: ImboniColors.error),
          );
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ugomba gutanga ibisobanuro!'), backgroundColor: ImboniColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> uploadedEvidenceIds = [];
      
      // 1. Upload all files
      for (final file in _selectedFiles) {
        if (file.path != null) {
          final uploadResult = await CaseService.instance.uploadEvidence(
            widget.caseId, 
            file.path!, 
            purpose: 'RESOLUTION',
            description: file.name,
          );
          if (uploadResult.isSuccess && uploadResult.data != null) {
            uploadedEvidenceIds.add(uploadResult.data!);
          } else {
            debugPrint('Failed to upload ${file.name}: ${uploadResult.error}');
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Failed to upload ${file.name}: ${uploadResult.error}')),
               );
            }
          }
        }
      }

      // 2. Resolve case (pass first evidence ID for backward compatibility, or null)
      final primaryEvidenceId = uploadedEvidenceIds.isNotEmpty ? uploadedEvidenceIds.first : null;
      final result = await CaseService.instance.resolveCase(widget.caseId, _notesController.text, primaryEvidenceId);
      
      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(context, result.data); // Return updated case
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Unknown error'), backgroundColor: ImboniColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habaye ikosa: $e'), backgroundColor: ImboniColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600, // Explicit wider width as requested
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kemura Ikibazo',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Input
                  const Text("Ibisobanuro by'Uko Cyakemutse", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: "Andika uburyo ikibazo cyakemutse n'ingamba zafashwe...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ImboniColors.primary, width: 1.5), // Green border as in image
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // File Upload
                  RichText(
                    text: TextSpan(
                      text: "Inyandiko Zishyigikira ",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                      children: [
                        TextSpan(text: "(Optional)", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // File Upload Area
                  InkWell(
                    onTap: _pickFiles,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(color: Colors.grey[400]!),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 28, color: Colors.grey[600]),
                              const SizedBox(height: 6),
                              const Text("Kanda hano uhitemo dosiye", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text("PDF, DOC, DOCX, JPG, PNG (Max: 5MB)", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Selected Files List
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _selectedFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          final ext = (file.extension ?? '').toLowerCase();
                          final canPreview = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'].contains(ext);
                          
                          return InkWell(
                            onTap: () => _previewFile(file),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getFileIcon(file.extension ?? ''),
                                    color: ImboniColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (canPreview)
                                          Text(
                                            'Kanda urebe',
                                            style: TextStyle(fontSize: 10, color: ImboniColors.primary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatSize(file.size),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _removeFile(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reka'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 20), // Taller buttons
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                        backgroundColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                      label: Text(_isLoading ? 'Birakorwa...' : 'Emeza'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00A65A), // Specific Green from image
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    final path = Path()..addRRect(rrect);

    Path dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Local image preview dialog for files not yet uploaded
class _LocalImagePreviewDialog extends StatelessWidget {
  final String filePath;
  final String fileName;

  const _LocalImagePreviewDialog({required this.filePath, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Image
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(filePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Ntibibashije kwereka ifoto', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
