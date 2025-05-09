// lib/services/technical_visit_report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technical_visit_report.dart';

class TechnicalVisitReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reports =>
      _firestore.collection('technical_visit_reports');

  Stream<List<TechnicalVisitReport>> getReportsStream({
    String? statusFilter,
    String? technicianId,
  }) {
    try {
      Query query = _reports;

      if (statusFilter != null && statusFilter.toLowerCase() != 'all') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      if (technicianId != null) {
        query = query.where('technicianId', isEqualTo: technicianId);
      }

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
      final reportData = report.toJson();
      await _reports.doc(report.id).set(reportData);
      debugPrint('Technical visit report created: ${report.id}');
    } catch (e) {
      debugPrint('Error creating technical visit report: $e');
      rethrow;
    }
  }

  Future<void> updateReport(TechnicalVisitReport report) async {
    try {
      debugPrint('Updating report: ${report.id}, Status: ${report.status}');

      final reportData = report.toJson();

      await _reports.doc(report.id).update(reportData);

      debugPrint('Report update successful');
    } catch (e) {
      debugPrint('Error updating report: $e');

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
    return getReportsStream(statusFilter: 'draft', technicianId: technicianId);
  }

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
