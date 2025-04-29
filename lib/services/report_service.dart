// lib/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _reports => _firestore.collection('reports');

  // Stream of reports for real-time updates
  Stream<List<Report>> getReportsStream({String? statusFilter}) {
    try {
      Query query;

      if (statusFilter != null && statusFilter != 'all') {
        // Using the composite index: status (ASC) + createdAt (DESC)
        query = _reports
            .where('status', isEqualTo: statusFilter.toLowerCase())
            .orderBy('createdAt', descending: true);

        debugPrint(
          'Query with filter: status=${statusFilter.toLowerCase()}, ordered by createdAt',
        );
      } else {
        // Just use ordering if no status filter
        query = _reports.orderBy('createdAt', descending: true);
        debugPrint('Query with no filter, ordered by createdAt');
      }

      return query.snapshots().map((snapshot) {
        debugPrint('Query returned ${snapshot.docs.length} documents');
        return snapshot.docs
            .map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              // Ensure all required fields are present
              if (!_validateDocumentData(data)) {
                debugPrint('Skipping invalid document: ${doc.id}');
                return null;
              }
              return Report.fromJson(data);
            })
            .where((report) => report != null)
            .cast<Report>()
            .toList();
      });
    } catch (e) {
      debugPrint('Error in getReportsStream: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }

  // Validate document data to prevent errors
  bool _validateDocumentData(Map<String, dynamic> data) {
    final requiredFields = [
      'id',
      'technicianId',
      'technicianName',
      'interventionTypeId',
      'interventionTitle',
      'description',
      'createdAt',
      'status',
    ];

    return requiredFields.every((field) => data.containsKey(field));
  }

  // Create a new report
  Future<void> createReport(Report report) async {
    try {
      await _reports.doc(report.id).set(report.toJson());
    } catch (e) {
      debugPrint('Error creating report: $e');
      rethrow;
    }
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _reports.doc(reportId).update({'status': newStatus.toLowerCase()});
    } catch (e) {
      debugPrint('Error updating report status: $e');
      rethrow;
    }
  }

  // Method to test the index directly
  Future<bool> testIndexQuery() async {
    try {
      // Test the exact query that requires the composite index
      final result =
          await _reports
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      debugPrint(
        'Index test successful! Found ${result.docs.length} documents',
      );
      return true;
    } catch (e) {
      debugPrint('Index test failed: $e');
      if (e.toString().contains('failed-precondition') &&
          e.toString().contains('requires an index')) {
        // Extract the URL to create the index
        final String errorMessage = e.toString();
        final int urlStart = errorMessage.indexOf(
          'https://console.firebase.google.com',
        );
        if (urlStart != -1) {
          final int urlEnd = errorMessage.indexOf('", code=');
          if (urlEnd != -1) {
            final String indexUrl = errorMessage.substring(urlStart, urlEnd);
            debugPrint('Create the required index at: $indexUrl');
          }
        }
      }
      return false;
    }
  }
}
