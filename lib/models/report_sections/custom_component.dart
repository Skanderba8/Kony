// lib/models/report_sections/custom_component.dart
import 'package:uuid/uuid.dart';

/// Model for representing custom user-defined components
class CustomComponent {
  final String id;
  final String name;
  final String description;
  final String location;
  final Map<String, dynamic> customFields;
  final String notes;

  CustomComponent({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.customFields = const {},
    this.notes = '',
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
  }) {
    return CustomComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
    );
  }
}
