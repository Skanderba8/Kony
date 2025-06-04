// lib/view_models/user_management_view_model.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/user_management_service.dart';
import '../models/user_model.dart';

class UserManagementViewModel extends ChangeNotifier {
  final UserManagementService _service;

  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];

  UserManagementViewModel({required UserManagementService userService})
    : _service = userService;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;

  // Create user
  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Creating user: $email');
      await _service.createUser(email: email, password: password, name: name);
      await loadUsers();
      debugPrint('User created successfully: $email');
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      _errorMessage = 'Erreur lors de la création: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load users
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Loading users...');
      _users = await _service.getUsers();
      debugPrint('Loaded ${_users.length} users');
    } catch (e) {
      debugPrint('Error loading users: $e');
      _errorMessage = 'Erreur lors du chargement: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile - FIXED VERSION
  Future<bool> updateUserProfile({
    required String authUid,
    String? name,
    String? email,
    File? profilePicture,
    String? phoneNumber,
    String? address,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Updating user profile: $authUid');

      final success = await _service.updateUserProfile(
        authUid: authUid,
        name: name,
        email: email,
        profilePicture: profilePicture,
        phoneNumber: phoneNumber,
        address: address,
        department: department,
      );

      if (success) {
        debugPrint('User profile updated successfully: $authUid');
        // Reload users to get updated data
        await loadUsers();
      } else {
        _errorMessage = 'Échec de la mise à jour du profil';
        debugPrint('Failed to update user profile: $authUid');
      }

      return success;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      _errorMessage = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update email - FIXED VERSION
  Future<bool> updateEmail(String password, String newEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Updating email to: $newEmail');

      final success = await _service.updateEmail(password, newEmail);

      if (!success) {
        _errorMessage = 'La mise à jour de l\'email a échoué';
        debugPrint('Failed to update email');
      } else {
        debugPrint('Email updated successfully');
        // Reload users to get updated data
        await loadUsers();
      }

      return success;
    } catch (e) {
      debugPrint('Error updating email: $e');
      _errorMessage = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activate user
  Future<bool> activateUser(String authUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Activating user: $authUid');

      final success = await _service.activateUser(authUid);

      if (success) {
        debugPrint('User activated successfully: $authUid');
        await loadUsers(); // Reload to show updated status
      } else {
        _errorMessage = 'Échec de l\'activation de l\'utilisateur';
        debugPrint('Failed to activate user: $authUid');
      }

      return success;
    } catch (e) {
      debugPrint('Error activating user: $e');
      _errorMessage = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Deactivate user
  Future<bool> deactivateUser(String authUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Deactivating user: $authUid');

      final success = await _service.deactivateUser(authUid);

      if (success) {
        debugPrint('User deactivated successfully: $authUid');
        await loadUsers(); // Reload to show updated status
      } else {
        _errorMessage = 'Échec de la désactivation de l\'utilisateur';
        debugPrint('Failed to deactivate user: $authUid');
      }

      return success;
    } catch (e) {
      debugPrint('Error deactivating user: $e');
      _errorMessage = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle user active status
  Future<bool> toggleUserActiveStatus(String authUid, bool isActive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Toggling user status: $authUid -> $isActive');

      final success = await _service.toggleUserActiveStatus(authUid, isActive);

      if (success) {
        debugPrint('User status toggled successfully: $authUid -> $isActive');
        await loadUsers(); // Reload to show updated status
      } else {
        _errorMessage = 'Échec du changement de statut de l\'utilisateur';
        debugPrint('Failed to toggle user status: $authUid');
      }

      return success;
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      _errorMessage = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user by auth UID
  Future<UserModel?> getUserByAuthUid(String authUid) async {
    try {
      debugPrint('Getting user by auth UID: $authUid');
      return await _service.getUserByAuthUid(authUid);
    } catch (e) {
      debugPrint('Error getting user by auth UID: $e');
      _errorMessage = 'Erreur lors de la récupération de l\'utilisateur: $e';
      notifyListeners();
      return null;
    }
  }

  // Get users by role
  List<UserModel> getUsersByRole(String role) {
    return _users
        .where((user) => user.role.toLowerCase() == role.toLowerCase())
        .toList();
  }

  // Get active users
  List<UserModel> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  // Get inactive users
  List<UserModel> getInactiveUsers() {
    return _users.where((user) => !user.isActive).toList();
  }

  // Get user statistics
  Map<String, int> getUserStatistics() {
    final stats = <String, int>{};

    stats['total'] = _users.length;
    stats['active'] = _users.where((user) => user.isActive).length;
    stats['inactive'] = _users.where((user) => !user.isActive).length;
    stats['admins'] =
        _users.where((user) => user.role.toLowerCase() == 'admin').length;
    stats['technicians'] =
        _users.where((user) => user.role.toLowerCase() == 'technician').length;

    return stats;
  }

  // Search users
  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;

    final lowercaseQuery = query.toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(lowercaseQuery) ||
          user.email.toLowerCase().contains(lowercaseQuery) ||
          (user.phoneNumber?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (user.department?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Filter users by multiple criteria
  List<UserModel> filterUsers({
    String? role,
    bool? isActive,
    String? searchQuery,
  }) {
    List<UserModel> filtered = List.from(_users);

    // Filter by role
    if (role != null && role.toLowerCase() != 'all') {
      if (role.toLowerCase() == 'active') {
        filtered = filtered.where((user) => user.isActive).toList();
      } else if (role.toLowerCase() == 'inactive') {
        filtered = filtered.where((user) => !user.isActive).toList();
      } else {
        filtered =
            filtered
                .where((user) => user.role.toLowerCase() == role.toLowerCase())
                .toList();
      }
    }

    // Filter by active status
    if (isActive != null) {
      filtered = filtered.where((user) => user.isActive == isActive).toList();
    }

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowercaseQuery = searchQuery.toLowerCase();
      filtered =
          filtered.where((user) {
            return user.name.toLowerCase().contains(lowercaseQuery) ||
                user.email.toLowerCase().contains(lowercaseQuery) ||
                (user.phoneNumber?.toLowerCase().contains(lowercaseQuery) ??
                    false) ||
                (user.department?.toLowerCase().contains(lowercaseQuery) ??
                    false);
          }).toList();
    }

    return filtered;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh users data
  Future<void> refreshUsers() async {
    await loadUsers();
  }

  // Keep old method for backward compatibility but make it deactivate
  Future<bool> deleteUserCompletely(String authUid) async {
    debugPrint(
      'deleteUserCompletely called - redirecting to deactivateUser for: $authUid',
    );
    return await deactivateUser(authUid);
  }

  // Dispose method to clean up resources
  @override
  void dispose() {
    debugPrint('UserManagementViewModel disposed');
    super.dispose();
  }
}
