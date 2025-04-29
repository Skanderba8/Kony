// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      debugPrint('AuthService: Attempting to sign in with email: $email');
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService: Authentication error: ${e.message} (code: ${e.code})',
      );
      rethrow; // Propagate the error to be handled by the view model
    } catch (e) {
      debugPrint('AuthService: Unexpected error during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get user role from Firestore with improved error handling
  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint(
          'AuthService: No authenticated user found when fetching role',
        );
        return null;
      }

      debugPrint('AuthService: Fetching role for user: ${user.uid}');

      // Try to get the user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        debugPrint('AuthService: User document does not exist in Firestore');

        // Fall back to querying by custom ID field if direct lookup fails
        debugPrint(
          'AuthService: Attempting to find user document by querying "authUid" field',
        );
        final querySnapshot =
            await _firestore
                .collection('users')
                .where('authUid', isEqualTo: user.uid)
                .limit(1)
                .get();

        if (querySnapshot.docs.isEmpty) {
          debugPrint(
            'AuthService: No user document found with authUid: ${user.uid}',
          );
          return null;
        }

        final data = querySnapshot.docs.first.data();
        debugPrint(
          'AuthService: Found user document by query. Role: ${data['role']}',
        );
        return data['role'] as String?;
      }

      // Normal document fetch succeeded
      final data = userDoc.data();
      if (data == null) {
        debugPrint('AuthService: User document exists but data is null');
        return null;
      }

      debugPrint('AuthService: User role from document: ${data['role']}');
      return data['role'] as String?;
    } on FirebaseException catch (e) {
      debugPrint(
        'AuthService: Firestore error getting user role: ${e.code} - ${e.message}',
      );
      // Handle specific Firestore errors
      if (e.code == 'permission-denied') {
        debugPrint(
          'AuthService: Permission denied accessing user document. Check Firestore rules.',
        );
      }
      return null;
    } catch (e) {
      debugPrint('AuthService: Unexpected error getting user role: $e');
      return null;
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
}
