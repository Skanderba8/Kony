// lib/services/component_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_sections/network_cabinet.dart';
import '../models/report_sections/perforation.dart';
import '../models/report_sections/access_trap.dart';
import '../models/report_sections/cable_path.dart';
import '../models/report_sections/cable_trunking.dart';
import '../models/report_sections/conduit.dart';
import '../models/report_sections/copper_cabling.dart';
import '../models/report_sections/fiber_optic_cabling.dart';
import '../models/report_sections/custom_component.dart';

class ComponentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _networkCabinetsCollection = 'network_cabinets';
  static const String _perforationsCollection = 'perforations';
  static const String _accessTrapsCollection = 'access_traps';
  static const String _cablePathsCollection = 'cable_paths';
  static const String _cableTrunkingsCollection = 'cable_trunkings';
  static const String _conduitsCollection = 'conduits';
  static const String _copperCablingsCollection = 'copper_cablings';
  static const String _fiberOpticCablingsCollection = 'fiber_optic_cablings';
  static const String _customComponentsCollection = 'custom_components';

  // Network Cabinets
  Future<String> saveNetworkCabinet(NetworkCabinet cabinet) async {
    final docRef = await _firestore
        .collection(_networkCabinetsCollection)
        .add(cabinet.toJson());
    return docRef.id;
  }

  Future<void> updateNetworkCabinet(String id, NetworkCabinet cabinet) async {
    await _firestore
        .collection(_networkCabinetsCollection)
        .doc(id)
        .update(cabinet.toJson());
  }

  Future<void> deleteNetworkCabinet(String id) async {
    await _firestore.collection(_networkCabinetsCollection).doc(id).delete();
  }

  Future<NetworkCabinet?> getNetworkCabinet(String id) async {
    final doc =
        await _firestore.collection(_networkCabinetsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id; // Add the document ID
      return NetworkCabinet.fromJson(data);
    }
    return null;
  }

  Stream<List<NetworkCabinet>> getNetworkCabinetsStream() {
    return _firestore
        .collection(_networkCabinetsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return NetworkCabinet.fromJson(data);
              }).toList(),
        );
  }

  // Perforations
  Future<String> savePerforation(Perforation perforation) async {
    final docRef = await _firestore
        .collection(_perforationsCollection)
        .add(perforation.toJson());
    return docRef.id;
  }

  Future<void> updatePerforation(String id, Perforation perforation) async {
    await _firestore
        .collection(_perforationsCollection)
        .doc(id)
        .update(perforation.toJson());
  }

  Future<void> deletePerforation(String id) async {
    await _firestore.collection(_perforationsCollection).doc(id).delete();
  }

  Future<Perforation?> getPerforation(String id) async {
    final doc =
        await _firestore.collection(_perforationsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Perforation.fromJson(data);
    }
    return null;
  }

  Stream<List<Perforation>> getPerforationsStream() {
    return _firestore
        .collection(_perforationsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Perforation.fromJson(data);
              }).toList(),
        );
  }

  // Access Traps
  Future<String> saveAccessTrap(AccessTrap trap) async {
    final docRef = await _firestore
        .collection(_accessTrapsCollection)
        .add(trap.toJson());
    return docRef.id;
  }

  Future<void> updateAccessTrap(String id, AccessTrap trap) async {
    await _firestore
        .collection(_accessTrapsCollection)
        .doc(id)
        .update(trap.toJson());
  }

  Future<void> deleteAccessTrap(String id) async {
    await _firestore.collection(_accessTrapsCollection).doc(id).delete();
  }

  Future<AccessTrap?> getAccessTrap(String id) async {
    final doc =
        await _firestore.collection(_accessTrapsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return AccessTrap.fromJson(data);
    }
    return null;
  }

  Stream<List<AccessTrap>> getAccessTrapsStream() {
    return _firestore
        .collection(_accessTrapsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return AccessTrap.fromJson(data);
              }).toList(),
        );
  }

  // Cable Paths
  Future<String> saveCablePath(CablePath path) async {
    final docRef = await _firestore
        .collection(_cablePathsCollection)
        .add(path.toJson());
    return docRef.id;
  }

  Future<void> updateCablePath(String id, CablePath path) async {
    await _firestore
        .collection(_cablePathsCollection)
        .doc(id)
        .update(path.toJson());
  }

  Future<void> deleteCablePath(String id) async {
    await _firestore.collection(_cablePathsCollection).doc(id).delete();
  }

  Future<CablePath?> getCablePath(String id) async {
    final doc =
        await _firestore.collection(_cablePathsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return CablePath.fromJson(data);
    }
    return null;
  }

  Stream<List<CablePath>> getCablePathsStream() {
    return _firestore
        .collection(_cablePathsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return CablePath.fromJson(data);
              }).toList(),
        );
  }

  // Cable Trunkings
  Future<String> saveCableTrunking(CableTrunking trunking) async {
    final docRef = await _firestore
        .collection(_cableTrunkingsCollection)
        .add(trunking.toJson());
    return docRef.id;
  }

  Future<void> updateCableTrunking(String id, CableTrunking trunking) async {
    await _firestore
        .collection(_cableTrunkingsCollection)
        .doc(id)
        .update(trunking.toJson());
  }

  Future<void> deleteCableTrunking(String id) async {
    await _firestore.collection(_cableTrunkingsCollection).doc(id).delete();
  }

  Future<CableTrunking?> getCableTrunking(String id) async {
    final doc =
        await _firestore.collection(_cableTrunkingsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return CableTrunking.fromJson(data);
    }
    return null;
  }

  Stream<List<CableTrunking>> getCableTrunkingsStream() {
    return _firestore
        .collection(_cableTrunkingsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return CableTrunking.fromJson(data);
              }).toList(),
        );
  }

  // Conduits
  Future<String> saveConduit(Conduit conduit) async {
    final docRef = await _firestore
        .collection(_conduitsCollection)
        .add(conduit.toJson());
    return docRef.id;
  }

  Future<void> updateConduit(String id, Conduit conduit) async {
    await _firestore
        .collection(_conduitsCollection)
        .doc(id)
        .update(conduit.toJson());
  }

  Future<void> deleteConduit(String id) async {
    await _firestore.collection(_conduitsCollection).doc(id).delete();
  }

  Future<Conduit?> getConduit(String id) async {
    final doc = await _firestore.collection(_conduitsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Conduit.fromJson(data);
    }
    return null;
  }

  Stream<List<Conduit>> getConduitsStream() {
    return _firestore
        .collection(_conduitsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Conduit.fromJson(data);
              }).toList(),
        );
  }

  // Copper Cablings
  Future<String> saveCopperCabling(CopperCabling cabling) async {
    final docRef = await _firestore
        .collection(_copperCablingsCollection)
        .add(cabling.toJson());
    return docRef.id;
  }

  Future<void> updateCopperCabling(String id, CopperCabling cabling) async {
    await _firestore
        .collection(_copperCablingsCollection)
        .doc(id)
        .update(cabling.toJson());
  }

  Future<void> deleteCopperCabling(String id) async {
    await _firestore.collection(_copperCablingsCollection).doc(id).delete();
  }

  Future<CopperCabling?> getCopperCabling(String id) async {
    final doc =
        await _firestore.collection(_copperCablingsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return CopperCabling.fromJson(data);
    }
    return null;
  }

  Stream<List<CopperCabling>> getCopperCablingsStream() {
    return _firestore
        .collection(_copperCablingsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return CopperCabling.fromJson(data);
              }).toList(),
        );
  }

  // Fiber Optic Cablings
  Future<String> saveFiberOpticCabling(FiberOpticCabling cabling) async {
    final docRef = await _firestore
        .collection(_fiberOpticCablingsCollection)
        .add(cabling.toJson());
    return docRef.id;
  }

  Future<void> updateFiberOpticCabling(
    String id,
    FiberOpticCabling cabling,
  ) async {
    await _firestore
        .collection(_fiberOpticCablingsCollection)
        .doc(id)
        .update(cabling.toJson());
  }

  Future<void> deleteFiberOpticCabling(String id) async {
    await _firestore.collection(_fiberOpticCablingsCollection).doc(id).delete();
  }

  Future<FiberOpticCabling?> getFiberOpticCabling(String id) async {
    final doc =
        await _firestore
            .collection(_fiberOpticCablingsCollection)
            .doc(id)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return FiberOpticCabling.fromJson(data);
    }
    return null;
  }

  Stream<List<FiberOpticCabling>> getFiberOpticCablingsStream() {
    return _firestore
        .collection(_fiberOpticCablingsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return FiberOpticCabling.fromJson(data);
              }).toList(),
        );
  }

  // Custom Components
  Future<String> saveCustomComponent(CustomComponent component) async {
    final docRef = await _firestore
        .collection(_customComponentsCollection)
        .add(component.toJson());
    return docRef.id;
  }

  Future<void> updateCustomComponent(
    String id,
    CustomComponent component,
  ) async {
    await _firestore
        .collection(_customComponentsCollection)
        .doc(id)
        .update(component.toJson());
  }

  Future<void> deleteCustomComponent(String id) async {
    await _firestore.collection(_customComponentsCollection).doc(id).delete();
  }

  Future<CustomComponent?> getCustomComponent(String id) async {
    final doc =
        await _firestore.collection(_customComponentsCollection).doc(id).get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return CustomComponent.fromJson(data);
    }
    return null;
  }

  Stream<List<CustomComponent>> getCustomComponentsStream() {
    return _firestore
        .collection(_customComponentsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return CustomComponent.fromJson(data);
              }).toList(),
        );
  }

  // Batch operations for efficiency
  Future<void> saveMultipleComponents({
    List<NetworkCabinet>? networkCabinets,
    List<Perforation>? perforations,
    List<AccessTrap>? accessTraps,
    List<CablePath>? cablePaths,
    List<CableTrunking>? cableTrunkings,
    List<Conduit>? conduits,
    List<CopperCabling>? copperCablings,
    List<FiberOpticCabling>? fiberOpticCablings,
    List<CustomComponent>? customComponents,
  }) async {
    final batch = _firestore.batch();

    // Add network cabinets
    if (networkCabinets != null) {
      for (final cabinet in networkCabinets) {
        final docRef = _firestore.collection(_networkCabinetsCollection).doc();
        batch.set(docRef, cabinet.toJson());
      }
    }

    // Add perforations
    if (perforations != null) {
      for (final perforation in perforations) {
        final docRef = _firestore.collection(_perforationsCollection).doc();
        batch.set(docRef, perforation.toJson());
      }
    }

    // Add access traps
    if (accessTraps != null) {
      for (final trap in accessTraps) {
        final docRef = _firestore.collection(_accessTrapsCollection).doc();
        batch.set(docRef, trap.toJson());
      }
    }

    // Add cable paths
    if (cablePaths != null) {
      for (final path in cablePaths) {
        final docRef = _firestore.collection(_cablePathsCollection).doc();
        batch.set(docRef, path.toJson());
      }
    }

    // Add cable trunkings
    if (cableTrunkings != null) {
      for (final trunking in cableTrunkings) {
        final docRef = _firestore.collection(_cableTrunkingsCollection).doc();
        batch.set(docRef, trunking.toJson());
      }
    }

    // Add conduits
    if (conduits != null) {
      for (final conduit in conduits) {
        final docRef = _firestore.collection(_conduitsCollection).doc();
        batch.set(docRef, conduit.toJson());
      }
    }

    // Add copper cablings
    if (copperCablings != null) {
      for (final cabling in copperCablings) {
        final docRef = _firestore.collection(_copperCablingsCollection).doc();
        batch.set(docRef, cabling.toJson());
      }
    }

    // Add fiber optic cablings
    if (fiberOpticCablings != null) {
      for (final cabling in fiberOpticCablings) {
        final docRef =
            _firestore.collection(_fiberOpticCablingsCollection).doc();
        batch.set(docRef, cabling.toJson());
      }
    }

    // Add custom components
    if (customComponents != null) {
      for (final component in customComponents) {
        final docRef = _firestore.collection(_customComponentsCollection).doc();
        batch.set(docRef, component.toJson());
      }
    }

    await batch.commit();
  }
}
