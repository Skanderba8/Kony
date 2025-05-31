// lib/models/report_sections/fiber_optic_cabling.dart
import 'package:uuid/uuid.dart';
import '../photo.dart';

/// Model for representing fiber optic network cabling
class FiberOpticCabling {
  final String id;
  final String location;
  final int drawerCount;
  final String fiberType;
  final int conduitCount;
  final double lengthInMeters;
  final bool isInterior;
  final double workHeight;
  final String notes;
  final List<Photo> photos;

  FiberOpticCabling({
    required this.id,
    required this.location,
    required this.drawerCount,
    required this.fiberType,
    required this.conduitCount,
    required this.lengthInMeters,
    required this.isInterior,
    required this.workHeight,
    this.notes = '',
    this.photos = const [],
  });

  /// Factory method to create a new empty fiber optic cabling entry with a UUID
  factory FiberOpticCabling.create() {
    return FiberOpticCabling(
      id: const Uuid().v4(),
      location: '',
      drawerCount: 0,
      fiberType: '',
      conduitCount: 0,
      lengthInMeters: 0.0,
      isInterior: true,
      workHeight: 0.0,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'drawerCount': drawerCount,
      'fiberType': fiberType,
      'conduitCount': conduitCount,
      'lengthInMeters': lengthInMeters,
      'isInterior': isInterior,
      'workHeight': workHeight,
      'notes': notes,
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }

  /// Create from Firestore data
  factory FiberOpticCabling.fromJson(Map<String, dynamic> json) {
    return FiberOpticCabling(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      drawerCount: json['drawerCount'] as int? ?? 0,
      fiberType: json['fiberType'] as String? ?? '',
      conduitCount: json['conduitCount'] as int? ?? 0,
      lengthInMeters: (json['lengthInMeters'] as num?)?.toDouble() ?? 0.0,
      isInterior: json['isInterior'] as bool? ?? true,
      workHeight: (json['workHeight'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create a copy with some fields updated
  FiberOpticCabling copyWith({
    String? id,
    String? location,
    int? drawerCount,
    String? fiberType,
    int? conduitCount,
    double? lengthInMeters,
    bool? isInterior,
    double? workHeight,
    String? notes,
    List<Photo>? photos,
  }) {
    return FiberOpticCabling(
      id: id ?? this.id,
      location: location ?? this.location,
      drawerCount: drawerCount ?? this.drawerCount,
      fiberType: fiberType ?? this.fiberType,
      conduitCount: conduitCount ?? this.conduitCount,
      lengthInMeters: lengthInMeters ?? this.lengthInMeters,
      isInterior: isInterior ?? this.isInterior,
      workHeight: workHeight ?? this.workHeight,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }

  // Photo management helper methods
  FiberOpticCabling addPhoto(Photo photo) {
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.add(photo);
    return copyWith(photos: updatedPhotos);
  }

  FiberOpticCabling updatePhoto(int index, Photo updatedPhoto) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos[index] = updatedPhoto;
    return copyWith(photos: updatedPhotos);
  }

  FiberOpticCabling removePhoto(int index) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.removeAt(index);
    return copyWith(photos: updatedPhotos);
  }
}
