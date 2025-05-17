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
      await _service.createUser(email: email, password: password, name: name);
      await loadUsers();
      return true;
    } catch (e) {
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
      _users = await _service.getUsers();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
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
      String? profilePictureUrl;

      if (profilePicture != null) {
        profilePictureUrl = await _service.uploadProfilePicture(
          authUid,
          profilePicture,
        );

        if (profilePictureUrl == null) {
          _errorMessage = 'Échec de l\'upload de l\'image';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final success = await _service.updateUserProfile(
        authUid: authUid,
        name: name,
        email: email,
        profilePictureUrl: profilePictureUrl,
        phoneNumber: phoneNumber,
        address: address,
        department: department,
      );

      if (!success) {
        _errorMessage = 'Échec de la mise à jour du profil';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update email
  Future<bool> updateEmail(String password, String newEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.updateEmail(password, newEmail);

      if (!success) {
        _errorMessage = 'La mise à jour de l\'email a échoué';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete user completely
  Future<bool> deleteUserCompletely(String authUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.deleteUserCompletely(authUid);

      if (success) {
        await loadUsers();
      } else {
        _errorMessage = 'Échec de la suppression de l\'utilisateur';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
