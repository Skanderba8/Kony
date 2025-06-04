// lib/services/technical_visit_report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technical_visit_report.dart';

class TechnicalVisitReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Two separate collections for the new workflow
  CollectionReference get _submittedReports =>
      _firestore.collection('technical_visit_reports');

  CollectionReference get _drafts => _firestore.collection('drafts');

  // Get all reports for admin (only submitted, reviewed, approved)
  Stream<List<TechnicalVisitReport>> getSubmittedReportsStreamForAdmin() {
    try {
      return _submittedReports.snapshots().map((snapshot) {
        final reports =
            snapshot.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (!_validateDocumentData(data)) {
                    return null;
                  }
                  return TechnicalVisitReport.fromJson(data);
                })
                .where((report) => report != null)
                .cast<TechnicalVisitReport>()
                .toList();

        // Sort by submission date
        reports.sort(
          (a, b) => (b.submittedAt ?? b.createdAt).compareTo(
            a.submittedAt ?? a.createdAt,
          ),
        );

        return reports;
      });
    } catch (e) {
      debugPrint('Error getting submitted reports for admin: $e');
      return Stream.value([]);
    }
  }

  // Get draft reports for technician (from drafts collection)
  Stream<List<TechnicalVisitReport>> getDraftReportsStream(
    String technicianId,
  ) {
    try {
      return _drafts
          .where('technicianId', isEqualTo: technicianId)
          .snapshots()
          .map((snapshot) {
            final reports =
                snapshot.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!_validateDocumentData(data)) {
                        return null;
                      }
                      return TechnicalVisitReport.fromJson(data);
                    })
                    .where((report) => report != null)
                    .cast<TechnicalVisitReport>()
                    .toList();

            // Sort by last modified date
            reports.sort(
              (a, b) => (b.lastModified ?? b.createdAt).compareTo(
                a.lastModified ?? a.createdAt,
              ),
            );

            return reports;
          });
    } catch (e) {
      debugPrint('Error getting draft reports: $e');
      return Stream.value([]);
    }
  }

  // Get submitted reports for technician (from main collection)
  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream(
    String technicianId,
  ) {
    try {
      return _submittedReports
          .where('technicianId', isEqualTo: technicianId)
          .snapshots()
          .map((snapshot) {
            final reports =
                snapshot.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (!_validateDocumentData(data)) {
                        return null;
                      }
                      return TechnicalVisitReport.fromJson(data);
                    })
                    .where((report) => report != null)
                    .cast<TechnicalVisitReport>()
                    .toList();

            // Sort by submission date
            reports.sort(
              (a, b) => (b.submittedAt ?? b.createdAt).compareTo(
                a.submittedAt ?? a.createdAt,
              ),
            );

            return reports;
          });
    } catch (e) {
      debugPrint('Error getting submitted reports for technician: $e');
      return Stream.value([]);
    }
  }

  // Get report by ID - check both collections
  Future<TechnicalVisitReport?> getReportById(String reportId) async {
    try {
      // First check drafts collection
      final draftDoc = await _drafts.doc(reportId).get();
      if (draftDoc.exists) {
        final data = draftDoc.data() as Map<String, dynamic>;
        if (_validateDocumentData(data)) {
          return TechnicalVisitReport.fromJson(data);
        }
      }

      // Then check submitted reports collection
      final submittedDoc = await _submittedReports.doc(reportId).get();
      if (submittedDoc.exists) {
        final data = submittedDoc.data() as Map<String, dynamic>;
        if (_validateDocumentData(data)) {
          return TechnicalVisitReport.fromJson(data);
        }
      }

      debugPrint('Report not found in either collection: $reportId');
      return null;
    } catch (e) {
      debugPrint('Error fetching report: $e');
      return null;
    }
  }

  // Create or update draft (always goes to drafts collection)
  Future<void> saveDraft(TechnicalVisitReport report) async {
    try {
      debugPrint('Saving draft to drafts collection: ${report.id}');

      final draftData =
          report
              .copyWith(status: 'draft', lastModified: DateTime.now())
              .toJson();

      await _drafts.doc(report.id).set(draftData);
      debugPrint('Draft saved successfully: ${report.id}');
    } catch (e) {
      debugPrint('Error saving draft: $e');
      rethrow;
    }
  }

  // Submit report - move from drafts to main collection
  Future<void> submitReport(TechnicalVisitReport report) async {
    try {
      debugPrint('Submitting report: ${report.id}');

      // Create submitted version
      final submittedReport = report.copyWith(
        status: 'submitted',
        submittedAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      // Add to main collection
      await _submittedReports.doc(report.id).set(submittedReport.toJson());

      // Remove from drafts collection
      await _drafts.doc(report.id).delete();

      debugPrint('Report submitted successfully: ${report.id}');
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  // Legacy methods for backward compatibility
  Future<void> createReport(TechnicalVisitReport report) async {
    if (report.status == 'draft') {
      await saveDraft(report);
    } else {
      await _submittedReports.doc(report.id).set(report.toJson());
    }
  }

  Future<void> updateReport(TechnicalVisitReport report) async {
    try {
      debugPrint('Updating report: ${report.id}, Status: ${report.status}');

      if (report.status == 'draft') {
        // Update in drafts collection
        await saveDraft(report);
      } else {
        // Update in main collection
        await _submittedReports.doc(report.id).update(report.toJson());
      }

      debugPrint('Report update successful');
    } catch (e) {
      debugPrint('Error updating report: $e');
      rethrow;
    }
  }

  // Update report status (for admin actions)
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _submittedReports.doc(reportId).update({
        'status': newStatus.toLowerCase(),
        'lastModified': DateTime.now().toIso8601String(),
      });
      debugPrint('Report status updated to $newStatus: $reportId');
    } catch (e) {
      debugPrint('Error updating report status: $e');
      rethrow;
    }
  }

  // Delete report - check both collections
  Future<void> deleteReport(String reportId) async {
    try {
      // Try to delete from drafts first
      final draftDoc = await _drafts.doc(reportId).get();
      if (draftDoc.exists) {
        await _drafts.doc(reportId).delete();
        debugPrint('Draft deleted: $reportId');
        return;
      }

      // If not in drafts, delete from main collection
      await _submittedReports.doc(reportId).delete();
      debugPrint('Submitted report deleted: $reportId');
    } catch (e) {
      debugPrint('Error deleting report: $e');
      rethrow;
    }
  }

  // PDF-related methods
  Future<void> updatePdfStatus(String reportId, bool generated) async {
    try {
      await _submittedReports.doc(reportId).update({
        'pdfGenerated': generated,
        'pdfGeneratedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('PDF generation status updated for report: $reportId');
    } catch (e) {
      debugPrint('Error updating PDF generation status: $e');
      rethrow;
    }
  }

  Future<void> recordPdfMetadata(String reportId, int fileSize) async {
    try {
      debugPrint('Recording PDF metadata for report: $reportId');
      await _submittedReports.doc(reportId).update({
        'pdfGenerated': true,
        'pdfGeneratedAt': DateTime.now().toIso8601String(),
        'pdfSizeBytes': fileSize,
      });
      debugPrint('PDF metadata recorded successfully');
    } catch (e) {
      debugPrint('Error recording PDF metadata: $e');
    }
  }

  // Admin-specific methods
  Stream<List<TechnicalVisitReport>> getReviewedReportsStream() {
    return _submittedReports
        .where('status', isEqualTo: 'reviewed')
        .snapshots()
        .map(_parseReportsFromSnapshot);
  }

  Stream<List<TechnicalVisitReport>> getApprovedReportsStream() {
    return _submittedReports
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(_parseReportsFromSnapshot);
  }

  Stream<List<TechnicalVisitReport>> getAllReportsStream() {
    return _submittedReports.snapshots().map(_parseReportsFromSnapshot);
  }

  // Helper method to parse reports from snapshot
  List<TechnicalVisitReport> _parseReportsFromSnapshot(QuerySnapshot snapshot) {
    final reports =
        snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (!_validateDocumentData(data)) {
                return null;
              }
              return TechnicalVisitReport.fromJson(data);
            })
            .where((report) => report != null)
            .cast<TechnicalVisitReport>()
            .toList();

    reports.sort(
      (a, b) => (b.submittedAt ?? b.createdAt).compareTo(
        a.submittedAt ?? a.createdAt,
      ),
    );

    return reports;
  }

  // Validation helper
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

  // Legacy method compatibility
  Stream<List<TechnicalVisitReport>> getReportsStream({
    String? statusFilter,
    String? technicianId,
  }) {
    // This maintains backward compatibility but routes to new methods
    if (technicianId != null) {
      if (statusFilter == 'draft') {
        return getDraftReportsStream(technicianId);
      } else {
        return getSubmittedReportsStream(technicianId);
      }
    } else {
      // Admin view - only submitted reports
      return getSubmittedReportsStreamForAdmin();
    }
  }
}
