// lib/models/report_sections/conduit.dart
import 'package:uuid/uuid.dart';

/// Model for representing cable conduits (tubages et conduits)
class Conduit {
  final String id;
  final String location;
  final String size;
  final double lengthInMeters;
  final bool isInterior;
  final double workHeight;
  final String notes;

  Conduit({
    required this.id,
    required this.location,
    required this.size,
    required this.lengthInMeters,
    required this.isInterior,
    required this.workHeight,
    this.notes = '',
  });

  /// Factory method to create a new empty conduit entry with a UUID
  factory Conduit.create() {
    return Conduit(
      id: const Uuid().v4(),
      location: '',
      size: '',
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
      'size': size,
      'lengthInMeters': lengthInMeters,
      'isInterior': isInterior,
      'workHeight': workHeight,
      'notes': notes,
    };
  }

  /// Create from Firestore data
  factory Conduit.fromJson(Map<String, dynamic> json) {
    return Conduit(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      size: json['size'] as String? ?? '',
      lengthInMeters: (json['lengthInMeters'] as num?)?.toDouble() ?? 0.0,
      isInterior: json['isInterior'] as bool? ?? true,
      workHeight: (json['workHeight'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Create a copy with some fields updated
  Conduit copyWith({
    String? id,
    String? location,
    String? size,
    double? lengthInMeters,
    bool? isInterior,
    double? workHeight,
    String? notes,
  }) {
    return Conduit(
      id: id ?? this.id,
      location: location ?? this.location,
      size: size ?? this.size,
      lengthInMeters: lengthInMeters ?? this.lengthInMeters,
      isInterior: isInterior ?? this.isInterior,
      workHeight: workHeight ?? this.workHeight,
      notes: notes ?? this.notes,
    );
  }
}
