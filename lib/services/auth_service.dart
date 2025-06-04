// lib/services/auth_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Session management
  Timer? _sessionTimer;
  DateTime? _lastActivity;
  static const Duration _sessionTimeout = Duration(hours: 4);
  static const Duration _warningTime = Duration(minutes: 15);

  // Current user state
  User? _currentUser;
  UserModel? _currentUserModel;
  bool _isSessionValid = false;

  // Session warning callback
  Function()? onSessionWarning;
  Function()? onSessionExpired;

  AuthService() {
    _initializeAuthService();
  }

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isAuthenticated => _currentUser != null && _isSessionValid;
  bool get isSessionValid => _isSessionValid;

  /// Initialize the authentication service
  Future<void> _initializeAuthService() async {
    try {
      // Listen to auth state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Check if user was previously logged in
      await _checkExistingSession();

      debugPrint('Auth service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;

    if (user != null) {
      // User is signed in, load their profile and start session
      await _loadUserProfile(user.uid);
      _startSessionTimer();
    } else {
      // User is signed out, clear session
      await _clearSession();
    }

    notifyListeners();
  }

  /// Check for existing valid session
  Future<void> _checkExistingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString('last_activity');
      final sessionStartString = prefs.getString('session_start');
      final storedUserId = prefs.getString('stored_user_id');
      final keepLoggedIn = prefs.getBool('keep_logged_in') ?? false;

      if (lastActivityString != null && sessionStartString != null) {
        final lastActivity = DateTime.parse(lastActivityString);
        final now = DateTime.now();

        // Check if session is still valid (within 4 hours of last activity)
        // OR if user chose to stay logged in permanently
        if (keepLoggedIn || now.difference(lastActivity) < _sessionTimeout) {
          _lastActivity = lastActivity;
          _isSessionValid = true;

          // If user is still logged in to Firebase but we have stored session
          if (_auth.currentUser != null) {
            await _loadUserProfile(_auth.currentUser!.uid);
            _startSessionTimer();
            debugPrint('Existing session restored for logged-in user');
          } else if (storedUserId != null && keepLoggedIn) {
            // User chose to stay logged in but Firebase session expired
            // We need to handle this by showing login screen but with stored email
            debugPrint(
              'Firebase session expired but user chose to stay logged in',
            );
            await _clearStoredSession();
          } else {
            debugPrint(
              'Session restored but no Firebase user, clearing session',
            );
            await _clearStoredSession();
          }
        } else {
          // Session expired, clear it
          await _clearStoredSession();
          debugPrint('Stored session expired, cleared');
        }
      }
    } catch (e) {
      debugPrint('Error checking existing session: $e');
      await _clearStoredSession();
    }
  }

  // Update the signInWithEmailAndPassword method in auth_service.dart to handle invitations:

  /// Sign in with email and password - UPDATED TO HANDLE INVITATIONS
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool keepLoggedIn = false,
  }) async {
    try {
      debugPrint('Attempting sign in for: $email');

      // FIRST: Try normal Firebase Auth login
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (credential.user != null) {
          // Load user profile
          final userModel = await _loadUserProfile(credential.user!.uid);

          if (userModel != null) {
            // CHECK IF USER IS ACTIVE
            if (!userModel.isActive) {
              await _auth.signOut();
              throw FirebaseAuthException(
                code: 'user-disabled',
                message:
                    'Votre compte a été désactivé. Contactez l\'administrateur.',
              );
            }

            // Start new session
            await _startNewSession(keepLoggedIn: keepLoggedIn);
            debugPrint('Sign in successful for: $email');
            return userModel;
          }
        }
      } on FirebaseAuthException catch (e) {
        // If user-not-found, check if they have an invitation
        if (e.code == 'user-not-found') {
          debugPrint(
            'User not found in Firebase Auth, checking for invitation: $email',
          );

          // Check if user has a pending invitation
          final querySnapshot =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: email.trim())
                  .where('accountStatus', isEqualTo: 'invitation_pending')
                  .limit(1)
                  .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userDoc = querySnapshot.docs.first;
            final userData = userDoc.data();

            // Check if the password matches the invitation password
            if (userData['invitationPassword'] == password) {
              debugPrint(
                'Valid invitation found, creating Firebase Auth account for: $email',
              );

              // Create Firebase Auth account for the invited user
              final newCredential = await _auth.createUserWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );

              if (newCredential.user != null) {
                // Update the user document with the real Firebase Auth UID
                final updatedUserData = {
                  ...userData,
                  'authUid': newCredential.user!.uid,
                  'accountStatus': 'active',
                  'firstLoginAt': FieldValue.serverTimestamp(),
                };

                // Remove the temporary password
                updatedUserData.remove('invitationPassword');

                // Create new document with Firebase Auth UID as document ID
                await _firestore
                    .collection('users')
                    .doc(newCredential.user!.uid)
                    .set(updatedUserData);

                // Delete the old document with temporary ID
                await _firestore.collection('users').doc(userDoc.id).delete();

                // Load the user profile with the new UID
                final userModel = await _loadUserProfile(
                  newCredential.user!.uid,
                );

                if (userModel != null) {
                  // Start new session
                  await _startNewSession(keepLoggedIn: keepLoggedIn);
                  debugPrint('First login successful for invited user: $email');
                  return userModel;
                }
              }
            } else {
              debugPrint('Invalid invitation password for: $email');
              throw FirebaseAuthException(
                code: 'wrong-password',
                message: 'Mot de passe incorrect.',
              );
            }
          }
        }

        // Re-throw the original exception if not handled above
        rethrow;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Also add this helper method to check if an email has a pending invitation
  Future<bool> hasUserInvitation(String email) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .where('accountStatus', isEqualTo: 'invitation_pending')
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user invitation: $e');
      return false;
    }
  }

  /// Load user profile from Firestore
  Future<UserModel?> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final userData = doc.data()!;
        _currentUserModel = UserModel.fromJson(userData, authUid: uid);

        // Update last login timestamp
        await _updateLastLogin(uid);

        debugPrint('User profile loaded: ${_currentUserModel?.email}');
        return _currentUserModel;
      }

      debugPrint('User profile not found for UID: $uid');
      return null;
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return null;
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  /// Start a new session
  Future<void> _startNewSession({bool keepLoggedIn = false}) async {
    final now = DateTime.now();
    _lastActivity = now;
    _isSessionValid = true;

    // Store session info
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_start', now.toIso8601String());
    await prefs.setString('last_activity', now.toIso8601String());
    await prefs.setBool('keep_logged_in', keepLoggedIn);

    // Store minimal user info for persistence
    if (_currentUser != null) {
      await prefs.setString('stored_user_id', _currentUser!.uid);
      await prefs.setString('stored_user_email', _currentUser!.email ?? '');
    }

    if (!keepLoggedIn) {
      _startSessionTimer();
    }

    debugPrint('New session started (keepLoggedIn: $keepLoggedIn)');
  }

  /// Start session timer for automatic timeout
  void _startSessionTimer() {
    _sessionTimer?.cancel();

    // Check if user chose to stay logged in permanently
    SharedPreferences.getInstance().then((prefs) {
      final keepLoggedIn = prefs.getBool('keep_logged_in') ?? false;
      if (keepLoggedIn) {
        debugPrint(
          'User chose to stay logged in permanently, no session timer',
        );
        return;
      }

      // Calculate time until session expires
      final now = DateTime.now();
      final sessionExpiry = (_lastActivity ?? now).add(_sessionTimeout);
      final timeUntilExpiry = sessionExpiry.difference(now);

      if (timeUntilExpiry.isNegative) {
        // Session already expired
        _handleSessionExpired();
        return;
      }

      // Set timer for session expiry
      _sessionTimer = Timer(timeUntilExpiry, _handleSessionExpired);

      // Set warning timer (15 minutes before expiry)
      final warningTime = timeUntilExpiry - _warningTime;
      if (warningTime.isNegative == false) {
        Timer(warningTime, _handleSessionWarning);
      }

      debugPrint(
        'Session timer started, expires in: ${timeUntilExpiry.inMinutes} minutes',
      );
    });
  }

  /// Handle session warning (15 minutes before expiry)
  void _handleSessionWarning() {
    debugPrint('Session warning: 15 minutes until expiry');
    onSessionWarning?.call();
  }

  /// Handle session expiry
  void _handleSessionExpired() {
    debugPrint('Session expired');
    _isSessionValid = false;
    onSessionExpired?.call();
    signOut();
  }

  /// Update last activity timestamp (call this on user interactions)
  Future<void> updateActivity() async {
    if (!_isSessionValid) return;

    final now = DateTime.now();
    _lastActivity = now;

    // Update stored timestamp
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_activity', now.toIso8601String());

      // Restart session timer with fresh timeout
      _startSessionTimer();
    } catch (e) {
      debugPrint('Error updating activity: $e');
    }
  }

  /// Extend session (call when user chooses to stay logged in)
  Future<void> extendSession() async {
    if (_currentUser != null) {
      await _startNewSession(keepLoggedIn: false);
      debugPrint('Session extended for 4 more hours');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint('Signing out user');

      // Cancel session timer
      _sessionTimer?.cancel();

      // Clear session data
      await _clearSession();

      // Sign out from Firebase
      await _auth.signOut();

      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Clear local state even if Firebase signout fails
      await _clearSession();
    }
  }

  /// Clear session data
  Future<void> _clearSession() async {
    _currentUser = null;
    _currentUserModel = null;
    _isSessionValid = false;
    _lastActivity = null;
    _sessionTimer?.cancel();

    await _clearStoredSession();
    notifyListeners();
  }

  /// Clear stored session data
  Future<void> _clearStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_start');
      await prefs.remove('last_activity');
      await prefs.remove('keep_logged_in');
      await prefs.remove('stored_user_id');
      await prefs.remove('stored_user_email');
    } catch (e) {
      debugPrint('Error clearing stored session: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    if (_currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      await _currentUser!.updatePassword(newPassword);
      debugPrint('Password updated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password update error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    if (_currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      // Update in Firestore using the UserModel's toJson method
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updatedUser.toJson());

      // Update local state
      _currentUserModel = updatedUser;
      notifyListeners();

      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Create a new user account (admin function)
  Future<UserModel?> createUserAccount({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? address,
    String? department,
    required String role,
  }) async {
    try {
      // Create the user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Create user profile in Firestore
        final newUser = UserModel(
          id: credential.user!.uid,
          authUid: credential.user!.uid,
          email: email.trim(),
          name: name,
          phoneNumber: phoneNumber,
          address: address,
          department: department,
          role: role,
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toJson());

        debugPrint('User account created successfully: $email');
        return newUser;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error creating user account: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error creating user account: $e');
      rethrow;
    }
  }

  /// Toggle user active status (NEW METHOD)
  Future<void> toggleUserActiveStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
      });
      debugPrint('User active status updated: $uid -> $isActive');
    } catch (e) {
      debugPrint('Error updating user active status: $e');
      rethrow;
    }
  }

  /// Get all users (admin function)
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson(data, authUid: doc.id);
          }).toList();
        });
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return UserModel.fromJson(data, authUid: uid);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Add these methods to your auth_service.dart after the existing methods

  /// Verify current user's password by attempting reauthentication
  Future<bool> verifyCurrentPassword(String currentPassword) async {
    try {
      if (_currentUser == null || _currentUser!.email == null) {
        throw Exception('No authenticated user or email');
      }

      // Create credential for reauthentication
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );

      // Attempt to reauthenticate
      await _currentUser!.reauthenticateWithCredential(credential);
      debugPrint('Password verification successful');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Password verification failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error verifying password: $e');
      return false;
    }
  }

  /// Send password reset email for the currently authenticated user
  Future<void> sendPasswordResetEmailForCurrentUser() async {
    try {
      if (_currentUser == null || _currentUser!.email == null) {
        throw Exception('No authenticated user or email');
      }

      await _auth.sendPasswordResetEmail(email: _currentUser!.email!);
      debugPrint(
        'Password reset email sent to current user: ${_currentUser!.email}',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Password reset error for current user: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error sending password reset email for current user: $e');
      rethrow;
    }
  }

  /// Change password flow: verify current password then send reset email
  Future<bool> initiatePasswordChange(String currentPassword) async {
    try {
      // First verify the current password
      final isPasswordValid = await verifyCurrentPassword(currentPassword);

      if (!isPasswordValid) {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Le mot de passe actuel est incorrect.',
        );
      }

      // If password is valid, send reset email
      await sendPasswordResetEmailForCurrentUser();
      debugPrint('Password change initiated successfully');
      return true;
    } catch (e) {
      debugPrint('Error initiating password change: $e');
      rethrow;
    }
  }

  /// Get session remaining time
  Duration? getSessionRemainingTime() {
    if (_lastActivity == null || !_isSessionValid) return null;

    final expiry = _lastActivity!.add(_sessionTimeout);
    final remaining = expiry.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if session is about to expire (within warning time)
  bool isSessionNearExpiry() {
    final remaining = getSessionRemainingTime();
    return remaining != null && remaining <= _warningTime;
  }

  /// Get current user's role
  String? getUserRole() {
    return _currentUserModel?.role;
  }

  /// Check if current user is admin
  bool isAdmin() {
    return _currentUserModel?.isAdmin ?? false;
  }

  /// Check if current user is technician
  bool isTechnician() {
    return _currentUserModel?.isTechnician ?? false;
  }

  /// Get current user's display name
  String? getUserDisplayName() {
    return _currentUserModel?.displayName;
  }

  /// Get current user's email
  String? getUserEmail() {
    return _currentUserModel?.email ?? _currentUser?.email;
  }

  /// Get current user's ID
  String? getUserId() {
    return _currentUserModel?.id ?? _currentUser?.uid;
  }

  /// Get current user's auth UID
  String? getUserAuthUid() {
    return _currentUserModel?.authUid ?? _currentUser?.uid;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
