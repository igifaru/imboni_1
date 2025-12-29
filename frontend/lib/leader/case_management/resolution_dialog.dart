import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/services/case_service.dart';

class ResolutionDialog extends StatefulWidget {
  final String caseId;

  const ResolutionDialog({super.key, required this.caseId});

  @override
  State<ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<ResolutionDialog> {
  final _notesController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) { // 5MB limit
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Dosiye igomba kuba munsi ya 5MB'), backgroundColor: ImboniColors.error),
           );
        }
        return;
      }
      setState(() => _selectedFile = file);
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
      String? attachmentId;
      // 1. Upload file if present
      if (_selectedFile != null && _selectedFile!.path != null) {
         final uploadResult = await CaseService.instance.uploadEvidence(widget.caseId, _selectedFile!.path!);
         if (!uploadResult.isSuccess || uploadResult.data == null) {
           throw Exception(uploadResult.error ?? 'Failed to upload evidence');
         }
         attachmentId = uploadResult.data;
      }

      // 2. Resolve case
      final result = await CaseService.instance.resolveCase(widget.caseId, _notesController.text, attachmentId: attachmentId);
      
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

                  if (_selectedFile == null)
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[50], // Light grey background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.none), // Using Dotted border would be nice but requires package. Using dashed effect via CustomPainter or just standard border for now. 
                        ),
                        child: CustomPaint(
                          painter: _DashedBorderPainter(color: Colors.grey[400]!),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                const Text("Kurura dosiye hano cyangwa ukande", style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text("Accepted formats: PDF, JPG, PNG. Max size: 5MB.", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedFile!.extension == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                            color: ImboniColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFile!.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                           Text(
                              _formatSize(_selectedFile!.size),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                           IconButton(
                             icon: const Icon(Icons.delete_outline, color: Colors.red),
                             onPressed: () => setState(() => _selectedFile = null),
                           ),
                        ],
                      ),
                    ),
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
