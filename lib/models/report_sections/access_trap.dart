// lib/models/report_sections/access_trap.dart
import 'package:uuid/uuid.dart';

/// Model for representing access traps for cable management
class AccessTrap {
  final String id;
  final String location;
  final String trapSize;
  final String notes;

  AccessTrap({
    required this.id,
    required this.location,
    required this.trapSize,
    this.notes = '',
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
    };
  }

  /// Create from Firestore data
  factory AccessTrap.fromJson(Map<String, dynamic> json) {
    return AccessTrap(
      id: json['id'] as String? ?? const Uuid().v4(),
      location: json['location'] as String? ?? '',
      trapSize: json['trapSize'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Create a copy with some fields updated
  AccessTrap copyWith({
    String? id,
    String? location,
    String? trapSize,
    String? notes,
  }) {
    return AccessTrap(
      id: id ?? this.id,
      location: location ?? this.location,
      trapSize: trapSize ?? this.trapSize,
      notes: notes ?? this.notes,
    );
  }
}
