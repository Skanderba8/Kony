// lib/views/screens/pdf_viewer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // You'll need to add this package
import 'package:share_plus/share_plus.dart'; // You'll need to add this package
import '../../utils/notification_utils.dart';

/// A screen to view PDF documents generated from technical visit reports.
///
/// This screen uses the flutter_pdfview package to render PDFs directly in the
/// application, providing a native reading experience with page navigation and
/// zoom capabilities.
class PdfViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String reportName;

  const PdfViewerScreen({
    super.key,
    required this.pdfFile,
    required this.reportName,
  });

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PDFViewController _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reportName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Partager le PDF',
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF View
          _hasError
              ? _buildErrorView()
              : PDFView(
                filePath: widget.pdfFile.path,
                onViewCreated: (PDFViewController controller) {
                  _pdfViewController = controller;
                },
                onPageChanged: (int? page, int? total) {
                  if (page != null && total != null) {
                    setState(() {
                      _currentPage = page;
                      _totalPages = total;
                      _isLoading = false;
                    });
                  }
                },
                onError: (error) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = error.toString();
                    _isLoading = false;
                  });
                },
                onRender: (_) {
                  setState(() {
                    _isLoading = false;
                  });
                },
              ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Page navigation controls
          if (!_isLoading && !_hasError && _totalPages > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildPageControls(),
            ),
        ],
      ),
    );
  }

  // Build the error view when PDF loading fails
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Échec du chargement du PDF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  // Build the page navigation controls
  Widget _buildPageControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed:
                _currentPage > 0
                    ? () {
                      _pdfViewController.setPage(_currentPage - 1);
                    }
                    : null,
            color:
                _currentPage > 0 ? Colors.white : Colors.white.withOpacity(0.5),
          ),

          // Page counter
          Text(
            'Page ${_currentPage + 1} sur $_totalPages',
            style: const TextStyle(color: Colors.white),
          ),

          // Next page button
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed:
                _currentPage < _totalPages - 1
                    ? () {
                      _pdfViewController.setPage(_currentPage + 1);
                    }
                    : null,
            color:
                _currentPage < _totalPages - 1
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  // Share the PDF with other apps
  void _sharePdf() async {
    try {
      await Share.shareFiles([
        widget.pdfFile.path,
      ], text: 'Rapport de Visite Technique: ${widget.reportName}');
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, 'Échec du partage du PDF: $e');
      }
    }
  }
}
