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

  Stream<List<TechnicalVisitReport>> getSubmittedReportsStreamForAdmin() {
    return _reportService.getSubmittedReportsStreamForAdmin();
  }

  // Update existing methods to use the new service structure
  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream() {
    return _reportService.getSubmittedReportsStreamForAdmin().map(
      (reports) => reports.where((r) => r.status == 'submitted').toList(),
    );
  }

  Stream<List<TechnicalVisitReport>> getReviewedReportsStream() {
    return _reportService.getReviewedReportsStream();
  }

  Stream<List<TechnicalVisitReport>> getApprovedReportsStream() {
    return _reportService.getApprovedReportsStream();
  }

  // ADD: Get rejected reports stream
  Stream<List<TechnicalVisitReport>> getRejectedReportsStream() {
    return _reportService.getRejectedReportsStream();
  }

  Stream<List<TechnicalVisitReport>> getAllReportsStream() {
    return _reportService.getAllReportsStream();
  }

  /// Update the status of a technical visit report
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

  Future<bool> rejectReport(String reportId, String comment) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _reportService.rejectReport(reportId, comment);
      _setSuccessMessage('Report rejected successfully');
      return true;
    } catch (e) {
      _setErrorMessage('Failed to reject report: $e');
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
