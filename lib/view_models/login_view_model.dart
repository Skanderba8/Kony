// lib/view_models/login_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  LoginViewModel({required AuthService authService})
    : _authService = authService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Add the missing lastErrorMessage getter
  String get lastErrorMessage =>
      _errorMessage ?? 'Une erreur inconnue s\'est produite';

  /// Sign in with email and password - UPDATED WITH ISACTIVE CHECK
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password, {
    bool keepLoggedIn = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Attempting to sign in with email: $email');

      final userModel = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
        keepLoggedIn: keepLoggedIn,
      );

      if (userModel != null) {
        // Additional check for isActive (already handled in AuthService, but double-check)
        if (!userModel.isActive) {
          debugPrint('User account is inactive: ${userModel.email}');
          _setError(
            'Votre compte a été désactivé. Contactez l\'administrateur.',
          );
          return null;
        }

        debugPrint('Authentication successful. User: ${userModel.email}');
        return userModel;
      } else {
        _setError('Failed to authenticate user');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cette adresse email.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'Adresse email invalide.';
          break;
        case 'user-disabled':
          message =
              'Votre compte a été désactivé. Contactez l\'administrateur.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Veuillez réessayer plus tard.';
          break;
        case 'network-request-failed':
          message = 'Erreur de connexion réseau.';
          break;
        case 'invalid-credential':
          message = 'Email ou mot de passe incorrect.';
          break;
        default:
          message = 'Erreur d\'authentification: ${e.message}';
          break;
      }
      debugPrint('Authentication error: ${e.code} - ${e.message}');
      _setError(message);
      return null;
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      _setError('Une erreur inattendue s\'est produite.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Sending password reset email to: $email');
      await _authService.sendPasswordResetEmail(email);
      debugPrint('Password reset email sent successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cette adresse email.';
          break;
        case 'invalid-email':
          message = 'Adresse email invalide.';
          break;
        case 'too-many-requests':
          message = 'Trop de demandes. Veuillez réessayer plus tard.';
          break;
        default:
          message = 'Erreur lors de l\'envoi de l\'email: ${e.message}';
          break;
      }
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      _setError(message);
      return false;
    } catch (e) {
      debugPrint('Unexpected error during password reset: $e');
      _setError('Une erreur inattendue s\'est produite.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Signing out user');
      await _authService.signOut();
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      _setError('Erreur lors de la déconnexion.');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _authService.isAuthenticated;
  }

  /// Get current user
  User? getCurrentUser() {
    return _authService.currentUser;
  }

  /// Get current user model
  UserModel? getCurrentUserModel() {
    return _authService.currentUserModel;
  }

  /// Get current user role
  String? getUserRole() {
    try {
      // If we have a cached user model, return its role
      final userModel = getCurrentUserModel();
      if (userModel != null) {
        return userModel.role;
      }

      // Otherwise, get user role from auth service
      return _authService.getUserRole();
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  /// Check if current user is admin
  bool isAdmin() {
    return _authService.isAdmin();
  }

  /// Check if current user is technician
  bool isTechnician() {
    return _authService.isTechnician();
  }

  /// Check if current user account is active
  bool isUserActive() {
    final userModel = getCurrentUserModel();
    return userModel?.isActive ?? false;
  }

  /// Add the missing isPhoneNumberMissing method
  Future<bool> isPhoneNumberMissing() async {
    try {
      final userModel = getCurrentUserModel();
      if (userModel != null) {
        // Check if phone number is null, empty, or just whitespace
        return userModel.phoneNumber == null ||
            userModel.phoneNumber!.trim().isEmpty;
      }

      // If no user model, try to get user info from auth service
      final user = getCurrentUser();
      if (user != null) {
        // You might need to fetch user profile from Firestore here
        // For now, we'll assume phone number is missing if user model is null
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking phone number: $e');
      // In case of error, assume phone number is not missing to avoid false notifications
      return false;
    }
  }

  /// Validate user account status on app resume or periodic checks
  Future<bool> validateAccountStatus() async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) {
        return false;
      }

      // Fetch latest user data from Firestore to check if account is still active
      final userModel = await _authService.getUserById(currentUser.uid);

      if (userModel == null) {
        debugPrint('User account not found in database');
        await signOut();
        _setError('Votre compte n\'existe plus. Contactez l\'administrateur.');
        return false;
      }

      if (!userModel.isActive) {
        debugPrint('User account has been deactivated');
        await signOut();
        _setError('Votre compte a été désactivé. Contactez l\'administrateur.');
        return false;
      }

      // Account is still valid and active
      return true;
    } catch (e) {
      debugPrint('Error validating account status: $e');
      return true; // Don't sign out on validation errors
    }
  }

  /// Check if profile information is complete
  bool isProfileComplete() {
    final userModel = getCurrentUserModel();
    return userModel?.isProfileComplete ?? false;
  }

  /// Get user display name
  String? getUserDisplayName() {
    final userModel = getCurrentUserModel();
    return userModel?.displayName;
  }

  /// Get user email
  String? getUserEmail() {
    final userModel = getCurrentUserModel();
    return userModel?.email;
  }

  /// Clear any existing error
  void clearError() {
    _clearError();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh current user data
  Future<void> refreshUserData() async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser != null) {
        // Use the public method to get fresh user data
        final userModel = await _authService.getUserById(currentUser.uid);
        if (userModel != null) {
          // The auth service will handle updating its internal state
          debugPrint('User data refreshed successfully');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }
}
