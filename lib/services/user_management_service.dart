// lib/services/user_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/user_model.dart';

class UserManagementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new user with email and password
  Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      final user = userCredential.user!;

      // Create user document in Firestore
      final userData = {
        'id': 'tech${DateTime.now().millisecondsSinceEpoch}',
        'authUid': user.uid,
        'name': name,
        'email': email,
        'role': 'technician',
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': '',
        'profilePictureUrl': '',
        'address': '',
        'department': '',
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      return UserModel(
        id: userData['id'] as String,
        authUid: user.uid,
        name: name,
        email: email,
        role: 'technician',
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // In lib/services/user_management_service.dart
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
          // Just update in Firestore
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

  // Update user profile info
  Future<bool> updateUserProfile({
    required String authUid,
    String? name,
    String? email,
    String? profilePictureUrl,
    String? phoneNumber,
    String? address,
    String? department,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (profilePictureUrl != null)
        updateData['profilePictureUrl'] = profilePictureUrl;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (department != null) updateData['department'] = department;

      await _firestore.collection('users').doc(authUid).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Get user by auth UID
  Future<UserModel?> getUserByAuthUid(String authUid) async {
    try {
      final doc = await _firestore.collection('users').doc(authUid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserModel(
        id: data['id'] ?? '',
        authUid: data['authUid'] ?? authUid,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'technician',
        profilePictureUrl: data['profilePictureUrl'],
        phoneNumber: data['phoneNumber'],
        address: data['address'],
        department: data['department'],
      );
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  // Get all users
  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return UserModel(
          id: data['id'] ?? '',
          authUid: data['authUid'] ?? doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'technician',
          profilePictureUrl: data['profilePictureUrl'],
          phoneNumber: data['phoneNumber'],
          address: data['address'],
          department: data['department'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  // Delete user
  Future<bool> deleteUserCompletely(String authUid) async {
    try {
      await _firestore.collection('users').doc(authUid).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }
}
