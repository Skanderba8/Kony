// lib/models/report_sections/access_trap.dart
import 'package:uuid/uuid.dart';
import '../photo.dart';

/// Model for representing access traps for cable management
class AccessTrap {
  final String id;
  final String location;
  final String trapSize;
  final String notes;
  final List<Photo> photos;

  AccessTrap({
    required this.id,
    required this.location,
    required this.trapSize,
    this.notes = '',
    this.photos = const [],
  });

  /// Factory method to create a new empty access trap entry with a UUID
  factory AccessTrap.create() {
    return AccessTrap(id: const Uuid().v4(), location: '', trapSize: '');
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'trapSize': trapSize,
      'notes': notes,
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }

  /// Create from Firestore data
  factory AccessTrap.fromJson(Map<String, dynamic> json) {
    return AccessTrap(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      trapSize: json['trapSize'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create a copy with some fields updated
  AccessTrap copyWith({
    String? id,
    String? location,
    String? trapSize,
    String? notes,
    List<Photo>? photos,
  }) {
    return AccessTrap(
      id: id ?? this.id,
      location: location ?? this.location,
      trapSize: trapSize ?? this.trapSize,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }

  // Photo management helper methods
  AccessTrap addPhoto(Photo photo) {
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.add(photo);
    return copyWith(photos: updatedPhotos);
  }

  AccessTrap updatePhoto(int index, Photo updatedPhoto) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos[index] = updatedPhoto;
    return copyWith(photos: updatedPhotos);
  }

  AccessTrap removePhoto(int index) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.removeAt(index);
    return copyWith(photos: updatedPhotos);
  }
}
