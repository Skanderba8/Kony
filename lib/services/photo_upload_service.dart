// lib/services/photo_upload_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class PhotoUploadService {
  static PhotoUploadService? _instance;
  static PhotoUploadService get instance =>
      _instance ??= PhotoUploadService._();
  PhotoUploadService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload photo to Firebase Storage and return the download URL
  Future<String> uploadPhoto({
    required File imageFile,
    required String reportId,
    required String componentId,
    String? photoId,
  }) async {
    try {
      // Generate unique photo ID if not provided
      photoId ??= const Uuid().v4();

      debugPrint(
        'Starting photo upload for report: $reportId, component: $componentId, photo: $photoId',
      );

      // Compress image before upload
      final compressedImage = await _compressImage(imageFile);

      // Create storage path: reports/{reportId}/components/{componentId}/photos/{photoId}.jpg
      final fileName = '$photoId.jpg';
      final storagePath =
          'reports/$reportId/components/$componentId/photos/$fileName';

      debugPrint('Storage path: $storagePath');

      // Create reference to Firebase Storage
      final Reference storageRef = _storage.ref().child(storagePath);

      // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'reportId': reportId,
          'componentId': componentId,
          'photoId': photoId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      debugPrint(
        'Uploading compressed image (${compressedImage.length} bytes)',
      );
      final UploadTask uploadTask = storageRef.putData(
        compressedImage,
        metadata,
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final String downloadUrl = await storageRef.getDownloadURL();
        debugPrint('Photo uploaded successfully. URL: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Compress image to reduce file size while maintaining quality
  Future<Uint8List> _compressImage(File imageFile) async {
    try {
      // Read image file
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large (max 1200px on longest side)
      if (image.width > 1200 || image.height > 1200) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: 1200);
        } else {
          image = img.copyResize(image, height: 1200);
        }
      }

      // Encode as JPEG with 85% quality
      final List<int> compressedBytes = img.encodeJpg(image, quality: 85);

      debugPrint(
        'Image compressed: ${imageBytes.length} bytes → ${compressedBytes.length} bytes',
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // If compression fails, return original bytes
      return await imageFile.readAsBytes();
    }
  }

  /// Delete photo from Firebase Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final Reference photoRef = _storage.refFromURL(photoUrl);
      await photoRef.delete();
      debugPrint('Photo deleted successfully: $photoUrl');
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      // Don't rethrow - deletion errors shouldn't block the app
    }
  }

  /// Get metadata for a photo
  Future<FullMetadata?> getPhotoMetadata(String photoUrl) async {
    try {
      final Reference photoRef = _storage.refFromURL(photoUrl);
      return await photoRef.getMetadata();
    } catch (e) {
      debugPrint('Error getting photo metadata: $e');
      return null;
    }
  }

  /// Batch delete photos for a component
  Future<void> deleteComponentPhotos({
    required String reportId,
    required String componentId,
  }) async {
    try {
      final String folderPath =
          'reports/$reportId/components/$componentId/photos/';
      final Reference folderRef = _storage.ref().child(folderPath);

      final ListResult result = await folderRef.listAll();

      for (final Reference photoRef in result.items) {
        await photoRef.delete();
      }

      debugPrint(
        'Deleted ${result.items.length} photos for component $componentId',
      );
    } catch (e) {
      debugPrint('Error batch deleting photos: $e');
    }
  }

  /// Batch delete all photos for a report
  Future<void> deleteReportPhotos(String reportId) async {
    try {
      final String folderPath = 'reports/$reportId/';
      final Reference folderRef = _storage.ref().child(folderPath);

      final ListResult result = await folderRef.listAll();

      // Delete all files in the report folder
      for (final Reference item in result.items) {
        await item.delete();
      }

      // Recursively delete subfolders
      for (final Reference prefix in result.prefixes) {
        await _deleteFolder(prefix);
      }

      debugPrint('Deleted all photos for report $reportId');
    } catch (e) {
      debugPrint('Error deleting report photos: $e');
    }
  }

  /// Helper method to recursively delete folders
  Future<void> _deleteFolder(Reference folderRef) async {
    final ListResult result = await folderRef.listAll();

    for (final Reference item in result.items) {
      await item.delete();
    }

    for (final Reference prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }
  }
}
