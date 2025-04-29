// lib/services/technical_visit_report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technical_visit_report.dart';

/// Service for managing technical visit reports in Firestore
///
/// This service handles all data operations related to technical visit reports,
/// following the repository pattern. It abstracts the data source (Firestore)
/// from the rest of the application, providing a clean API for CRUD operations.
class TechnicalVisitReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for technical visit reports
  CollectionReference get _reports =>
      _firestore.collection('technical_visit_reports');

  /// Stream of technical visit reports for real-time updates
  ///
  /// Provides a reactive stream of reports that can be filtered by status and technician.
  /// This method is used for real-time list views that update automatically.
  ///
  /// Parameters:
  /// - [statusFilter]: Optional filter to show only reports with this status
  /// - [technicianId]: Optional filter to show only reports by this technician
  ///
  /// Returns: A stream of report lists that updates in real-time
  Stream<List<TechnicalVisitReport>> getReportsStream({
    String? statusFilter,
    String? technicianId,
  }) {
    try {
      Query query = _reports;

      // Apply filters if provided, without complex sorting
      if (statusFilter != null && statusFilter.toLowerCase() != 'all') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      if (technicianId != null) {
        query = query.where('technicianId', isEqualTo: technicianId);
      }

      // Simple stream without complex indexing or sorting
      return query.snapshots().map((snapshot) {
        debugPrint(
          'Query returned ${snapshot.docs.length} technical visit reports',
        );
        return snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (!_validateDocumentData(data)) {
                debugPrint(
                  'Skipping invalid technical visit report document: ${doc.id}',
                );
                return null;
              }
              return TechnicalVisitReport.fromJson(data);
            })
            .where((report) => report != null)
            .cast<TechnicalVisitReport>()
            .toList();
      });
    } catch (e) {
      debugPrint('Error in getReportsStream: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }

  /// Get a single technical visit report by ID
  ///
  /// Fetches a specific report by its unique identifier.
  /// Used for viewing or editing an existing report.
  ///
  /// Parameters:
  /// - [reportId]: The unique identifier of the report to fetch
  ///
  /// Returns: The report if found, null otherwise
  Future<TechnicalVisitReport?> getReportById(String reportId) async {
    try {
      final doc = await _reports.doc(reportId).get();
      if (!doc.exists) {
        debugPrint('Technical visit report not found: $reportId');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (!_validateDocumentData(data)) {
        debugPrint('Invalid technical visit report document: $reportId');
        return null;
      }

      return TechnicalVisitReport.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching technical visit report: $e');
      return null;
    }
  }

  /// Create a new technical visit report
  ///
  /// Persists a new report to Firestore with a generated ID.
  /// Used when a technician creates a new draft report.
  ///
  /// Parameters:
  /// - [report]: The report object to create in the database
  Future<void> createReport(TechnicalVisitReport report) async {
    try {
      final reportData = report.toJson();
      await _reports.doc(report.id).set(reportData);
      debugPrint('Technical visit report created: ${report.id}');
    } catch (e) {
      debugPrint('Error creating technical visit report: $e');
      rethrow;
    }
  }

  /// Update an existing technical visit report
  ///
  /// Updates an existing report in Firestore.
  /// Used when a technician edits a draft report.
  ///
  /// Parameters:
  /// - [report]: The updated report object
  Future<void> updateReport(TechnicalVisitReport report) async {
    try {
      // Log the operation to help with debugging
      debugPrint('Updating report: ${report.id}, Status: ${report.status}');

      // Convert to JSON with timestamp handling
      final reportData = report.toJson();

      // Single Firestore operation
      await _reports.doc(report.id).update(reportData);

      debugPrint('Report update successful');
    } catch (e) {
      debugPrint('Error updating report: $e');

      // Important: Add detailed error logging for Firestore errors
      if (e.toString().contains('permission-denied')) {
        debugPrint(
          'PERMISSION DENIED: This usually indicates a security rules violation',
        );
        debugPrint('Current report status: ${report.status}');
      }

      rethrow;
    }
  }

  /// Submit a technical visit report
  ///
  /// Changes the status of a report to 'submitted' and records the submission time.
  /// Used when a technician finalizes a report.
  ///
  /// Parameters:
  /// - [reportId]: The ID of the report to submit
  // lib/services/technical_visit_report_service.dart - update the submitReport method

  Future<void> submitReport(String reportId) async {
    try {
      // First, check if the document exists
      final docSnapshot = await _reports.doc(reportId).get();

      if (!docSnapshot.exists) {
        debugPrint('Report document does not exist: $reportId');
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Report document does not exist. Create a draft first.',
        );
      }

      // If document exists, update it
      await _reports.doc(reportId).update({
        'status': 'submitted',
        'submittedAt': DateTime.now().toIso8601String(),
        'lastModified': DateTime.now().toIso8601String(),
      });

      debugPrint('Technical visit report submitted: $reportId');
    } catch (e) {
      debugPrint('Error submitting technical visit report: $e');
      rethrow;
    }
  }

  /// Update report status
  ///
  /// Updates the status of a report (for admin review/approval).
  /// Used when an admin reviews or approves a submitted report.
  ///
  /// Parameters:
  /// - [reportId]: The ID of the report to update
  /// - [newStatus]: The new status to set
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _reports.doc(reportId).update({
        'status': newStatus.toLowerCase(),
        'lastModified': DateTime.now().toIso8601String(),
      });
      debugPrint(
        'Technical visit report status updated to $newStatus: $reportId',
      );
    } catch (e) {
      debugPrint('Error updating technical visit report status: $e');
      rethrow;
    }
  }

  /// Update PDF generation status
  ///
  /// Updates the PDF generation status of a report.
  /// Used to track whether a PDF has been successfully generated.
  ///
  /// Parameters:
  /// - [reportId]: The ID of the report
  /// - [generated]: Whether the PDF was successfully generated
  Future<void> updatePdfStatus(String reportId, bool generated) async {
    try {
      await _reports.doc(reportId).update({
        'pdfGenerated': generated,
        'pdfGeneratedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('PDF generation status updated for report: $reportId');
    } catch (e) {
      debugPrint('Error updating PDF generation status: $e');
      rethrow;
    }
  }

  /// Record PDF metadata
  ///
  /// Records metadata about a generated PDF without storing the actual PDF content.
  /// Used to track PDF generation without exceeding Firestore document size limits.
  ///
  /// Parameters:
  /// - [reportId]: The ID of the report
  /// - [fileSize]: The size of the PDF file in bytes
  Future<void> recordPdfMetadata(String reportId, int fileSize) async {
    try {
      debugPrint('Recording PDF metadata for report: $reportId');
      await _reports.doc(reportId).update({
        'pdfGenerated': true,
        'pdfGeneratedAt': DateTime.now().toIso8601String(),
        'pdfSizeBytes': fileSize,
      });
      debugPrint('PDF metadata recorded successfully');
    } catch (e) {
      debugPrint('Error recording PDF metadata: $e');
      // Don't rethrow this error - PDF metadata is non-critical
    }
  }

  /// Delete a technical visit report
  ///
  /// Permanently removes a report from Firestore.
  /// Used when a technician deletes a draft report.
  ///
  /// Parameters:
  /// - [reportId]: The ID of the report to delete
  Future<void> deleteReport(String reportId) async {
    try {
      await _reports.doc(reportId).delete();
      debugPrint('Technical visit report deleted: $reportId');
    } catch (e) {
      debugPrint('Error deleting technical visit report: $e');
      rethrow;
    }
  }

  /// Validate document data
  ///
  /// Checks if a Firestore document has all required fields for a report.
  /// Used internally to prevent errors when processing reports.
  ///
  /// Parameters:
  /// - [data]: The document data to validate
  ///
  /// Returns: true if the document is valid, false otherwise
  bool _validateDocumentData(Map<String, dynamic> data) {
    final requiredFields = [
      'id',
      'technicianId',
      'technicianName',
      'date',
      'status',
      'createdAt',
    ];

    return requiredFields.every((field) => data.containsKey(field));
  }

  /// Get draft reports for a technician
  ///
  /// Provides a stream of draft reports for a specific technician.
  /// Used to display the technician's draft reports.
  ///
  /// Parameters:
  /// - [technicianId]: The ID of the technician
  ///
  /// Returns: A stream of draft reports that updates in real-time
  Stream<List<TechnicalVisitReport>> getDraftReportsStream(
    String technicianId,
  ) {
    return getReportsStream(statusFilter: 'draft', technicianId: technicianId);
  }

  /// Get submitted reports for a technician
  ///
  /// Provides a stream of submitted, reviewed, or approved reports for a specific technician.
  /// Used to display the technician's submitted reports.
  ///
  /// Parameters:
  /// - [technicianId]: The ID of the technician
  ///
  /// Returns: A stream of submitted reports that updates in real-time
  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream(
    String technicianId,
  ) {
    try {
      final query = _reports
          .where('technicianId', isEqualTo: technicianId)
          .where('status', whereIn: ['submitted', 'reviewed', 'approved'])
          .orderBy('submittedAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (!_validateDocumentData(data)) {
                debugPrint(
                  'Skipping invalid technical visit report document: ${doc.id}',
                );
                return null;
              }
              return TechnicalVisitReport.fromJson(data);
            })
            .where((report) => report != null)
            .cast<TechnicalVisitReport>()
            .toList();
      });
    } catch (e) {
      debugPrint('Error in getSubmittedReportsStream: $e');
      return Stream.value([]);
    }
  }
}
