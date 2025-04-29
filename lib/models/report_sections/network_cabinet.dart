// lib/models/report_sections/network_cabinet.dart
import 'package:uuid/uuid.dart';

/// Model for representing a network cabinet in the technical visit report
///
/// This class encapsulates all information related to a network cabinet
/// including its identification, physical properties, and capacity details.
/// It follows immutable object pattern with constructors for creation and
/// conversion methods for serialization.
class NetworkCabinet {
  final String id;
  final String name;
  final String location;
  final String cabinetState;
  final bool isPowered;
  final int availableOutlets;
  final int totalRackUnits;
  final int availableRackUnits;
  final String notes;

  /// Constructor requiring all essential fields
  ///
  /// Creates an immutable NetworkCabinet instance with all required properties.
  /// Notes field is optional with a default empty value.
  NetworkCabinet({
    required this.id,
    required this.name,
    required this.location,
    required this.cabinetState,
    required this.isPowered,
    required this.availableOutlets,
    required this.totalRackUnits,
    required this.availableRackUnits,
    this.notes = '',
  });

  /// Factory method to create a new empty cabinet with a UUID
  ///
  /// This provides a convenient way to create a new cabinet instance
  /// with default values and a newly generated UUID.
  factory NetworkCabinet.create() {
    return NetworkCabinet(
      id: const Uuid().v4(),
      name: '',
      location: '',
      cabinetState: '',
      isPowered: false,
      availableOutlets: 0,
      totalRackUnits: 0,
      availableRackUnits: 0,
    );
  }

  /// Convert to Map for Firestore
  ///
  /// Serializes this object into a Map that can be directly stored in Firestore.
  /// All properties are included with their corresponding field names.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'cabinetState': cabinetState,
      'isPowered': isPowered,
      'availableOutlets': availableOutlets,
      'totalRackUnits': totalRackUnits,
      'availableRackUnits': availableRackUnits,
      'notes': notes,
    };
  }

  /// Create from Firestore data
  ///
  /// Deserializes a Map (typically from Firestore) into a NetworkCabinet instance.
  /// Handles null values and missing fields with appropriate defaults.
  factory NetworkCabinet.fromJson(Map<String, dynamic> json) {
    return NetworkCabinet(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      cabinetState: json['cabinetState'] as String? ?? '',
      isPowered: json['isPowered'] as bool? ?? false,
      availableOutlets: json['availableOutlets'] as int? ?? 0,
      totalRackUnits: json['totalRackUnits'] as int? ?? 0,
      availableRackUnits: json['availableRackUnits'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Create a copy with some fields updated
  ///
  /// Implements the immutable object pattern by providing a way to create
  /// a new instance with some properties changed while keeping others the same.
  NetworkCabinet copyWith({
    String? id,
    String? name,
    String? location,
    String? cabinetState,
    bool? isPowered,
    int? availableOutlets,
    int? totalRackUnits,
    int? availableRackUnits,
    String? notes,
  }) {
    return NetworkCabinet(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      cabinetState: cabinetState ?? this.cabinetState,
      isPowered: isPowered ?? this.isPowered,
      availableOutlets: availableOutlets ?? this.availableOutlets,
      totalRackUnits: totalRackUnits ?? this.totalRackUnits,
      availableRackUnits: availableRackUnits ?? this.availableRackUnits,
      notes: notes ?? this.notes,
    );
  }
}
