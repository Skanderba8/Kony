// lib/models/report_sections/custom_component.dart
import 'package:uuid/uuid.dart';
import '../photo.dart'; // Make sure to add this import

/// Model for representing custom user-defined components
class CustomComponent {
  final String id;
  final String name;
  final String description;
  final String location;
  final Map<String, dynamic> customFields;
  final String notes;
  // Add photos list
  final List<Photo> photos;

  CustomComponent({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.customFields = const {},
    this.notes = '',
    this.photos = const [], // Initialize with empty list
  });

  /// Factory method to create a new empty custom component with a UUID
  factory CustomComponent.create() {
    return CustomComponent(
      id: const Uuid().v4(),
      name: '',
      description: '',
      location: '',
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'customFields': customFields,
      'notes': notes,
      'photos': photos.map((photo) => photo.toJson()).toList(), // Add this line
    };
  }

  /// Create from Firestore data
  factory CustomComponent.fromJson(Map<String, dynamic> json) {
    return CustomComponent(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      customFields: json['customFields'] as Map<String, dynamic>? ?? {},
      notes: json['notes'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [], // Add this line
    );
  }

  /// Create a copy with some fields updated
  CustomComponent copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    Map<String, dynamic>? customFields,
    String? notes,
    List<Photo>? photos, // Add this parameter
  }) {
    return CustomComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos, // Add this line
    );
  }

  // Add these photo management helper methods here

  // Add a new photo to the component
  CustomComponent addPhoto(Photo photo) {
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.add(photo);
    return copyWith(photos: updatedPhotos);
  }

  // Update an existing photo
  CustomComponent updatePhoto(int index, Photo updatedPhoto) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos[index] = updatedPhoto;
    return copyWith(photos: updatedPhotos);
  }

  // Remove a photo
  CustomComponent removePhoto(int index) {
    if (index < 0 || index >= photos.length) return this;
    final updatedPhotos = List<Photo>.from(photos);
    updatedPhotos.removeAt(index);
    return copyWith(photos: updatedPhotos);
  }
}
