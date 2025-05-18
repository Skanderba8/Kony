// lib/models/floor.dart
import 'package:uuid/uuid.dart';
import 'report_sections/network_cabinet.dart';
import 'report_sections/perforation.dart';
import 'report_sections/access_trap.dart';
import 'report_sections/cable_path.dart';
import 'report_sections/cable_trunking.dart';
import 'report_sections/conduit.dart';
import 'report_sections/copper_cabling.dart';
import 'report_sections/fiber_optic_cabling.dart';
import 'report_sections/custom_component.dart';

/// A model representing a building floor with all its technical components
class Floor {
  final String id;
  final String name;
  final List<NetworkCabinet> networkCabinets;
  final List<Perforation> perforations;
  final List<AccessTrap> accessTraps;
  final List<CablePath> cablePaths;
  final List<CableTrunking> cableTrunkings;
  final List<Conduit> conduits;
  final List<CopperCabling> copperCablings;
  final List<FiberOpticCabling> fiberOpticCablings;
  final List<CustomComponent> customComponents;

  final String notes;

  Floor({
    required this.id,
    required this.name,
    this.networkCabinets = const [],
    this.perforations = const [],
    this.accessTraps = const [],
    this.cablePaths = const [],
    this.cableTrunkings = const [],
    this.conduits = const [],
    this.copperCablings = const [],
    this.fiberOpticCablings = const [],
    this.customComponents = const [],
    this.notes = '',
  });

  /// Create a new floor with a default name and empty components
  factory Floor.create({String? name}) {
    return Floor(id: const Uuid().v4(), name: name ?? 'Étage');
  }

  /// Create a copy of this floor with updated fields
  Floor copyWith({
    String? id,
    String? name,
    List<NetworkCabinet>? networkCabinets,
    List<Perforation>? perforations,
    List<AccessTrap>? accessTraps,
    List<CablePath>? cablePaths,
    List<CableTrunking>? cableTrunkings,
    List<Conduit>? conduits,
    List<CopperCabling>? copperCablings,
    List<FiberOpticCabling>? fiberOpticCablings,
    List<CustomComponent>? customComponents,
    String? notes,
  }) {
    return Floor(
      id: id ?? this.id,
      name: name ?? this.name,
      networkCabinets: networkCabinets ?? this.networkCabinets,
      perforations: perforations ?? this.perforations,
      accessTraps: accessTraps ?? this.accessTraps,
      cablePaths: cablePaths ?? this.cablePaths,
      cableTrunkings: cableTrunkings ?? this.cableTrunkings,
      conduits: conduits ?? this.conduits,
      copperCablings: copperCablings ?? this.copperCablings,
      fiberOpticCablings: fiberOpticCablings ?? this.fiberOpticCablings,
      customComponents: customComponents ?? this.customComponents,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'networkCabinets': networkCabinets.map((c) => c.toJson()).toList(),
      'perforations': perforations.map((p) => p.toJson()).toList(),
      'accessTraps': accessTraps.map((t) => t.toJson()).toList(),
      'cablePaths': cablePaths.map((p) => p.toJson()).toList(),
      'cableTrunkings': cableTrunkings.map((t) => t.toJson()).toList(),
      'conduits': conduits.map((c) => c.toJson()).toList(),
      'copperCablings': copperCablings.map((c) => c.toJson()).toList(),
      'fiberOpticCablings': fiberOpticCablings.map((c) => c.toJson()).toList(),
      'customComponents': customComponents.map((c) => c.toJson()).toList(),
      'notes': notes,
    };
  }

  /// Create from Firestore data
  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Étage',
      networkCabinets: _parseComponentList<NetworkCabinet>(
        json['networkCabinets'],
        NetworkCabinet.fromJson,
      ),
      perforations: _parseComponentList<Perforation>(
        json['perforations'],
        Perforation.fromJson,
      ),
      accessTraps: _parseComponentList<AccessTrap>(
        json['accessTraps'],
        AccessTrap.fromJson,
      ),
      cablePaths: _parseComponentList<CablePath>(
        json['cablePaths'],
        CablePath.fromJson,
      ),
      cableTrunkings: _parseComponentList<CableTrunking>(
        json['cableTrunkings'],
        CableTrunking.fromJson,
      ),
      conduits: _parseComponentList<Conduit>(
        json['conduits'],
        Conduit.fromJson,
      ),
      copperCablings: _parseComponentList<CopperCabling>(
        json['copperCablings'],
        CopperCabling.fromJson,
      ),
      fiberOpticCablings: _parseComponentList<FiberOpticCabling>(
        json['fiberOpticCablings'],
        FiberOpticCabling.fromJson,
      ),
      customComponents: _parseComponentList<CustomComponent>(
        json['customComponents'],
        CustomComponent.fromJson,
      ),
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Helper method to parse component lists from Firestore
  static List<T> _parseComponentList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((item) => fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get the total component count for this floor
  int get totalComponentCount {
    return networkCabinets.length +
        perforations.length +
        accessTraps.length +
        cablePaths.length +
        cableTrunkings.length +
        conduits.length +
        copperCablings.length +
        fiberOpticCablings.length +
        customComponents.length;
  }

  /// Check if this floor has any components
  bool get hasComponents => totalComponentCount > 0;
}
