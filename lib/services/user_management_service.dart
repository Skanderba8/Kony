// lib/services/user_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';

class UserManagementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Replace the createUser method in user_management_service.dart with this:

  Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('Creating user invitation: $email');

      // Generate a unique ID for the user
      final userId = _firestore.collection('users').doc().id;

      // Create user document directly in Firestore (NO Firebase Auth yet)
      final userData = {
        'id': 'tech${DateTime.now().millisecondsSinceEpoch}',
        'authUid': userId, // Temporary ID until they create their account
        'name': name,
        'email': email,
        'role': 'technician',
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': '',
        'profilePictureUrl': '',
        'address': '',
        'department': '',
        'isActive': true,
        'accountStatus': 'invitation_pending', // NEW FIELD
        'invitationPassword':
            password, // Store temporarily (encrypt in production)
      };

      // Store in Firestore directly
      await _firestore.collection('users').doc(userId).set(userData);

      debugPrint('User invitation created successfully: $email');

      return UserModel(
        id: userData['id'] as String,
        authUid: userId,
        name: name,
        email: email,
        role: 'technician',
        isActive: true,
      );
    } catch (e) {
      debugPrint('Error creating user invitation: $e');
      rethrow;
    }
  }

  // Add this method to handle when the user logs in for the first time
  Future<bool> completeUserRegistration(String email, String password) async {
    try {
      // Find the user invitation
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .where('accountStatus', isEqualTo: 'invitation_pending')
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // No invitation found
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Check if the password matches
      if (userData['invitationPassword'] != password) {
        return false; // Wrong password
      }

      // NOW create the Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update the user document with the real authUid
        await _firestore.collection('users').doc(userDoc.id).update({
          'authUid': userCredential.user!.uid,
          'accountStatus': 'active',
          'invitationPassword': FieldValue.delete(), // Remove temp password
          'firstLoginAt': FieldValue.serverTimestamp(),
        });

        // Also create a document with the Firebase Auth UID as the document ID
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        // Delete the old document with temp ID
        await _firestore.collection('users').doc(userDoc.id).delete();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error completing user registration: $e');
      return false;
    }
  }

  // BETTER SOLUTION: Use Firebase Functions or Admin SDK
  // Add this method that doesn't affect authentication:

  Future<UserModel?> createUserWithoutAuthSwitch({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('Creating user without auth switch: $email');

      // Method 1: Create user data and send invitation email
      final userId = _firestore.collection('users').doc().id;

      final userData = {
        'id': 'tech${DateTime.now().millisecondsSinceEpoch}',
        'authUid': '', // Will be populated when user first logs in
        'name': name,
        'email': email,
        'role': 'technician',
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': '',
        'profilePictureUrl': '',
        'address': '',
        'department': '',
        'isActive': true,
        'accountStatus': 'invitation_sent',
        'temporaryPassword': password, // Store encrypted in production
      };

      // Store user as "invited" until they complete registration
      await _firestore.collection('user_invitations').doc(userId).set(userData);

      debugPrint('User invitation created: $email');

      return UserModel(
        id: userData['id'] as String,
        authUid: userId,
        name: name,
        email: email,
        role: 'technician',
        isActive: true,
      );
    } catch (e) {
      debugPrint('Error creating user invitation: $e');
      rethrow;
    }
  }

  // Update email with proper validation
  Future<bool> updateEmail(String password, String newEmail) async {
    try {
      // Get current user
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return false;
      }

      final String currentEmail = user.email!;

      // Create credential for reauthentication
      final AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: password,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);

      // Update email in Auth - ADD VERIFICATION STEP
      try {
        await user.verifyBeforeUpdateEmail(newEmail);
        // This sends a verification email to the new address

        // Update email in Firestore immediately
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });

        return true;
      } catch (e) {
        // Fall back to direct update if verification isn't supported or configured
        if (e.toString().contains('not-allowed')) {
          // Update Firebase Auth email directly
          await user.updateEmail(newEmail);

          // Update in Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'email': newEmail,
          });
          return true;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error updating email: $e');
      return false;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(String authUid, File imageFile) async {
    try {
      final String filename = 'profile_$authUid.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child(filename);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String url = await snapshot.ref.getDownloadURL();

      return url;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  // Update user profile info - FIXED VERSION
  Future<bool> updateUserProfile({
    required String authUid,
    String? name,
    String? email,
    String? profilePictureUrl,
    String? phoneNumber,
    String? address,
    String? department,
    File? profilePicture,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      // Handle profile picture upload first if provided
      if (profilePicture != null) {
        final uploadedUrl = await uploadProfilePicture(authUid, profilePicture);
        if (uploadedUrl != null) {
          updateData['profilePictureUrl'] = uploadedUrl;
        }
      } else if (profilePictureUrl != null) {
        updateData['profilePictureUrl'] = profilePictureUrl;
      }

      // Add other fields to update
      if (name != null && name.trim().isNotEmpty)
        updateData['name'] = name.trim();
      if (email != null && email.trim().isNotEmpty)
        updateData['email'] = email.trim();
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber.trim();
      if (address != null) updateData['address'] = address.trim();
      if (department != null) updateData['department'] = department.trim();

      // Only update if there's data to update
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(authUid).update(updateData);
        debugPrint('User profile updated successfully: $updateData');
      }

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Get user by auth UID - UPDATED WITH ISACTIVE
  Future<UserModel?> getUserByAuthUid(String authUid) async {
    try {
      final doc = await _firestore.collection('users').doc(authUid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromJson(data, authUid: authUid);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  // Get all users - UPDATED WITH ISACTIVE
  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromJson(data, authUid: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  // REPLACED deleteUserCompletely with activate/deactivate methods
  Future<bool> activateUser(String authUid) async {
    try {
      await _firestore.collection('users').doc(authUid).update({
        'isActive': true,
      });
      debugPrint('User activated: $authUid');
      return true;
    } catch (e) {
      debugPrint('Error activating user: $e');
      return false;
    }
  }

  Future<bool> deactivateUser(String authUid) async {
    try {
      await _firestore.collection('users').doc(authUid).update({
        'isActive': false,
      });
      debugPrint('User deactivated: $authUid');
      return true;
    } catch (e) {
      debugPrint('Error deactivating user: $e');
      return false;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserActiveStatus(String authUid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(authUid).update({
        'isActive': isActive,
      });
      debugPrint('User status toggled: $authUid -> $isActive');
      return true;
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      return false;
    }
  }

  // Keep the old method for backward compatibility but make it deactivate instead
  Future<bool> deleteUserCompletely(String authUid) async {
    return await deactivateUser(authUid);
  }
}
