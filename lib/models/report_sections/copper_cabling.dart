// lib/models/report_sections/copper_cabling.dart
import 'package:uuid/uuid.dart';
import '../photo.dart';

/// Model for representing copper network cabling
class CopperCabling {
  final String id;
  final String location;
  final String pathDescription;
  final String category; // e.g., 'Cat6', 'Cat6A', 'Cat7', etc.
  final double lengthInMeters;
  final bool isInterior;
  final double workHeight;
  final String notes;
  final List<Photo> photos;

  CopperCabling({
    required this.id,
    required this.location,
    required this.pathDescription,
    required this.category,
    required this.lengthInMeters,
    required this.isInterior,
    required this.workHeight,
    this.notes = '',
    this.photos = const [],
  });

  /// Factory method to create a new empty copper cabling entry with a UUID
  factory CopperCabling.create() {
    return CopperCabling(
      id: const Uuid().v4(),
      location: '',
      pathDescription: '',
      category: 'Cat6',
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
      'pathDescription': pathDescription,
      'category': category,
      'lengthInMeters': lengthInMeters,
      'isInterior': isInterior,
      'workHeight': workHeight,
      'notes': notes,
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }

  /// Create from Firestore data
  factory CopperCabling.fromJson(Map<String, dynamic> json) {
    return CopperCabling(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      pathDescription: json['pathDescription'] as String? ?? '',
      category: json['category'] as String? ?? 'Cat6',
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
  CopperCabling copyWith({
    String? id,
    String? location,
    String? pathDescription,
    String? category,
    double? lengthInMeters,
    bool? isInterior,
    double? workHeight,
    String? notes,
    List<Photo>? photos,
  }) {
    return CopperCabling(
      id: id ?? this.id,
      location: location ?? this.location,
      pathDescription: pathDescription ?? this.pathDescription,
      category: category ?? this.category,
      lengthInMeters: lengthInMeters ?? this.lengthInMeters,
      isInterior: isInterior ?? this.isInterior,
      workHeight: workHeight ?? this.workHeight,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }

  // Photo management helper methods
  CopperCabling addPhoto(Photo photo) {
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.add(photo);
    return copyWith(photos: updatedPhotos);
  }

  CopperCabling updatePhoto(int index, Photo updatedPhoto) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos[index] = updatedPhoto;
    return copyWith(photos: updatedPhotos);
  }

  CopperCabling removePhoto(int index) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.removeAt(index);
    return copyWith(photos: updatedPhotos);
  }
}
