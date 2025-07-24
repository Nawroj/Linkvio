// pages/pdf_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Import for Syncfusion PDF Viewer

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerPage({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        // You can add actions here, like a share button if desired
      ),
      body: SfPdfViewer.network(pdfUrl), // Loads and displays the PDF from the provided URL
    );
  }
}