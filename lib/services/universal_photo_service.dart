// lib/services/universal_photo_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kony/services/cloudinary_service.dart';
import 'package:kony/services/photo_upload_service.dart';

/// Enumeration of available photo storage services
enum PhotoStorageService { firebase, cloudinary, awsS3 }

/// Abstract interface for photo upload services
abstract class PhotoUploadInterface {
  Future<String> uploadPhoto({
    required File imageFile,
    required String reportId,
    required String componentId,
    String? photoId,
    Function(double)? onProgress,
  });

  Future<void> deletePhoto(String photoUrl);

  Future<void> deleteComponentPhotos({
    required String reportId,
    required String componentId,
  });

  Future<void> deleteReportPhotos(String reportId);

  Future<List<String>> uploadMultiplePhotos({
    required List<File> imageFiles,
    required String reportId,
    required String componentId,
    Function(int completed, int total)? onProgress,
  });
}

/// Universal photo service that can switch between different storage providers
class UniversalPhotoService implements PhotoUploadInterface {
  static UniversalPhotoService? _instance;
  static UniversalPhotoService get instance =>
      _instance ??= UniversalPhotoService._();
  UniversalPhotoService._();

  // Current storage service being used
  PhotoStorageService _currentService = PhotoStorageService.cloudinary;

  // Service instances
  late PhotoUploadInterface _activeService;

  /// Initialize the service with the preferred storage provider
  void initialize({
    PhotoStorageService service = PhotoStorageService.cloudinary,
  }) {
    _currentService = service;

    switch (_currentService) {
      case PhotoStorageService.cloudinary:
        // Import your cloudinary service
        _activeService = CloudinaryService.instance;
        break;
      case PhotoStorageService.firebase:
        // Import your firebase service
        _activeService = PhotoUploadService.instance;
        break;
      case PhotoStorageService.awsS3:
        // Import your AWS S3 service
        // _activeService = AwsS3Service.instance;
        throw UnimplementedError('AWS S3 service not implemented yet');
    }

    debugPrint('Universal Photo Service initialized with: $_currentService');
  }

  /// Get the current service being used
  PhotoStorageService get currentService => _currentService;

  /// Switch to a different storage service
  void switchService(PhotoStorageService newService) {
    initialize(service: newService);
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
      return await _activeService.uploadPhoto(
        imageFile: imageFile,
        reportId: reportId,
        componentId: componentId,
        photoId: photoId,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Universal Photo Service upload error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePhoto(String photoUrl) async {
    try {
      await _activeService.deletePhoto(photoUrl);
    } catch (e) {
      debugPrint('Universal Photo Service delete error: $e');
      // Don't rethrow for delete operations
    }
  }

  @override
  Future<void> deleteComponentPhotos({
    required String reportId,
    required String componentId,
  }) async {
    try {
      await _activeService.deleteComponentPhotos(
        reportId: reportId,
        componentId: componentId,
      );
    } catch (e) {
      debugPrint('Universal Photo Service batch delete error: $e');
    }
  }

  @override
  Future<void> deleteReportPhotos(String reportId) async {
    try {
      await _activeService.deleteReportPhotos(reportId);
    } catch (e) {
      debugPrint('Universal Photo Service report delete error: $e');
    }
  }

  @override
  Future<List<String>> uploadMultiplePhotos({
    required List<File> imageFiles,
    required String reportId,
    required String componentId,
    Function(int completed, int total)? onProgress,
  }) async {
    try {
      return await _activeService.uploadMultiplePhotos(
        imageFiles: imageFiles,
        reportId: reportId,
        componentId: componentId,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Universal Photo Service batch upload error: $e');
      return [];
    }
  }

  /// Get optimized image URL (only available for Cloudinary)
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    if (_currentService == PhotoStorageService.cloudinary) {
      final cloudinaryService = _activeService as CloudinaryService;
      return cloudinaryService.getOptimizedUrl(
        originalUrl,
        width: width,
        height: height,
        quality: quality,
      );
    }
    return originalUrl;
  }

  /// Get thumbnail URL (only available for Cloudinary)
  String getThumbnailUrl(String originalUrl, {int size = 150}) {
    if (_currentService == PhotoStorageService.cloudinary) {
      final cloudinaryService = _activeService as CloudinaryService;
      return cloudinaryService.getThumbnailUrl(originalUrl, size: size);
    }
    return originalUrl;
  }
}
