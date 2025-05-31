// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'universal_photo_service.dart';

class CloudinaryService implements PhotoUploadInterface {
  static CloudinaryService? _instance;
  static CloudinaryService get instance =>
      _instance ??= CloudinaryService._internal();

  // Cloudinary Configuration - Replace with your actual values
  static const String _cloudName = 'duxn4ckur';
  static const String _uploadPreset = 'kony-app-photos';

  late final CloudinaryPublic _cloudinary;

  CloudinaryService._internal() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  @override
  Future<String> uploadPhoto({
    required File imageFile,
    required String reportId,
    required String componentId,
    String? photoId,
    Function(double)? onProgress,
  }) async {
    try {
      photoId ??= const Uuid().v4();

      debugPrint('Starting Cloudinary upload: $photoId');

      // Compress image
      final compressedImage = await _compressImage(imageFile);

      // Create folder structure and public ID
      final folder = 'kony-app/reports/$reportId/components/$componentId';

      // Upload to Cloudinary
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          compressedImage,
          identifier: '$folder/$photoId',
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Check if we got a valid URL back
      if (response.secureUrl.isNotEmpty) {
        debugPrint('Upload successful: ${response.secureUrl}');
        return response.secureUrl;
      } else {
        throw Exception('Upload failed - no URL returned');
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> uploadMultiplePhotos({
    required List<File> imageFiles,
    required String reportId,
    required String componentId,
    Function(int completed, int total)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadPhoto(
          imageFile: imageFiles[i],
          reportId: reportId,
          componentId: componentId,
        );
        uploadedUrls.add(url);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        debugPrint('Failed to upload photo ${i + 1}: $e');
      }
    }

    return uploadedUrls;
  }

  Future<Uint8List> _compressImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large
      if (image.width > 1200 || image.height > 1200) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: 1200);
        } else {
          image = img.copyResize(image, height: 1200);
        }
      }

      final compressedBytes = img.encodeJpg(image, quality: 85);

      debugPrint(
        'Image compressed: ${imageBytes.length} → ${compressedBytes.length} bytes',
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('Compression error: $e');
      return await imageFile.readAsBytes();
    }
  }

  @override
  Future<void> deletePhoto(String photoUrl) async {
    try {
      // Note: cloudinary_public package doesn't support delete operations
      // Delete requires admin API with API secret
      debugPrint('Delete not supported with cloudinary_public package');
      debugPrint('Photo URL: $photoUrl');
    } catch (e) {
      debugPrint('Error in delete operation: $e');
    }
  }

  @override
  Future<void> deleteComponentPhotos({
    required String reportId,
    required String componentId,
  }) async {
    debugPrint('Batch delete not supported with cloudinary_public package');
  }

  @override
  Future<void> deleteReportPhotos(String reportId) async {
    debugPrint('Batch delete not supported with cloudinary_public package');
  }

  /// Get optimized URL with transformations
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      if (!originalUrl.contains('cloudinary.com')) {
        return originalUrl;
      }

      // Extract the path after /upload/
      final uploadIndex = originalUrl.indexOf('/upload/');
      if (uploadIndex == -1) return originalUrl;

      final beforeUpload = originalUrl.substring(0, uploadIndex + 8);
      final afterUpload = originalUrl.substring(uploadIndex + 8);

      // Build transformation string
      final transformations = <String>[];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');

      final transformationString = transformations.join(',');

      return '$beforeUpload$transformationString/$afterUpload';
    } catch (e) {
      debugPrint('Error generating optimized URL: $e');
      return originalUrl;
    }
  }

  /// Generate thumbnail URL
  String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return getOptimizedUrl(
      originalUrl,
      width: size,
      height: size,
      quality: 'auto',
      format: 'auto',
    );
  }
}
