// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'universal_photo_service.dart';
import '../utils/cloudinary_config.dart';

class CloudinaryService implements PhotoUploadInterface {
  static CloudinaryService? _instance;
  static CloudinaryService get instance => _instance ??= CloudinaryService._();
  CloudinaryService._();

  @override
  Future<String> uploadPhoto({
    required File imageFile,
    required String reportId,
    required String componentId,
    String? photoId,
    Function(double)? onProgress,
  }) async {
    try {
      // Generate unique photo ID if not provided
      photoId ??= const Uuid().v4();

      debugPrint(
        'Starting Cloudinary upload for report: $reportId, component: $componentId, photo: $photoId',
      );

      // Compress image before upload
      final compressedImage = await _compressImage(imageFile);

      // Create folder path for organization
      final folderPath = CloudinaryConfig.getFolderPath(reportId, componentId);

      // Create public ID with folder structure
      final publicId = '$folderPath/$photoId';

      debugPrint('Cloudinary public ID: $publicId');

      // Prepare upload URL for unsigned upload
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // For UNSIGNED uploads - only use upload_preset
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['public_id'] = publicId;
      request.fields['resource_type'] = 'image';

      // Add metadata
      request.fields['context'] =
          'report_id=$reportId|component_id=$componentId|photo_id=$photoId';

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressedImage,
          filename: '$photoId.jpg',
        ),
      );

      debugPrint('Uploading to Cloudinary with unsigned preset...');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Cloudinary response status: ${response.statusCode}');
      debugPrint('Cloudinary response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String downloadUrl = responseData['secure_url'] as String;

        debugPrint('Cloudinary upload successful. URL: $downloadUrl');
        return downloadUrl;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('Cloudinary upload failed: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error uploading photo to Cloudinary: $e');
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
        debugPrint('Failed to upload photo ${i + 1} to Cloudinary: $e');
        // Continue with other photos
      }
    }

    return uploadedUrls;
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

  @override
  Future<void> deletePhoto(String photoUrl) async {
    try {
      // For unsigned uploads, we cannot delete photos programmatically
      // This would require admin API credentials
      debugPrint(
        'Photo deletion not available with unsigned uploads: $photoUrl',
      );
      debugPrint(
        'Note: Delete photos manually from Cloudinary dashboard if needed',
      );
    } catch (e) {
      debugPrint('Error deleting photo from Cloudinary: $e');
      // Don't rethrow - deletion errors shouldn't block the app
    }
  }

  @override
  Future<void> deleteComponentPhotos({
    required String reportId,
    required String componentId,
  }) async {
    try {
      debugPrint('Batch photo deletion not available with unsigned uploads');
      debugPrint(
        'Component photos for component $componentId not deleted from Cloudinary',
      );
    } catch (e) {
      debugPrint('Error batch deleting photos: $e');
    }
  }

  @override
  Future<void> deleteReportPhotos(String reportId) async {
    try {
      debugPrint('Report photo deletion not available with unsigned uploads');
      debugPrint('Photos for report $reportId not deleted from Cloudinary');
    } catch (e) {
      debugPrint('Error deleting report photos: $e');
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      // Find upload segment and insert transformation
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1) {
        final transformations = <String>[];

        if (width != null) transformations.add('w_$width');
        if (height != null) transformations.add('h_$height');
        transformations.add('q_$quality');
        transformations.add('f_auto');

        if (transformations.isNotEmpty) {
          pathSegments.insert(uploadIndex + 1, transformations.join(','));
        }

        final newUri = uri.replace(pathSegments: pathSegments);
        return newUri.toString();
      }

      return originalUrl;
    } catch (e) {
      return originalUrl;
    }
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return getOptimizedUrl(
      originalUrl,
      width: size,
      height: size,
      quality: 'auto',
    );
  }
}
