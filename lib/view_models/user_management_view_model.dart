// lib/view_models/user_management_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
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
      _errorMessage = 'Une erreur inattendue est survenue: $e';
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
      _errorMessage = 'Erreur lors du chargement des utilisateurs: $e';
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
      _errorMessage = 'Erreur lors de la suppression de l\'utilisateur: $e';
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
      _errorMessage = 'Erreur lors de la récupération de l\'utilisateur: $e';
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
        _errorMessage = 'Échec de la mise à jour de l\'utilisateur';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de l\'utilisateur: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile including profile picture
  Future<bool> updateUserProfile({
    required String authUid,
    String? name,
    String? email,
    File? profilePicture,
    String? phoneNumber,
    String? address,
    String? department,
    Map<String, dynamic>? additionalInfo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? profilePictureUrl;

      // Upload profile picture if provided
      if (profilePicture != null) {
        profilePictureUrl = await _service.uploadProfilePicture(
          authUid,
          profilePicture,
        );
        if (profilePictureUrl == null) {
          _errorMessage = 'Échec de l\'upload de l\'image de profil';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Update user profile
      final success = await _service.updateUserProfile(
        authUid: authUid,
        name: name,
        email: email,
        profilePictureUrl: profilePictureUrl,
        phoneNumber: phoneNumber,
        address: address,
        department: department,
        additionalInfo: additionalInfo,
      );

      if (success) {
        await loadUsers();
      } else {
        _errorMessage = 'Échec de la mise à jour du profil';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du profil: $e';
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
        _errorMessage = 'Échec de la suppression complète de l\'utilisateur';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de l\'utilisateur: $e';
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
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      default:
        return e.message ?? 'Erreur d\'authentification';
    }
  }
}
