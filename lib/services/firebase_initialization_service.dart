// lib/services/firebase_initialization_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize required Firestore collections with placeholder documents
  Future<void> initializeFirestoreCollections() async {
    try {
      // List of collections to ensure exist
      final collections = ['reports', 'technical_visit_reports', 'users'];

      for (final collection in collections) {
        // Check if collection exists by trying to get a document
        final querySnapshot =
            await _firestore.collection(collection).limit(1).get();

        // If collection is empty, create a placeholder document to ensure it exists
        if (querySnapshot.docs.isEmpty) {
          final placeholderId =
              'placeholder_${DateTime.now().millisecondsSinceEpoch}';
          await _firestore.collection(collection).doc(placeholderId).set({
            'placeholder': true,
            'created_at': FieldValue.serverTimestamp(),
            'description':
                'This document ensures the $collection collection exists',
          });
          debugPrint('Created placeholder for $collection collection');
        } else {
          debugPrint('Collection $collection already exists');
        }
      }

      debugPrint('Firestore collections initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firestore collections: $e');
      rethrow;
    }
  }
}
