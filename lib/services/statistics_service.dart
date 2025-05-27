// lib/services/statistics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/technical_visit_report.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get all reports
      final reportsSnapshot =
          await _firestore.collection('technical_visit_reports').get();

      final reports =
          reportsSnapshot.docs.map((doc) {
            final data = doc.data();
            return TechnicalVisitReport.fromJson(data);
          }).toList();

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      final users =
          usersSnapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson(data, authUid: doc.id);
          }).toList();

      // Calculate statistics
      final totalReports = reports.length;
      final draftReports = reports.where((r) => r.status == 'draft').length;
      final submittedReports =
          reports.where((r) => r.status == 'submitted').length;
      final reviewedReports =
          reports.where((r) => r.status == 'reviewed').length;
      final approvedReports =
          reports.where((r) => r.status == 'approved').length;

      // Monthly reports
      final monthlyReports =
          reports.where((r) {
            final reportDate = r.submittedAt ?? r.createdAt;
            return reportDate.isAfter(startOfMonth);
          }).length;

      // Weekly reports
      final weeklyReports =
          reports.where((r) {
            final reportDate = r.submittedAt ?? r.createdAt;
            return reportDate.isAfter(startOfWeek);
          }).length;

      // Active technicians
      final activeTechnicians =
          users
              .where((u) => u.role.toLowerCase() == 'technician' && u.isActive)
              .length;

      // Recent activity (last 7 days)
      final recentActivity =
          reports.where((r) {
            final reportDate = r.lastModified ?? r.createdAt;
            return reportDate.isAfter(now.subtract(const Duration(days: 7)));
          }).length;

      return {
        'totalReports': totalReports,
        'draftReports': draftReports,
        'submittedReports': submittedReports,
        'reviewedReports': reviewedReports,
        'approvedReports': approvedReports,
        'monthlyReports': monthlyReports,
        'weeklyReports': weeklyReports,
        'activeTechnicians': activeTechnicians,
        'recentActivity': recentActivity,
        'totalUsers': users.length,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return <String, dynamic>{};
    }
  }

  /// Get reports by status
  Future<Map<String, int>> getReportsByStatus() async {
    try {
      final snapshot =
          await _firestore.collection('technical_visit_reports').get();

      final reports =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return TechnicalVisitReport.fromJson(data);
          }).toList();

      final statusCounts = <String, int>{};
      for (final report in reports) {
        statusCounts[report.status] = (statusCounts[report.status] ?? 0) + 1;
      }

      return statusCounts;
    } catch (e) {
      debugPrint('Error getting reports by status: $e');
      return <String, int>{};
    }
  }

  /// Get reports by technician
  Future<Map<String, dynamic>> getReportsByTechnician() async {
    try {
      final reportsSnapshot =
          await _firestore.collection('technical_visit_reports').get();

      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'technician')
              .get();

      final reports =
          reportsSnapshot.docs.map((doc) {
            final data = doc.data();
            return TechnicalVisitReport.fromJson(data);
          }).toList();

      final users =
          usersSnapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson(data, authUid: doc.id);
          }).toList();

      final technicianStats = <String, Map<String, dynamic>>{};

      for (final user in users) {
        final userReports =
            reports.where((r) => r.technicianId == user.authUid).toList();

        technicianStats[user.authUid] = {
          'name': user.name,
          'email': user.email,
          'totalReports': userReports.length,
          'draftReports': userReports.where((r) => r.status == 'draft').length,
          'submittedReports':
              userReports.where((r) => r.status == 'submitted').length,
          'approvedReports':
              userReports.where((r) => r.status == 'approved').length,
          'lastActivity':
              userReports.isNotEmpty
                  ? userReports
                      .map((r) => r.lastModified ?? r.createdAt)
                      .reduce((a, b) => a.isAfter(b) ? a : b)
                  : null,
        };
      }

      return technicianStats;
    } catch (e) {
      debugPrint('Error getting reports by technician: $e');
      return <String, dynamic>{};
    }
  }

  /// Get monthly report trends
  Future<List<Map<String, dynamic>>> getMonthlyTrends() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      final snapshot =
          await _firestore
              .collection('technical_visit_reports')
              .where('createdAt', isGreaterThan: sixMonthsAgo)
              .get();

      final reports =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return TechnicalVisitReport.fromJson(data);
          }).toList();

      final monthlyData = <String, Map<String, int>>{};

      for (final report in reports) {
        final reportDate = report.submittedAt ?? report.createdAt;
        final monthKey =
            '${reportDate.year}-${reportDate.month.toString().padLeft(2, '0')}';

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'draft': 0,
            'submitted': 0,
            'reviewed': 0,
            'approved': 0,
          };
        }

        monthlyData[monthKey]![report.status] =
            (monthlyData[monthKey]![report.status] ?? 0) + 1;
      }

      final sortedEntries =
          monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      return sortedEntries
          .map((entry) => {'month': entry.key, 'data': entry.value})
          .toList();
    } catch (e) {
      debugPrint('Error getting monthly trends: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Get user activity statistics
  Future<Map<String, dynamic>> getUserActivityStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final users =
          usersSnapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson(data, authUid: doc.id);
          }).toList();

      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = DateTime(now.year, now.month - 1, now.day);

      final activeThisWeek =
          users
              .where(
                (u) =>
                    u.lastLoginAt != null && u.lastLoginAt!.isAfter(lastWeek),
              )
              .length;

      final activeThisMonth =
          users
              .where(
                (u) =>
                    u.lastLoginAt != null && u.lastLoginAt!.isAfter(lastMonth),
              )
              .length;

      final totalActive = users.where((u) => u.isActive).length;
      final totalInactive = users.where((u) => !u.isActive).length;

      final adminCount =
          users.where((u) => u.role.toLowerCase() == 'admin').length;
      final technicianCount =
          users.where((u) => u.role.toLowerCase() == 'technician').length;

      return {
        'totalUsers': users.length,
        'activeUsers': totalActive,
        'inactiveUsers': totalInactive,
        'activeThisWeek': activeThisWeek,
        'activeThisMonth': activeThisMonth,
        'adminCount': adminCount,
        'technicianCount': technicianCount,
      };
    } catch (e) {
      debugPrint('Error getting user activity stats: $e');
      return <String, dynamic>{};
    }
  }

  /// Get average report completion time
  Future<Map<String, dynamic>> getReportCompletionStats() async {
    try {
      final snapshot =
          await _firestore
              .collection('technical_visit_reports')
              .where('status', whereIn: ['submitted', 'approved'])
              .get();

      final reports =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return TechnicalVisitReport.fromJson(data);
          }).toList();

      if (reports.isEmpty) {
        return {
          'averageCompletionHours': 0.0,
          'fastestCompletionHours': 0.0,
          'slowestCompletionHours': 0.0,
          'totalCompletedReports': 0,
        };
      }

      final completionTimes = <double>[];

      for (final report in reports) {
        if (report.submittedAt != null) {
          final createdAt = report.createdAt;
          final submittedAt = report.submittedAt!;
          final completionHours =
              submittedAt.difference(createdAt).inHours.toDouble();
          completionTimes.add(completionHours);
        }
      }

      final averageHours =
          completionTimes.isNotEmpty
              ? completionTimes.reduce((a, b) => a + b) / completionTimes.length
              : 0.0;

      final fastestHours =
          completionTimes.isNotEmpty
              ? completionTimes.reduce((a, b) => a < b ? a : b)
              : 0.0;

      final slowestHours =
          completionTimes.isNotEmpty
              ? completionTimes.reduce((a, b) => a > b ? a : b)
              : 0.0;

      return {
        'averageCompletionHours': averageHours,
        'fastestCompletionHours': fastestHours,
        'slowestCompletionHours': slowestHours,
        'totalCompletedReports': completionTimes.length,
      };
    } catch (e) {
      debugPrint('Error getting report completion stats: $e');
      return <String, dynamic>{};
    }
  }

  /// Get component usage statistics
  Future<Map<String, int>> getComponentUsageStats() async {
    try {
      final snapshot =
          await _firestore.collection('technical_visit_reports').get();

      final reports =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return TechnicalVisitReport.fromJson(data);
          }).toList();

      final componentCounts = <String, int>{
        'networkCabinets': 0,
        'perforations': 0,
        'accessTraps': 0,
        'cablePaths': 0,
        'cableTrunkings': 0,
        'conduits': 0,
        'copperCablings': 0,
        'fiberOpticCablings': 0,
        'customComponents': 0,
      };

      for (final report in reports) {
        for (final floor in report.floors) {
          componentCounts['networkCabinets'] =
              (componentCounts['networkCabinets'] ?? 0) +
              floor.networkCabinets.length;
          componentCounts['perforations'] =
              (componentCounts['perforations'] ?? 0) +
              floor.perforations.length;
          componentCounts['accessTraps'] =
              (componentCounts['accessTraps'] ?? 0) + floor.accessTraps.length;
          componentCounts['cablePaths'] =
              (componentCounts['cablePaths'] ?? 0) + floor.cablePaths.length;
          componentCounts['cableTrunkings'] =
              (componentCounts['cableTrunkings'] ?? 0) +
              floor.cableTrunkings.length;
          componentCounts['conduits'] =
              (componentCounts['conduits'] ?? 0) + floor.conduits.length;
          componentCounts['copperCablings'] =
              (componentCounts['copperCablings'] ?? 0) +
              floor.copperCablings.length;
          componentCounts['fiberOpticCablings'] =
              (componentCounts['fiberOpticCablings'] ?? 0) +
              floor.fiberOpticCablings.length;
          componentCounts['customComponents'] =
              (componentCounts['customComponents'] ?? 0) +
              floor.customComponents.length;
        }
      }

      return componentCounts;
    } catch (e) {
      debugPrint('Error getting component usage stats: $e');
      return <String, int>{};
    }
  }

  /// Get real-time statistics stream
  Stream<Map<String, dynamic>> getRealtimeStatsStream() {
    return _firestore
        .collection('technical_visit_reports')
        .snapshots()
        .asyncMap((_) async => await getDashboardStats());
  }
}
