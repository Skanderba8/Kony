// lib/view_models/admin_view_model.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/technical_visit_report_service.dart';
import '../services/pdf_generation_service.dart';
import '../models/technical_visit_report.dart';

/// View model for the admin functionality, specifically for managing technical visit reports.
///
/// This follows the MVVM pattern where the view model acts as an intermediary between
/// the data services and the UI. It exposes streams and methods needed by the admin views
/// to display and interact with the technical visit reports.
class AdminViewModel extends ChangeNotifier {
  final TechnicalVisitReportService _reportService;
  final AuthService _authService;
  final PdfGenerationService _pdfService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters for state
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Constructor with dependency injection
  AdminViewModel({
    required TechnicalVisitReportService reportService,
    required AuthService authService,
    required PdfGenerationService pdfService,
  }) : _reportService = reportService,
       _authService = authService,
       _pdfService = pdfService;

  /// Get a stream of all submitted technical visit reports
  ///
  /// This provides real-time updates whenever reports change in the database
  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream() {
    // Use a simpler query that doesn't require complex indexing
    return _reportService.getReportsStream(statusFilter: 'submitted');
  }

  /// Get a stream of all reviewed technical visit reports
  Stream<List<TechnicalVisitReport>> getReviewedReportsStream() {
    return _reportService.getReportsStream(statusFilter: 'reviewed');
  }

  /// Get a stream of all approved technical visit reports
  Stream<List<TechnicalVisitReport>> getApprovedReportsStream() {
    return _reportService.getReportsStream(statusFilter: 'approved');
  }

  /// Get a stream of all technical visit reports, regardless of status
  Stream<List<TechnicalVisitReport>> getAllReportsStream() {
    return _reportService.getReportsStream();
  }

  /// Update the status of a technical visit report
  ///
  /// This method marks a report as reviewed or approved
  Future<bool> updateReportStatus(String reportId, String newStatus) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _reportService.updateReportStatus(reportId, newStatus);
      _setSuccessMessage('Report status updated to $newStatus successfully');
      return true;
    } catch (e) {
      _setErrorMessage('Failed to update report status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a technical visit report
  ///
  /// This method permanently removes a report from the database
  Future<bool> deleteReport(String reportId) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _reportService.deleteReport(reportId);
      _setSuccessMessage('Report deleted successfully');
      return true;
    } catch (e) {
      _setErrorMessage('Failed to delete report: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific technical visit report by its ID
  Future<TechnicalVisitReport?> getReportById(String reportId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final report = await _reportService.getReportById(reportId);
      return report;
    } catch (e) {
      _setErrorMessage('Failed to load report: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate a PDF for a specific technical visit report
  ///
  /// Returns the file if successful, null if failed
  Future<File?> generateReportPdf(String reportId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final report = await _reportService.getReportById(reportId);
      if (report == null) {
        _setErrorMessage('Report not found');
        return null;
      }

      final pdfFile = await _pdfService.generateTechnicalReportPdf(report);

      // Record metadata about PDF generation in Firestore
      await _reportService.recordPdfMetadata(reportId, await pdfFile.length());

      _setSuccessMessage('PDF generated successfully');
      return pdfFile;
    } catch (e) {
      _setErrorMessage('Failed to generate PDF: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    _setLoading(true);
    _clearMessages();

    try {
      await _authService.signOut();
    } catch (e) {
      _setErrorMessage('Failed to log out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods for state management
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
