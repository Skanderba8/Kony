import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';

// Just add this getter to your existing TechnicianViewModel class
// No constructor changes needed!

class TechnicianViewModel extends ChangeNotifier {
  final ReportService _reportService;
  final AuthService _authService;

  final bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Add this getter - no other changes needed!
  String get currentUserName {
    final user = _authService.currentUser;
    if (user != null) {
      // Try to get display name first, then fall back to email prefix
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      } else if (user.email != null) {
        // Extract name from email (everything before @)
        return user.email!.split('@').first;
      }
    }
    return 'Technicien'; // Fallback
  }

  // Constructor with dependency injection - keep as is
  TechnicianViewModel({
    required ReportService reportService,
    required AuthService authService,
  }) : _reportService = reportService,
       _authService = authService;

  // ... rest of your existing methods stay the same ...
}
