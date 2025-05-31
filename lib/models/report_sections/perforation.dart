// lib/models/report_sections/perforation.dart
import 'package:uuid/uuid.dart';
import '../photo.dart';

/// Model for representing wall perforations needed for cable passage
class Perforation {
  final String id;
  final String location;
  final String wallType;
  final double wallDepth;
  final String wallSounding;
  final String perforationAccess;
  final String perforationConstraints;
  final String notes;
  final List<Photo> photos;

  Perforation({
    required this.id,
    required this.location,
    required this.wallType,
    required this.wallDepth,
    required this.wallSounding,
    required this.perforationAccess,
    required this.perforationConstraints,
    this.notes = '',
    this.photos = const [],
  });

  /// Factory method to create a new empty perforation entry with a UUID
  factory Perforation.create() {
    return Perforation(
      id: const Uuid().v4(),
      location: '',
      wallType: '',
      wallDepth: 0.0,
      wallSounding: '',
      perforationAccess: '',
      perforationConstraints: '',
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'wallType': wallType,
      'wallDepth': wallDepth,
      'wallSounding': wallSounding,
      'perforationAccess': perforationAccess,
      'perforationConstraints': perforationConstraints,
      'notes': notes,
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }

  /// Create from Firestore data
  factory Perforation.fromJson(Map<String, dynamic> json) {
    return Perforation(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      wallType: json['wallType'] as String? ?? '',
      wallDepth: (json['wallDepth'] as num?)?.toDouble() ?? 0.0,
      wallSounding: json['wallSounding'] as String? ?? '',
      perforationAccess: json['perforationAccess'] as String? ?? '',
      perforationConstraints: json['perforationConstraints'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create a copy with some fields updated
  Perforation copyWith({
    String? id,
    String? location,
    String? wallType,
    double? wallDepth,
    String? wallSounding,
    String? perforationAccess,
    String? perforationConstraints,
    String? notes,
    List<Photo>? photos,
  }) {
    return Perforation(
      id: id ?? this.id,
      location: location ?? this.location,
      wallType: wallType ?? this.wallType,
      wallDepth: wallDepth ?? this.wallDepth,
      wallSounding: wallSounding ?? this.wallSounding,
      perforationAccess: perforationAccess ?? this.perforationAccess,
      perforationConstraints:
          perforationConstraints ?? this.perforationConstraints,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }

  // Photo management helper methods
  Perforation addPhoto(Photo photo) {
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.add(photo);
    return copyWith(photos: updatedPhotos);
  }

  Perforation updatePhoto(int index, Photo updatedPhoto) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos[index] = updatedPhoto;
    return copyWith(photos: updatedPhotos);
  }

  Perforation removePhoto(int index) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.removeAt(index);
    return copyWith(photos: updatedPhotos);
  }
}
