// lib/view_models/statistics_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/technical_visit_report.dart';
import '../models/user_model.dart';
import '../models/statistics/report_stats.dart';
import '../services/statistics_service.dart';
import '../services/user_management_service.dart';

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsService _statisticsService;
  final UserManagementService _userService;

  bool _isLoading = false;
  String? _errorMessage;

  // Data holders
  List<TechnicalVisitReport> _reports = [];
  List<UserModel> _users = [];
  Map<String, ReportStats> _monthlyStats = {};
  Map<String, int> _technicianProductivity = {};
  Map<String, int> _componentDistribution = {};
  Map<String, int> _locationDistribution = {};
  Map<String, double> _durationStatistics = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TechnicalVisitReport> get reports => _reports;
  List<UserModel> get users => _users;
  Map<String, ReportStats> get monthlyStats => _monthlyStats;
  Map<String, int> get technicianProductivity => _technicianProductivity;
  Map<String, int> get componentDistribution => _componentDistribution;
  Map<String, int> get locationDistribution => _locationDistribution;
  Map<String, double> get durationStatistics => _durationStatistics;

  // lib/view_models/statistics_view_model.dart (update constructor)
  // Constructor with dependencies
  StatisticsViewModel({
    required StatisticsService statisticsService,
    required UserManagementService userService,
  }) : _statisticsService = statisticsService,
       _userService = userService;

  // Load all statistics
  Future<void> loadAllStatistics() async {
    _setLoading(true);
    _clearError();

    try {
      // Load reports and users
      _reports = await _statisticsService.getAllReports();
      _users = await _statisticsService.getAllUsers();

      // Calculate statistics
      _monthlyStats = _statisticsService.getMonthlyReportStats(_reports);
      _technicianProductivity = _statisticsService.getTechnicianProductivity(
        _reports,
      );
      _componentDistribution = _statisticsService.getComponentDistribution(
        _reports,
      );
      _locationDistribution = _statisticsService.getLocationDistribution(
        _reports,
      );
      _durationStatistics = _statisticsService.getDurationStatistics(_reports);

      notifyListeners();
    } catch (e) {
      _setError('Failed to load statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get technician name by ID
  String getTechnicianName(String techId) {
    final user = _users.firstWhere(
      (user) => user.authUid == techId,
      orElse:
          () => UserModel(
            id: 'unknown',
            name: 'Technicien inconnu',
            email: '',
            role: 'technician',
          ),
    );

    return user.name;
  }

  // Get total reports count
  int get totalReports => _reports.length;

  // Get total components count
  int get totalComponents {
    return _componentDistribution.values.fold(0, (sum, value) => sum + value);
  }

  // Get average completion time in hours
  double get averageCompletionTime {
    final completedReports =
        _reports.where((r) => r.submittedAt != null).toList();
    if (completedReports.isEmpty) return 0;

    double totalHours = 0;
    int count = 0;

    for (final report in completedReports) {
      final duration = _statisticsService.calculateCompletionTime(report);
      if (duration != null) {
        totalHours += duration.inHours;
        count++;
      }
    }

    return count > 0 ? totalHours / count : 0;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
