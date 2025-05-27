// lib/view_models/statistics_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/statistics_service.dart';
import '../services/user_management_service.dart';
import '../models/user_model.dart';

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsService _statisticsService;
  final UserManagementService _userService;

  StatisticsViewModel({
    required StatisticsService statisticsService,
    required UserManagementService userService,
  }) : _statisticsService = statisticsService,
       _userService = userService {
    _initializeData();
  }

  // Dashboard statistics
  Map<String, dynamic> _dashboardStats = {};
  Map<String, int> _reportsByStatus = {};
  Map<String, dynamic> _reportsByTechnician = {};
  List<Map<String, dynamic>> _monthlyTrends = [];
  Map<String, dynamic> _userActivityStats = {};
  Map<String, dynamic> _reportCompletionStats = {};
  Map<String, int> _componentUsageStats = {};

  // Loading states
  bool _isLoadingDashboard = false;
  bool _isLoadingReports = false;
  bool _isLoadingUsers = false;
  bool _isLoadingTrends = false;

  // Error states
  String? _errorMessage;

  // Stream subscription for real-time updates
  StreamSubscription<Map<String, dynamic>>? _realtimeStatsSubscription;

  // Getters
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  Map<String, int> get reportsByStatus => _reportsByStatus;
  Map<String, dynamic> get reportsByTechnician => _reportsByTechnician;
  List<Map<String, dynamic>> get monthlyTrends => _monthlyTrends;
  Map<String, dynamic> get userActivityStats => _userActivityStats;
  Map<String, dynamic> get reportCompletionStats => _reportCompletionStats;
  Map<String, int> get componentUsageStats => _componentUsageStats;

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingReports => _isLoadingReports;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingTrends => _isLoadingTrends;
  bool get isLoading =>
      _isLoadingDashboard ||
      _isLoadingReports ||
      _isLoadingUsers ||
      _isLoadingTrends;

  String? get errorMessage => _errorMessage;

  /// Initialize data when ViewModel is created
  void _initializeData() {
    loadDashboardStats();
    loadReportsByStatus();
    loadReportsByTechnician();
    loadMonthlyTrends();
    loadUserActivityStats();
    loadReportCompletionStats();
    loadComponentUsageStats();
    _startRealtimeUpdates();
  }

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    _isLoadingDashboard = true;
    _clearError();
    notifyListeners();

    try {
      debugPrint('Loading dashboard statistics...');
      _dashboardStats = await _statisticsService.getDashboardStats();
      debugPrint('Dashboard stats loaded: ${_dashboardStats.length} metrics');
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      _setError('Failed to load dashboard statistics: $e');
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  /// Load reports by status
  Future<void> loadReportsByStatus() async {
    _isLoadingReports = true;
    _clearError();
    notifyListeners();

    try {
      debugPrint('Loading reports by status...');
      _reportsByStatus = await _statisticsService.getReportsByStatus();
      debugPrint(
        'Reports by status loaded: ${_reportsByStatus.length} statuses',
      );
    } catch (e) {
      debugPrint('Error loading reports by status: $e');
      _setError('Failed to load reports by status: $e');
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  /// Load reports by technician
  Future<void> loadReportsByTechnician() async {
    _isLoadingUsers = true;
    _clearError();
    notifyListeners();

    try {
      debugPrint('Loading reports by technician...');
      _reportsByTechnician = await _statisticsService.getReportsByTechnician();
      debugPrint(
        'Reports by technician loaded: ${_reportsByTechnician.length} technicians',
      );
    } catch (e) {
      debugPrint('Error loading reports by technician: $e');
      _setError('Failed to load technician reports: $e');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Load monthly trends
  Future<void> loadMonthlyTrends() async {
    _isLoadingTrends = true;
    _clearError();
    notifyListeners();

    try {
      debugPrint('Loading monthly trends...');
      _monthlyTrends = await _statisticsService.getMonthlyTrends();
      debugPrint('Monthly trends loaded: ${_monthlyTrends.length} months');
    } catch (e) {
      debugPrint('Error loading monthly trends: $e');
      _setError('Failed to load monthly trends: $e');
    } finally {
      _isLoadingTrends = false;
      notifyListeners();
    }
  }

  /// Load user activity statistics
  Future<void> loadUserActivityStats() async {
    try {
      debugPrint('Loading user activity stats...');
      _userActivityStats = await _statisticsService.getUserActivityStats();
      debugPrint('User activity stats loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user activity stats: $e');
      _setError('Failed to load user activity statistics: $e');
    }
  }

  /// Load report completion statistics
  Future<void> loadReportCompletionStats() async {
    try {
      debugPrint('Loading report completion stats...');
      _reportCompletionStats =
          await _statisticsService.getReportCompletionStats();
      debugPrint('Report completion stats loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading report completion stats: $e');
      _setError('Failed to load completion statistics: $e');
    }
  }

  /// Load component usage statistics
  Future<void> loadComponentUsageStats() async {
    try {
      debugPrint('Loading component usage stats...');
      _componentUsageStats = await _statisticsService.getComponentUsageStats();
      debugPrint('Component usage stats loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading component usage stats: $e');
      _setError('Failed to load component statistics: $e');
    }
  }

  /// Refresh all statistics
  Future<void> refreshAllStats() async {
    debugPrint('Refreshing all statistics...');
    await Future.wait([
      loadDashboardStats(),
      loadReportsByStatus(),
      loadReportsByTechnician(),
      loadMonthlyTrends(),
      loadUserActivityStats(),
      loadReportCompletionStats(),
      loadComponentUsageStats(),
    ]);
    debugPrint('All statistics refreshed');
  }

  /// Start real-time updates
  void _startRealtimeUpdates() {
    _realtimeStatsSubscription?.cancel();
    _realtimeStatsSubscription = _statisticsService
        .getRealtimeStatsStream()
        .listen(
          (stats) {
            _dashboardStats = stats;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error in realtime stats stream: $error');
          },
        );
  }

  /// Stop real-time updates
  void stopRealtimeUpdates() {
    _realtimeStatsSubscription?.cancel();
    _realtimeStatsSubscription = null;
  }

  // Convenience getters for common statistics
  int get totalReports => _dashboardStats['totalReports'] as int? ?? 0;
  int get draftReports => _dashboardStats['draftReports'] as int? ?? 0;
  int get submittedReports => _dashboardStats['submittedReports'] as int? ?? 0;
  int get approvedReports => _dashboardStats['approvedReports'] as int? ?? 0;
  int get monthlyReports => _dashboardStats['monthlyReports'] as int? ?? 0;
  int get weeklyReports => _dashboardStats['weeklyReports'] as int? ?? 0;
  int get activeTechnicians =>
      _dashboardStats['activeTechnicians'] as int? ?? 0;
  int get totalUsers => _dashboardStats['totalUsers'] as int? ?? 0;
  int get recentActivity => _dashboardStats['recentActivity'] as int? ?? 0;

  /// Get total active users
  int get totalActiveUsers => _userActivityStats['activeUsers'] as int? ?? 0;

  /// Get users active this week
  int get usersActiveThisWeek =>
      _userActivityStats['activeThisWeek'] as int? ?? 0;

  /// Get users active this month
  int get usersActiveThisMonth =>
      _userActivityStats['activeThisMonth'] as int? ?? 0;

  /// Get average completion time in hours
  double get averageCompletionHours =>
      _reportCompletionStats['averageCompletionHours'] as double? ?? 0.0;

  /// Get fastest completion time in hours
  double get fastestCompletionHours =>
      _reportCompletionStats['fastestCompletionHours'] as double? ?? 0.0;

  /// Get slowest completion time in hours
  double get slowestCompletionHours =>
      _reportCompletionStats['slowestCompletionHours'] as double? ?? 0.0;

  /// Get completion rate percentage
  double get completionRate {
    final total = totalReports;
    final completed = approvedReports + submittedReports;
    return total > 0 ? (completed / total) * 100 : 0.0;
  }

  /// Get most used component type
  String get mostUsedComponent {
    if (_componentUsageStats.isEmpty) return 'N/A';

    final sortedComponents =
        _componentUsageStats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return _getComponentDisplayName(sortedComponents.first.key);
  }

  /// Get component display name
  String _getComponentDisplayName(String componentKey) {
    switch (componentKey) {
      case 'networkCabinets':
        return 'Baies Informatiques';
      case 'perforations':
        return 'Percements';
      case 'accessTraps':
        return 'Trappes d\'accès';
      case 'cablePaths':
        return 'Chemins de câbles';
      case 'cableTrunkings':
        return 'Goulottes';
      case 'conduits':
        return 'Conduits';
      case 'copperCablings':
        return 'Câblages cuivre';
      case 'fiberOpticCablings':
        return 'Câblages fibre optique';
      case 'customComponents':
        return 'Composants personnalisés';
      default:
        return componentKey;
    }
  }

  /// Get top performing technicians
  List<Map<String, dynamic>> get topPerformingTechnicians {
    final techniciansList =
        _reportsByTechnician.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          return {
            'id': entry.key,
            'name': data['name'] as String? ?? 'Unknown',
            'email': data['email'] as String? ?? '',
            'totalReports': data['totalReports'] as int? ?? 0,
            'approvedReports': data['approvedReports'] as int? ?? 0,
            'lastActivity': data['lastActivity'],
          };
        }).toList();

    // Sort by total reports (descending)
    techniciansList.sort(
      (a, b) => (b['totalReports'] as int).compareTo(a['totalReports'] as int),
    );

    return techniciansList.take(5).toList(); // Top 5 technicians
  }

  /// Get report status distribution for charts
  List<Map<String, dynamic>> get reportStatusChartData {
    return _reportsByStatus.entries
        .map(
          (entry) => {
            'status': _getStatusDisplayName(entry.key),
            'count': entry.value,
            'percentage':
                totalReports > 0 ? (entry.value / totalReports) * 100 : 0.0,
          },
        )
        .toList();
  }

  /// Get status display name
  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Brouillons';
      case 'submitted':
        return 'Soumis';
      case 'reviewed':
        return 'Révisés';
      case 'approved':
        return 'Approuvés';
      default:
        return status;
    }
  }

  /// Get monthly trends for charts
  List<Map<String, dynamic>> get monthlyTrendsChartData {
    return _monthlyTrends.map((trend) {
      final data = trend['data'] as Map<String, int>;
      final total = data.values.fold(0, (sum, count) => sum + count);

      return {
        'month': trend['month'],
        'total': total,
        'draft': data['draft'] ?? 0,
        'submitted': data['submitted'] ?? 0,
        'reviewed': data['reviewed'] ?? 0,
        'approved': data['approved'] ?? 0,
      };
    }).toList();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _realtimeStatsSubscription?.cancel();
    super.dispose();
  }
}
