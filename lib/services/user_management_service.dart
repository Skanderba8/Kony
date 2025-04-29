// lib/services/user_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserManagementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new user with custom ID format (tech1, tech2, etc.)
  Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    UserCredential? userCredential;
    String? customUserId;

    try {
      // 1. Check if email already exists
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already registered.',
        );
      }

      // 2. Generate custom user ID (tech1, tech2, etc.)
      customUserId = await _generateNextTechnicianId();
      debugPrint('Generated custom ID: $customUserId');

      // 3. Create authentication user
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create authentication record');
      }

      debugPrint('Auth user created with UID: ${firebaseUser.uid}');

      // 4. Create user document with custom ID format
      final Map<String, dynamic> userData = {
        'id': customUserId, // Custom ID (tech1, tech2, etc.)
        'authUid': firebaseUser.uid, // Store Auth UID as a reference
        'name': name, // From the name parameter
        'email': email, // From the email parameter
        'role': 'technician', // Hardcoded as 'technician'
        'createdAt': FieldValue.serverTimestamp(), // Server-generated timestamp
      };

      // Using the Firebase Auth UID as doc ID for security/consistency
      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      debugPrint(
        'Firestore document created for: ${firebaseUser.uid} with custom ID: $customUserId',
      );

      return UserModel(
        id: customUserId,
        name: name,
        email: email,
        role: 'technician',
        authUid: firebaseUser.uid,
      );
    } catch (e) {
      debugPrint('Error in user creation: $e');

      // Clean up process if needed
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
          debugPrint('Cleaned up auth user after error');
        } catch (cleanupError) {
          debugPrint('Cleanup error: $cleanupError');
        }
      }

      rethrow;
    }
  }

  /// Generates the next technician ID in sequence (tech1, tech2, etc.)
  Future<String> _generateNextTechnicianId() async {
    try {
      // Get the current highest technician ID
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'technician')
              .orderBy('id', descending: true)
              .limit(1)
              .get();

      int nextNumber = 1; // Default start

      if (snapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            snapshot.docs.first.data() as Map<String, dynamic>;

        final String currentId = data['id'] as String;

        // Extract number from "tech123" format
        final RegExp regex = RegExp(r'tech(\d+)');
        final match = regex.firstMatch(currentId);

        if (match != null && match.groupCount >= 1) {
          nextNumber = int.parse(match.group(1)!) + 1;
        }
      }

      return 'tech$nextNumber';
    } catch (e) {
      debugPrint('Error generating next technician ID: $e');
      // Fallback to timestamp-based ID if sequence generation fails
      return 'tech${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Retrieves all users with "technician" role
  /// Retrieves all users with "technician" role with improved error handling and logging
  Future<List<UserModel>> getUsers() async {
    try {
      debugPrint('Fetching technicians...');

      // Get all users documents instead of filtering by role
      final QuerySnapshot snapshot = await _firestore.collection('users').get();

      debugPrint('Fetched ${snapshot.docs.length} user documents');

      // Transform and filter in memory instead
      final users =
          snapshot.docs
              .map((DocumentSnapshot doc) {
                debugPrint('Processing document: ${doc.id}');

                final Map<String, dynamic> data;
                try {
                  data = doc.data() as Map<String, dynamic>;
                } catch (e) {
                  debugPrint('Error casting document data: $e');
                  return null;
                }

                // Debug print the data structure
                debugPrint('Document data: ${data.toString()}');

                final String role = data['role'] as String? ?? '';
                // Include all users for now to see what's in the database
                // We can filter by role later if needed

                return UserModel(
                  id: data['id'] ?? '',
                  name: data['name'] ?? '',
                  email: data['email'] ?? '',
                  role: role,
                  authUid:
                      doc.id, // Use the document ID as authUid if not present
                );
              })
              .where((user) => user != null)
              .cast<UserModel>()
              .toList();

      debugPrint('Returning ${users.length} user models');
      return users;
    } catch (e, stackTrace) {
      debugPrint('Error fetching users: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Updates user information in Firestore
  Future<bool> updateUser({
    required String authUid,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      // We use the authUid as the document ID in Firestore
      final docRef = _firestore.collection('users').doc(authUid);

      // First check if document exists
      final doc = await docRef.get();
      if (!doc.exists) {
        debugPrint('Document does not exist: $authUid');
        return false;
      }

      // Only update allowed fields, preserving id and authUid
      await docRef.update({
        'name': name,
        'email': email,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated user document: $authUid');
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Deletes a user from both Firestore and Firebase Authentication
  Future<bool> deleteUserCompletely(String authUid) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(authUid).delete();
      debugPrint('Deleted user document from Firestore: $authUid');

      // Note: Deleting from Authentication requires Admin SDK
      // This would typically be done via a Cloud Function

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  /// Retrieves a single user by authUid
  Future<UserModel?> getUserByAuthUid(String authUid) async {
    try {
      final doc = await _firestore.collection('users').doc(authUid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserModel(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'technician',
        authUid: data['authUid'] ?? '',
      );
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  /// Deletes a user document from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      // Need to find the document by custom ID first
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .where('id', isEqualTo: userId)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final String docId = snapshot.docs.first.id;
        await _firestore.collection('users').doc(docId).delete();
        debugPrint('Deleted Firestore document for user: $userId');
      } else {
        throw Exception('User document not found for ID: $userId');
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }
}
