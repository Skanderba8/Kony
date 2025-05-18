// lib/services/statistics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technical_visit_report.dart';
import '../models/user_model.dart';
import '../models/statistics/report_stats.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all reports for statistics
  Future<List<TechnicalVisitReport>> getAllReports() async {
    try {
      final querySnapshot =
          await _firestore.collection('technical_visit_reports').get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data.isEmpty) return null;
            try {
              return TechnicalVisitReport.fromJson(data);
            } catch (e) {
              debugPrint('Error parsing report: $e');
              return null;
            }
          })
          .where((report) => report != null)
          .cast<TechnicalVisitReport>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching reports for statistics: $e');
      return [];
    }
  }

  // Get all users for statistics
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data.isEmpty) return null;
            try {
              return UserModel.fromMap(data);
            } catch (e) {
              debugPrint('Error parsing user: $e');
              return null;
            }
          })
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching users for statistics: $e');
      return [];
    }
  }

  // Calculate report completion time (from creation to submission)
  Duration? calculateCompletionTime(TechnicalVisitReport report) {
    if (report.submittedAt == null) return null;
    return report.submittedAt!.difference(report.createdAt);
  }

  // Aggregate report statistics by month
  Map<String, ReportStats> getMonthlyReportStats(
    List<TechnicalVisitReport> reports,
  ) {
    final Map<String, ReportStats> monthlyStats = {};

    for (final report in reports) {
      final month =
          '${report.createdAt.year}-${report.createdAt.month.toString().padLeft(2, '0')}';

      if (!monthlyStats.containsKey(month)) {
        monthlyStats[month] = ReportStats(
          total: 0,
          draft: 0,
          submitted: 0,
          reviewed: 0,
          approved: 0,
          averageDuration: 0,
          totalComponents: 0,
        );
      }

      // Update stats
      final stats = monthlyStats[month]!;
      stats.total++;

      switch (report.status) {
        case 'draft':
          stats.draft++;
          break;
        case 'submitted':
          stats.submitted++;
          break;
        case 'reviewed':
          stats.reviewed++;
          break;
        case 'approved':
          stats.approved++;
          break;
      }

      // Count components
      int componentCount = 0;
      for (final floor in report.floors) {
        // Use the null-safe access for totalComponentCount
        componentCount += floor.totalComponentCount ?? 0;
      }
      stats.totalComponents += componentCount;

      // Calculate average duration for completed reports
      if (report.status != 'draft' && report.submittedAt != null) {
        final duration = calculateCompletionTime(report);
        if (duration != null) {
          final currentAvg = stats.averageDuration;
          final currentCount =
              stats.submitted + stats.reviewed + stats.approved;

          if (currentCount > 0) {
            stats.averageDuration =
                (currentAvg * (currentCount - 1) + duration.inHours) /
                currentCount;
          } else {
            stats.averageDuration = duration.inHours.toDouble();
          }
        }
      }
    }

    return monthlyStats;
  }

  // Get technician productivity stats
  Map<String, int> getTechnicianProductivity(
    List<TechnicalVisitReport> reports,
  ) {
    final Map<String, int> productivity = {};

    for (final report in reports) {
      if (report.status != 'draft') {
        // Only count completed reports
        final techId = report.technicianId;
        productivity[techId] = (productivity[techId] ?? 0) + 1;
      }
    }

    return productivity;
  }

  // Get component distribution across all reports
  Map<String, int> getComponentDistribution(
    List<TechnicalVisitReport> reports,
  ) {
    final Map<String, int> distribution = {
      'Baies Informatiques': 0,
      'Percements': 0,
      'Trappes d\'accès': 0,
      'Chemins de câbles': 0,
      'Goulottes': 0,
      'Conduits': 0,
      'Câblages cuivre': 0,
      'Câblages fibre optique': 0,
      'Composants personnalisés': 0,
    };

    for (final report in reports) {
      for (final floor in report.floors) {
        // Safely update distribution counts using null-safe methods
        distribution['Baies Informatiques'] =
            (distribution['Baies Informatiques'] ?? 0) +
            (floor.networkCabinets.length ?? 0);
        distribution['Percements'] =
            (distribution['Percements'] ?? 0) +
            (floor.perforations.length ?? 0);
        distribution['Trappes d\'accès'] =
            (distribution['Trappes d\'accès'] ?? 0) +
            (floor.accessTraps.length ?? 0);
        distribution['Chemins de câbles'] =
            (distribution['Chemins de câbles'] ?? 0) +
            (floor.cablePaths.length ?? 0);
        distribution['Goulottes'] =
            (distribution['Goulottes'] ?? 0) +
            (floor.cableTrunkings.length ?? 0);
        distribution['Conduits'] =
            (distribution['Conduits'] ?? 0) + (floor.conduits.length ?? 0);
        distribution['Câblages cuivre'] =
            (distribution['Câblages cuivre'] ?? 0) +
            (floor.copperCablings.length ?? 0);
        distribution['Câblages fibre optique'] =
            (distribution['Câblages fibre optique'] ?? 0) +
            (floor.fiberOpticCablings.length ?? 0);
        distribution['Composants personnalisés'] =
            (distribution['Composants personnalisés'] ?? 0) +
            (floor.customComponents.length ?? 0);
      }
    }

    return distribution;
  }

  // Get location distribution
  Map<String, int> getLocationDistribution(List<TechnicalVisitReport> reports) {
    final Map<String, int> distribution = {};

    for (final report in reports) {
      if (report.location.isNotEmpty) {
        // Simplify location to city or first part before comma
        final String simplifiedLocation =
            report.location.split(',').first.trim();
        distribution[simplifiedLocation] =
            (distribution[simplifiedLocation] ?? 0) + 1;
      }
    }

    return distribution;
  }

  // Get estimated duration statistics
  Map<String, double> getDurationStatistics(
    List<TechnicalVisitReport> reports,
  ) {
    if (reports.isEmpty) {
      return {'average': 0, 'median': 0, 'min': 0, 'max': 0};
    }

    final List<int> durations = [];
    for (final report in reports) {
      if (report.estimatedDurationDays > 0) {
        durations.add(report.estimatedDurationDays);
      }
    }

    if (durations.isEmpty) {
      return {'average': 0, 'median': 0, 'min': 0, 'max': 0};
    }

    // Sort for median calculation
    durations.sort();

    final double average = durations.reduce((a, b) => a + b) / durations.length;
    final double median =
        durations.length.isOdd
            ? durations[durations.length ~/ 2].toDouble()
            : (durations[(durations.length ~/ 2) - 1] +
                    durations[durations.length ~/ 2]) /
                2.0;

    return {
      'average': average,
      'median': median,
      'min': durations.first.toDouble(),
      'max': durations.last.toDouble(),
    };
  }
}
