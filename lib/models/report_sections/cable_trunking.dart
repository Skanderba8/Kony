// lib/models/report_sections/cable_trunking.dart
import 'package:uuid/uuid.dart';

/// Model for representing cable trunking (goulottes)
class CableTrunking {
  final String id;
  final String location;
  final String size;
  final double lengthInMeters;
  final int innerAngles;
  final int outerAngles;
  final int flatAngles;
  final bool isInterior;
  final double workHeight;
  final String notes;

  CableTrunking({
    required this.id,
    required this.location,
    required this.size,
    required this.lengthInMeters,
    required this.innerAngles,
    required this.outerAngles,
    required this.flatAngles,
    required this.isInterior,
    required this.workHeight,
    this.notes = '',
  });

  /// Factory method to create a new empty cable trunking entry with a UUID
  factory CableTrunking.create() {
    return CableTrunking(
      id: const Uuid().v4(),
      location: '',
      size: '',
      lengthInMeters: 0.0,
      innerAngles: 0,
      outerAngles: 0,
      flatAngles: 0,
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
      'innerAngles': innerAngles,
      'outerAngles': outerAngles,
      'flatAngles': flatAngles,
      'isInterior': isInterior,
      'workHeight': workHeight,
      'notes': notes,
    };
  }

  /// Create from Firestore data
  factory CableTrunking.fromJson(Map<String, dynamic> json) {
    return CableTrunking(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      size: json['size'] as String? ?? '',
      lengthInMeters: (json['lengthInMeters'] as num?)?.toDouble() ?? 0.0,
      innerAngles: json['innerAngles'] as int? ?? 0,
      outerAngles: json['outerAngles'] as int? ?? 0,
      flatAngles: json['flatAngles'] as int? ?? 0,
      isInterior: json['isInterior'] as bool? ?? true,
      workHeight: (json['workHeight'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Create a copy with some fields updated
  CableTrunking copyWith({
    String? id,
    String? location,
    String? size,
    double? lengthInMeters,
    int? innerAngles,
    int? outerAngles,
    int? flatAngles,
    bool? isInterior,
    double? workHeight,
    String? notes,
  }) {
    return CableTrunking(
      id: id ?? this.id,
      location: location ?? this.location,
      size: size ?? this.size,
      lengthInMeters: lengthInMeters ?? this.lengthInMeters,
      innerAngles: innerAngles ?? this.innerAngles,
      outerAngles: outerAngles ?? this.outerAngles,
      flatAngles: flatAngles ?? this.flatAngles,
      isInterior: isInterior ?? this.isInterior,
      workHeight: workHeight ?? this.workHeight,
      notes: notes ?? this.notes,
    );
  }
}
