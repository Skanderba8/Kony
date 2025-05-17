import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kony/services/user_management_service.dart';
import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  String _lastErrorMessage = "";

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  String get lastErrorMessage => _lastErrorMessage;

  // Constructor with dependency injection
  LoginViewModel({required AuthService authService})
    : _authService = authService;

  // Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _setError('Please fill in all fields');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      debugPrint('Attempting to sign in with email: $email');
      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      debugPrint(
        'Authentication successful. User ID: ${userCredential.user?.uid}',
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        default:
          message = 'Authentication failed: ${e.message}';
      }

      debugPrint('Authentication error: $message (code: ${e.code})');
      _lastErrorMessage = message;
      _setError(message);
      return null;
    } catch (e) {
      debugPrint('Unexpected authentication error: $e');
      _lastErrorMessage = 'An unexpected error occurred during authentication';
      _setError('An unexpected error occurred during authentication');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      debugPrint('Attempting to fetch user role...');
      final role = await _authService.getUserRole();
      debugPrint('User role fetched: $role');
      return role;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      _lastErrorMessage = 'Error fetching user role: $e';
      _setError('Error fetching user role');
      return null;
    }
  }

  Future<bool> isPhoneNumberMissing() async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      // Get the user service from the user management service
      final userManagementService = UserManagementService();
      final userModel = await userManagementService.getUserByAuthUid(user.uid);

      // Check if phone number is missing
      return userModel?.phoneNumber == null || userModel!.phoneNumber!.isEmpty;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError('Failed to send password reset email');
      debugPrint('Error sending password reset: $e');
      return false;
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
