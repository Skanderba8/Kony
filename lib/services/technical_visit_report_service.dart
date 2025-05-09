// lib/services/technical_visit_report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technical_visit_report.dart';

class TechnicalVisitReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reports =>
      _firestore.collection('technical_visit_reports');

  // In the technical_visit_report_service.dart file, you'll need to:
  // 1. Remove any queries that combine where() and orderBy()
  // 2. Replace them with simpler queries and in-memory filtering/sorting

  Stream<List<TechnicalVisitReport>> getReportsStream({
    String? statusFilter,
    String? technicianId,
  }) {
    try {
      Query query = _firestore.collection('technical_visit_reports');

      // Only use one filter condition
      if (statusFilter != null && statusFilter.toLowerCase() != 'all') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      } else if (technicianId != null) {
        query = query.where('technicianId', isEqualTo: technicianId);
      }

      // Remove any orderBy clauses - do sorting in memory instead
      return query.snapshots().map((snapshot) {
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

        // If needed, filter by the other condition in memory
        final filteredReports =
            reports.where((report) {
              if (statusFilter != null && technicianId != null) {
                return report.status == statusFilter.toLowerCase() &&
                    report.technicianId == technicianId;
              }
              return true;
            }).toList();

        // Sort in memory if needed
        filteredReports.sort(
          (a, b) => (b.submittedAt ?? b.createdAt).compareTo(
            a.submittedAt ?? a.createdAt,
          ),
        );

        return filteredReports;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

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

  Future<void> createReport(TechnicalVisitReport report) async {
    try {
      debugPrint('Creating report in Firestore with ID: ${report.id}');
      debugPrint('Report status: ${report.status}');
      debugPrint('Report technician ID: ${report.technicianId}');

      final reportData = report.toJson();
      await _reports.doc(report.id).set(reportData);

      debugPrint('Report created successfully: ${report.id}');
    } catch (e) {
      debugPrint('Error creating report: $e');

      // Provide more detailed error information
      if (e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('Firestore security rules prevented the write operation');
      } else if (e.toString().contains('NOT_FOUND')) {
        debugPrint('Collection or document path not found');
      }

      rethrow;
    }
  }

  Future<void> updateReport(TechnicalVisitReport report) async {
    try {
      // Log the operation to help with debugging
      debugPrint('Updating report: ${report.id}, Status: ${report.status}');
      debugPrint('Report technician ID: ${report.technicianId}');

      // First check if document exists
      final docSnapshot = await _reports.doc(report.id).get();

      if (!docSnapshot.exists) {
        debugPrint(
          'Report document does not exist, will create it: ${report.id}',
        );
        await createReport(report);
        return;
      }

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

  Future<void> submitReport(String reportId) async {
    try {
      final docSnapshot = await _reports.doc(reportId).get();

      if (!docSnapshot.exists) {
        debugPrint('Report document does not exist: $reportId');
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message:
              'Le document du rapport n\'existe pas. Créez d\'abord un brouillon.',
        );
      }

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
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _reports.doc(reportId).delete();
      debugPrint('Technical visit report deleted: $reportId');
    } catch (e) {
      debugPrint('Error deleting technical visit report: $e');
      rethrow;
    }
  }

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

  Stream<List<TechnicalVisitReport>> getDraftReportsStream(
    String technicianId,
  ) {
    try {
      // Only use one condition, don't combine where() with orderBy()
      final query = _reports.where('technicianId', isEqualTo: technicianId);

      return query.snapshots().map((snapshot) {
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

        // Filter for draft status in memory
        final draftReports =
            reports.where((report) => report.status == 'draft').toList();

        // Sort by lastModified in memory
        draftReports.sort(
          (a, b) => (b.lastModified ?? b.createdAt).compareTo(
            a.lastModified ?? a.createdAt,
          ),
        );

        return draftReports;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream(
    String technicianId,
  ) {
    try {
      // Only use single condition queries
      final query = _reports.where('technicianId', isEqualTo: technicianId);

      return query.snapshots().map((snapshot) {
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

        // Filter for submitted/reviewed/approved status in memory
        final submittedReports =
            reports
                .where(
                  (report) => [
                    'submitted',
                    'reviewed',
                    'approved',
                  ].contains(report.status),
                )
                .toList();

        // Sort by submittedAt in memory
        submittedReports.sort(
          (a, b) => (b.submittedAt ?? b.createdAt).compareTo(
            a.submittedAt ?? a.createdAt,
          ),
        );

        return submittedReports;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }
}
