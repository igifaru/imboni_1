import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatelessWidget {
  final String? url;
  final String? filePath;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    this.url,
    this.filePath,
    required this.fileName,
  }) : assert(url != null || filePath != null, 'Either url or filePath must be provided');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: _buildPdfViewer(context),
    );
  }

  Widget _buildPdfViewer(BuildContext context) {
    if (filePath != null) {
      // Local file
      return SfPdfViewer.file(
        File(filePath!),
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ntibibashije gufungura PDF: ${details.error}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } else {
      // Network URL
      return SfPdfViewer.network(
        url!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load PDF: ${details.error}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }
}
