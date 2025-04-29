// lib/view_models/user_management_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_management_service.dart';
import '../models/user_model.dart';

class UserManagementViewModel extends ChangeNotifier {
  final UserManagementService _service;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;

  // Constructor
  UserManagementViewModel({required UserManagementService userService})
    : _service = userService;

  // Create a new user
  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createUser(email: email, password: password, name: name);

      // Refresh user list
      await loadUsers();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all users
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.getUsers();
    } catch (e) {
      _errorMessage = 'Error loading users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a user
  Future<bool> deleteUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteUser(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting user: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a specific user by their authentication UID
  Future<UserModel?> getUserByAuthUid(String authUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _service.getUserByAuthUid(authUid);
      return user;
    } catch (e) {
      _errorMessage = 'Error fetching user: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a user's editable information
  Future<bool> updateUser({
    required String authUid,
    required String name,
    required String email,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.updateUser(
        authUid: authUid,
        name: name,
        email: email,
        role: role,
      );

      if (success) {
        await loadUsers();
      } else {
        _errorMessage = 'Failed to update user';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Error updating user: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a user completely from both Firestore and Auth
  Future<bool> deleteUserCompletely(String authUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.deleteUserCompletely(authUid);

      if (success) {
        await loadUsers();
      } else {
        _errorMessage = 'Failed to delete user completely';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Error deleting user: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper for Firebase error messages
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email is already in use';
      case 'invalid-email':
        return 'Invalid email format';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return e.message ?? 'Authentication error';
    }
  }
}
