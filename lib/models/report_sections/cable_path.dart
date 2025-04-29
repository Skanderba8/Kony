// lib/models/report_sections/cable_path.dart
import 'package:uuid/uuid.dart';

/// Model for representing cable paths (chemins de câbles)
class CablePath {
  final String id;
  final String location;
  final String size;
  final double lengthInMeters;
  final String fixationType;
  final bool isVisible;
  final bool isInterior;
  final double heightInMeters;
  final String notes;

  CablePath({
    required this.id,
    required this.location,
    required this.size,
    required this.lengthInMeters,
    required this.fixationType,
    required this.isVisible,
    required this.isInterior,
    required this.heightInMeters,
    this.notes = '',
  });

  /// Factory method to create a new empty cable path entry with a UUID
  factory CablePath.create() {
    return CablePath(
      id: const Uuid().v4(),
      location: '',
      size: '',
      lengthInMeters: 0.0,
      fixationType: '',
      isVisible: true,
      isInterior: true,
      heightInMeters: 0.0,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'size': size,
      'lengthInMeters': lengthInMeters,
      'fixationType': fixationType,
      'isVisible': isVisible,
      'isInterior': isInterior,
      'heightInMeters': heightInMeters,
      'notes': notes,
    };
  }

  /// Create from Firestore data
  factory CablePath.fromJson(Map<String, dynamic> json) {
    return CablePath(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      size: json['size'] as String? ?? '',
      lengthInMeters: (json['lengthInMeters'] as num?)?.toDouble() ?? 0.0,
      fixationType: json['fixationType'] as String? ?? '',
      isVisible: json['isVisible'] as bool? ?? true,
      isInterior: json['isInterior'] as bool? ?? true,
      heightInMeters: (json['heightInMeters'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Create a copy with some fields updated
  CablePath copyWith({
    String? id,
    String? location,
    String? size,
    double? lengthInMeters,
    String? fixationType,
    bool? isVisible,
    bool? isInterior,
    double? heightInMeters,
    String? notes,
  }) {
    return CablePath(
      id: id ?? this.id,
      location: location ?? this.location,
      size: size ?? this.size,
      lengthInMeters: lengthInMeters ?? this.lengthInMeters,
      fixationType: fixationType ?? this.fixationType,
      isVisible: isVisible ?? this.isVisible,
      isInterior: isInterior ?? this.isInterior,
      heightInMeters: heightInMeters ?? this.heightInMeters,
      notes: notes ?? this.notes,
    );
  }
}
