import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';

class TechnicianViewModel extends ChangeNotifier {
  final ReportService _reportService;
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor with dependency injection
  TechnicianViewModel({
    required ReportService reportService,
    required AuthService authService,
  }) : _reportService = reportService,
       _authService = authService;

  // Logout function
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
    } catch (e) {
      _setError('Failed to log out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper method to set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Helper method to clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
