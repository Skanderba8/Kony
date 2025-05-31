// lib/view_models/technical_visit_report_view_model.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:kony/models/photo.dart';
import 'package:kony/models/report_sections/custom_component.dart';
import '../models/technical_visit_report.dart';
import '../models/floor.dart';
import '../models/report_sections/network_cabinet.dart';
import '../models/report_sections/perforation.dart';
import '../models/report_sections/access_trap.dart';
import '../models/report_sections/cable_path.dart';
import '../models/report_sections/cable_trunking.dart';
import '../models/report_sections/conduit.dart';
import '../models/report_sections/copper_cabling.dart';
import '../models/report_sections/fiber_optic_cabling.dart';
import '../services/auth_service.dart';
import '../services/technical_visit_report_service.dart';
import '../services/universal_photo_service.dart';
import '../services/pdf_generation_service.dart';
import 'package:open_file/open_file.dart';

class TechnicalVisitReportViewModel extends ChangeNotifier {
  final TechnicalVisitReportService _reportService;
  final AuthService _authService;
  final PdfGenerationService _pdfService;
  String? _lastAddedComponentType;
  String? get lastAddedComponentType => _lastAddedComponentType;

  TechnicalVisitReport? _currentReport;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;
  int _currentFloorIndex = 0;
  String? _selectedComponentType;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  final List<String> componentTypes = [
    'Baie Informatique',
    'Percement',
    'Trappe d\'accès',
    'Chemin de câbles',
    'Goulotte',
    'Conduit',
    'Câblage cuivre',
    'Câblage fibre optique',
    'Composant personnalisé',
  ];

  TechnicalVisitReport? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStep => _currentStep;
  bool get isSubmitting => _isLoading && _currentReport?.status == 'draft';
  bool get isNewReport => _currentReport?.id.isEmpty ?? true;
  bool get canSubmit => _currentReport != null && validateAllSections();
  int get currentFloorIndex => _currentFloorIndex;
  List<Floor> get floors => _currentReport?.floors ?? [];
  Floor? get currentFloor =>
      _currentReport != null &&
              _currentFloorIndex < _currentReport!.floors.length
          ? _currentReport!.floors[_currentFloorIndex]
          : null;
  String? get selectedComponentType => _selectedComponentType;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  TechnicalVisitReportViewModel({
    required TechnicalVisitReportService reportService,
    required AuthService authService,
    required PdfGenerationService pdfService,
  }) : _reportService = reportService,
       _authService = authService,
       _pdfService = pdfService {
    _initAutoSave();
  }

  void _initAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_hasUnsavedChanges && _currentReport?.status == 'draft') {
        _autoSave();
      }
    });
  }

  Future<void> initNewReport() async {
    _setLoading(true);
    _clearError();

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        return;
      }

      final technicianName =
          user.displayName ?? user.email ?? 'Unknown Technician';
      _currentReport = TechnicalVisitReport.createDraft(
        technicianId: user.uid,
        technicianName: technicianName,
      );

      _currentStep = 0;
      _currentFloorIndex = 0;
      _selectedComponentType = null;
      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize new report: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReport(String reportId) async {
    _setLoading(true);
    _clearError();

    try {
      final report = await _reportService.getReportById(reportId);
      if (report == null) {
        _setError('Report not found');
        return;
      }

      _currentReport = report;
      _currentStep = 0;
      _currentFloorIndex = 0;
      _selectedComponentType = null;
      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load report: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveDraft() async {
    if (_currentReport == null) {
      _setError('No report to save');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedReport = _currentReport!.copyWith(
        lastModified: DateTime.now(),
      );

      if (_isNewReport()) {
        await _reportService.createReport(updatedReport);
      } else {
        await _reportService.updateReport(updatedReport);
      }

      _currentReport = updatedReport;
      _hasUnsavedChanges = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save draft: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _autoSave() async {
    if (_currentReport == null || !_hasUnsavedChanges) return;

    try {
      if (_currentReport!.status == 'draft') {
        await _reportService.updateReport(_currentReport!);
        _hasUnsavedChanges = false;
      }
    } catch (e) {
      // Silent fail for auto-save
    }
  }

  Future<bool> submitReport() async {
    if (_currentReport == null) {
      _setError('No report to submit');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      if (!await _validateAllPhotosUploaded()) {
        _setError(
          'Some photos are still uploading. Please wait and try again.',
        );
        return false;
      }

      if (!validateAllSections()) {
        _setError('Veuillez compléter toutes les sections requises');
        return false;
      }

      await _reportService.createReport(_currentReport!);

      final reportToSubmit = _currentReport!.copyWith(
        status: 'submitted',
        submittedAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      await _reportService.updateReport(reportToSubmit);

      _currentReport = reportToSubmit;
      _hasUnsavedChanges = false;

      try {
        final pdfFile = await _pdfService.generateTechnicalReportPdf(
          reportToSubmit,
        );

        await _reportService.recordPdfMetadata(
          reportToSubmit.id,
          await pdfFile.length(),
        );

        if (Platform.isAndroid || Platform.isIOS) {
          try {
            await OpenFile.open(pdfFile.path);
          } catch (e) {
            // Silent fail for PDF opening
          }
        }
      } catch (pdfError) {
        // PDF generation failed but report was successfully submitted
      }

      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      String errorMsg;
      if (e.code == 'not-found') {
        errorMsg = 'Le rapport n\'existe pas dans la base de données.';
      } else if (e.code == 'permission-denied') {
        errorMsg = 'Vous n\'avez pas les permissions nécessaires.';
      } else {
        errorMsg = 'Erreur Firebase: ${e.message}';
      }
      _setError(errorMsg);
      return false;
    } catch (e) {
      final errorMsg = 'Erreur lors de la soumission: $e';
      _setError(errorMsg);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _validateAllPhotosUploaded() async {
    if (_currentReport == null) return true;

    for (final floor in _currentReport!.floors) {
      // Check all component types for photos
      for (final component in floor.customComponents) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.networkCabinets) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.perforations) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.accessTraps) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.cablePaths) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.cableTrunkings) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.conduits) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.copperCablings) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
      for (final component in floor.fiberOpticCablings) {
        for (final photo in component.photos) {
          if (photo.url.isEmpty || !_isValidPhotoUrl(photo.url)) return false;
        }
      }
    }

    return true;
  }

  bool _isValidPhotoUrl(String url) {
    return url.startsWith('https://firebasestorage.googleapis.com') ||
        url.startsWith('https://res.cloudinary.com') ||
        url.startsWith('https://');
  }

  Stream<List<TechnicalVisitReport>> getDraftReportsStream() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _reportService.getDraftReportsStream(user.uid);
  }

  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _reportService.getSubmittedReportsStream(user.uid);
  }

  void navigateToStep(int step) {
    if (step >= 0 && step <= 6) {
      _currentStep = step;
      notifyListeners();
    }
  }

  bool nextStep() {
    if (_currentStep < 6) {
      _currentStep++;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setCurrentFloorIndex(int index) {
    if (_currentReport != null &&
        index >= 0 &&
        index < _currentReport!.floors.length) {
      _currentFloorIndex = index;
      _selectedComponentType = null;
      notifyListeners();
    }
  }

  void setSelectedComponentType(String? type) {
    _selectedComponentType = type;
    notifyListeners();
  }

  void addFloor() {
    if (_currentReport == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final floorNumber = floors.length + 1;

    String floorName;
    if (floorNumber == 1) {
      floorName = 'Rez-de-chaussée';
    } else {
      floorName = 'Étage ${floorNumber - 1}';
    }

    floors.add(Floor.create(name: floorName));

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _currentFloorIndex = floors.length - 1;
    _selectedComponentType = null;
    _markAsChanged();
    notifyListeners();
  }

  void updateFloorName(int index, String name) {
    if (_currentReport == null ||
        index < 0 ||
        index >= _currentReport!.floors.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    floors[index] = floors[index].copyWith(name: name);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void deleteFloor(int index) {
    if (_currentReport == null ||
        index < 0 ||
        index >= _currentReport!.floors.length ||
        _currentReport!.floors.length <= 1)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    floors.removeAt(index);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    if (_currentFloorIndex >= floors.length) {
      _currentFloorIndex = floors.length - 1;
    }

    _markAsChanged();
    notifyListeners();
  }

  void _setLastAddedComponentType(String componentType) {
    _lastAddedComponentType = componentType;
    notifyListeners();
  }

  // Network Cabinet methods
  void addNetworkCabinet() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final currentFloorCabinets = List<NetworkCabinet>.from(
      currentFloor!.networkCabinets,
    );

    currentFloorCabinets.add(NetworkCabinet.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      networkCabinets: currentFloorCabinets,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('NetworkCabinet'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void updateNetworkCabinet(int index, NetworkCabinet updatedCabinet) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.networkCabinets.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cabinets = List<NetworkCabinet>.from(currentFloor!.networkCabinets);

    cabinets[index] = updatedCabinet;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      networkCabinets: cabinets,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void removeNetworkCabinet(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.networkCabinets.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cabinets = List<NetworkCabinet>.from(currentFloor!.networkCabinets);

    cabinets.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      networkCabinets: cabinets,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Network Cabinet
  Future<void> addPhotoToNetworkCabinet(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'NetworkCabinet',
    );
  }

  void updateNetworkCabinetPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'NetworkCabinet',
    );
  }

  Future<void> removePhotoFromNetworkCabinet(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(
      componentIndex,
      photoIndex,
      'NetworkCabinet',
    );
  }

  // Perforation methods
  void addPerforation() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final perforations = List<Perforation>.from(currentFloor!.perforations);

    perforations.add(Perforation.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      perforations: perforations,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void updatePerforation(int index, Perforation updatedPerforation) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.perforations.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final perforations = List<Perforation>.from(currentFloor!.perforations);

    perforations[index] = updatedPerforation;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      perforations: perforations,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('Perforation'); // Track last added
    _markAsChanged();
    notifyListeners();
  }

  void removePerforation(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.perforations.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final perforations = List<Perforation>.from(currentFloor!.perforations);

    perforations.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      perforations: perforations,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Perforation
  Future<void> addPhotoToPerforation(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'Perforation',
    );
  }

  void updatePerforationPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'Perforation',
    );
  }

  Future<void> removePhotoFromPerforation(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(componentIndex, photoIndex, 'Perforation');
  }

  // Access Trap methods
  void addAccessTrap() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final accessTraps = List<AccessTrap>.from(currentFloor!.accessTraps);

    accessTraps.add(AccessTrap.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      accessTraps: accessTraps,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('AccessTrap'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void updateAccessTrap(int index, AccessTrap updatedTrap) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.accessTraps.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final accessTraps = List<AccessTrap>.from(currentFloor!.accessTraps);

    accessTraps[index] = updatedTrap;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      accessTraps: accessTraps,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void removeAccessTrap(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.accessTraps.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final accessTraps = List<AccessTrap>.from(currentFloor!.accessTraps);

    accessTraps.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      accessTraps: accessTraps,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Access Trap
  Future<void> addPhotoToAccessTrap(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'AccessTrap',
    );
  }

  void updateAccessTrapPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'AccessTrap',
    );
  }

  Future<void> removePhotoFromAccessTrap(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(componentIndex, photoIndex, 'AccessTrap');
  }

  // Cable Path methods
  void addCablePath() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cablePaths = List<CablePath>.from(currentFloor!.cablePaths);

    cablePaths.add(CablePath.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(cablePaths: cablePaths);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('CablePath'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void updateCablePath(int index, CablePath updatedPath) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.cablePaths.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cablePaths = List<CablePath>.from(currentFloor!.cablePaths);

    cablePaths[index] = updatedPath;

    floors[_currentFloorIndex] = currentFloor!.copyWith(cablePaths: cablePaths);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void removeCablePath(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.cablePaths.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cablePaths = List<CablePath>.from(currentFloor!.cablePaths);

    cablePaths.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(cablePaths: cablePaths);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Cable Path
  Future<void> addPhotoToCablePath(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(componentIndex, imageFile, comment, 'CablePath');
  }

  void updateCablePathPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'CablePath',
    );
  }

  Future<void> removePhotoFromCablePath(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(componentIndex, photoIndex, 'CablePath');
  }

  // Cable Trunking methods
  void addCableTrunking() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cableTrunkings = List<CableTrunking>.from(
      currentFloor!.cableTrunkings,
    );

    cableTrunkings.add(CableTrunking.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      cableTrunkings: cableTrunkings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void updateCableTrunking(int index, CableTrunking updatedTrunking) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.cableTrunkings.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cableTrunkings = List<CableTrunking>.from(
      currentFloor!.cableTrunkings,
    );

    cableTrunkings[index] = updatedTrunking;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      cableTrunkings: cableTrunkings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('CableTrunking'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void removeCableTrunking(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.cableTrunkings.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final cableTrunkings = List<CableTrunking>.from(
      currentFloor!.cableTrunkings,
    );

    cableTrunkings.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      cableTrunkings: cableTrunkings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Cable Trunking
  Future<void> addPhotoToCableTrunking(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'CableTrunking',
    );
  }

  void updateCableTrunkingPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'CableTrunking',
    );
  }

  Future<void> removePhotoFromCableTrunking(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(
      componentIndex,
      photoIndex,
      'CableTrunking',
    );
  }

  // Conduit methods
  void addConduit() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final conduits = List<Conduit>.from(currentFloor!.conduits);

    conduits.add(Conduit.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(conduits: conduits);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void updateConduit(int index, Conduit updatedConduit) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.conduits.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final conduits = List<Conduit>.from(currentFloor!.conduits);

    conduits[index] = updatedConduit;

    floors[_currentFloorIndex] = currentFloor!.copyWith(conduits: conduits);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('Conduit'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void removeConduit(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.conduits.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final conduits = List<Conduit>.from(currentFloor!.conduits);

    conduits.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(conduits: conduits);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Conduit
  Future<void> addPhotoToConduit(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(componentIndex, imageFile, comment, 'Conduit');
  }

  void updateConduitPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'Conduit',
    );
  }

  Future<void> removePhotoFromConduit(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(componentIndex, photoIndex, 'Conduit');
  }

  // Copper Cabling methods
  void addCopperCabling() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final copperCablings = List<CopperCabling>.from(
      currentFloor!.copperCablings,
    );

    copperCablings.add(CopperCabling.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      copperCablings: copperCablings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('CopperCabling'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void updateCopperCabling(int index, CopperCabling updatedCabling) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.copperCablings.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final copperCablings = List<CopperCabling>.from(
      currentFloor!.copperCablings,
    );

    copperCablings[index] = updatedCabling;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      copperCablings: copperCablings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void removeCopperCabling(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.copperCablings.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final copperCablings = List<CopperCabling>.from(
      currentFloor!.copperCablings,
    );

    copperCablings.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      copperCablings: copperCablings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Copper Cabling
  Future<void> addPhotoToCopperCabling(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'CopperCabling',
    );
  }

  void updateCopperCablingPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'CopperCabling',
    );
  }

  Future<void> removePhotoFromCopperCabling(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(
      componentIndex,
      photoIndex,
      'CopperCabling',
    );
  }

  // Fiber Optic Cabling methods
  void addFiberOpticCabling() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final fiberOpticCablings = List<FiberOpticCabling>.from(
      currentFloor!.fiberOpticCablings,
    );

    fiberOpticCablings.add(FiberOpticCabling.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      fiberOpticCablings: fiberOpticCablings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('FiberOpticCabling'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void updateFiberOpticCabling(int index, FiberOpticCabling updatedCabling) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.fiberOpticCablings.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final fiberOpticCablings = List<FiberOpticCabling>.from(
      currentFloor!.fiberOpticCablings,
    );

    fiberOpticCablings[index] = updatedCabling;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      fiberOpticCablings: fiberOpticCablings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void removeFiberOpticCabling(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.fiberOpticCablings.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final fiberOpticCablings = List<FiberOpticCabling>.from(
      currentFloor!.fiberOpticCablings,
    );

    fiberOpticCablings.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      fiberOpticCablings: fiberOpticCablings,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Fiber Optic Cabling
  Future<void> addPhotoToFiberOpticCabling(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'FiberOpticCabling',
    );
  }

  void updateFiberOpticCablingPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
  ) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'FiberOpticCabling',
    );
  }

  Future<void> removePhotoFromFiberOpticCabling(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(
      componentIndex,
      photoIndex,
      'FiberOpticCabling',
    );
  }

  // Custom Component methods (existing)
  void addCustomComponent() {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final customComponents = List<CustomComponent>.from(
      currentFloor!.customComponents,
    );

    customComponents.add(CustomComponent.create());

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      customComponents: customComponents,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
    _setLastAddedComponentType('CustomComponent'); // Track last added

    _markAsChanged();
    notifyListeners();
  }

  void updateCustomComponent(int index, CustomComponent updatedComponent) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.customComponents.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final customComponents = List<CustomComponent>.from(
      currentFloor!.customComponents,
    );

    customComponents[index] = updatedComponent;

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      customComponents: customComponents,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void removeCustomComponent(int index) {
    if (_currentReport == null ||
        currentFloor == null ||
        index < 0 ||
        index >= currentFloor!.customComponents.length)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final customComponents = List<CustomComponent>.from(
      currentFloor!.customComponents,
    );

    customComponents.removeAt(index);

    floors[_currentFloorIndex] = currentFloor!.copyWith(
      customComponents: customComponents,
    );

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  // Photo methods for Custom Component (existing)
  Future<void> addPhotoToCustomComponent(
    int componentIndex,
    File imageFile,
    String comment,
  ) async {
    await _addPhotoToComponent(
      componentIndex,
      imageFile,
      comment,
      'CustomComponent',
    );
  }

  void updatePhotoComment(int componentIndex, int photoIndex, String comment) {
    _updateComponentPhotoComment(
      componentIndex,
      photoIndex,
      comment,
      'CustomComponent',
    );
  }

  Future<void> removePhotoFromCustomComponent(
    int componentIndex,
    int photoIndex,
  ) async {
    await _removePhotoFromComponent(
      componentIndex,
      photoIndex,
      'CustomComponent',
    );
  }

  // Generic photo management methods
  Future<void> _addPhotoToComponent(
    int componentIndex,
    File imageFile,
    String comment,
    String componentType,
  ) async {
    if (_currentReport == null || currentFloor == null || componentIndex < 0) {
      _setError('Invalid component or report state');
      return;
    }

    _setLoading(true);

    try {
      final tempPhoto = Photo.create(
        localPath: imageFile.path,
        comment: comment,
      );

      String componentId;
      switch (componentType) {
        case 'NetworkCabinet':
          if (componentIndex >= currentFloor!.networkCabinets.length) return;
          componentId = currentFloor!.networkCabinets[componentIndex].id;
          break;
        case 'Perforation':
          if (componentIndex >= currentFloor!.perforations.length) return;
          componentId = currentFloor!.perforations[componentIndex].id;
          break;
        case 'AccessTrap':
          if (componentIndex >= currentFloor!.accessTraps.length) return;
          componentId = currentFloor!.accessTraps[componentIndex].id;
          break;
        case 'CablePath':
          if (componentIndex >= currentFloor!.cablePaths.length) return;
          componentId = currentFloor!.cablePaths[componentIndex].id;
          break;
        case 'CableTrunking':
          if (componentIndex >= currentFloor!.cableTrunkings.length) return;
          componentId = currentFloor!.cableTrunkings[componentIndex].id;
          break;
        case 'Conduit':
          if (componentIndex >= currentFloor!.conduits.length) return;
          componentId = currentFloor!.conduits[componentIndex].id;
          break;
        case 'CopperCabling':
          if (componentIndex >= currentFloor!.copperCablings.length) return;
          componentId = currentFloor!.copperCablings[componentIndex].id;
          break;
        case 'FiberOpticCabling':
          if (componentIndex >= currentFloor!.fiberOpticCablings.length) return;
          componentId = currentFloor!.fiberOpticCablings[componentIndex].id;
          break;
        case 'CustomComponent':
          if (componentIndex >= currentFloor!.customComponents.length) return;
          componentId = currentFloor!.customComponents[componentIndex].id;
          break;
        default:
          _setError('Unknown component type: $componentType');
          return;
      }

      final photoUrl = await UniversalPhotoService.instance.uploadPhoto(
        imageFile: imageFile,
        reportId: _currentReport!.id,
        componentId: componentId,
        photoId: tempPhoto.id,
        onProgress: (progress) {
          // Progress callback
        },
      );

      final photo = tempPhoto.copyWith(url: photoUrl);
      _updateComponentWithPhoto(componentIndex, componentType, photo);

      await _autoSave();
      _markAsChanged();
      notifyListeners();
    } catch (e) {
      _setError('Failed to upload photo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _updateComponentPhotoComment(
    int componentIndex,
    int photoIndex,
    String comment,
    String componentType,
  ) {
    if (_currentReport == null ||
        currentFloor == null ||
        componentIndex < 0 ||
        photoIndex < 0)
      return;

    final floors = List<Floor>.from(_currentReport!.floors);

    switch (componentType) {
      case 'NetworkCabinet':
        if (componentIndex >= currentFloor!.networkCabinets.length) return;
        final cabinets = List<NetworkCabinet>.from(
          currentFloor!.networkCabinets,
        );
        final cabinet = cabinets[componentIndex];
        if (photoIndex >= cabinet.photos.length) return;
        final photo = cabinet.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        cabinets[componentIndex] = cabinet.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          networkCabinets: cabinets,
        );
        break;
      case 'Perforation':
        if (componentIndex >= currentFloor!.perforations.length) return;
        final perforations = List<Perforation>.from(currentFloor!.perforations);
        final perforation = perforations[componentIndex];
        if (photoIndex >= perforation.photos.length) return;
        final photo = perforation.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        perforations[componentIndex] = perforation.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          perforations: perforations,
        );
        break;
      case 'AccessTrap':
        if (componentIndex >= currentFloor!.accessTraps.length) return;
        final accessTraps = List<AccessTrap>.from(currentFloor!.accessTraps);
        final accessTrap = accessTraps[componentIndex];
        if (photoIndex >= accessTrap.photos.length) return;
        final photo = accessTrap.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        accessTraps[componentIndex] = accessTrap.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          accessTraps: accessTraps,
        );
        break;
      case 'CablePath':
        if (componentIndex >= currentFloor!.cablePaths.length) return;
        final cablePaths = List<CablePath>.from(currentFloor!.cablePaths);
        final cablePath = cablePaths[componentIndex];
        if (photoIndex >= cablePath.photos.length) return;
        final photo = cablePath.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        cablePaths[componentIndex] = cablePath.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          cablePaths: cablePaths,
        );
        break;
      case 'CableTrunking':
        if (componentIndex >= currentFloor!.cableTrunkings.length) return;
        final cableTrunkings = List<CableTrunking>.from(
          currentFloor!.cableTrunkings,
        );
        final cableTrunking = cableTrunkings[componentIndex];
        if (photoIndex >= cableTrunking.photos.length) return;
        final photo = cableTrunking.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        cableTrunkings[componentIndex] = cableTrunking.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          cableTrunkings: cableTrunkings,
        );
        break;
      case 'Conduit':
        if (componentIndex >= currentFloor!.conduits.length) return;
        final conduits = List<Conduit>.from(currentFloor!.conduits);
        final conduit = conduits[componentIndex];
        if (photoIndex >= conduit.photos.length) return;
        final photo = conduit.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        conduits[componentIndex] = conduit.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(conduits: conduits);
        break;
      case 'CopperCabling':
        if (componentIndex >= currentFloor!.copperCablings.length) return;
        final copperCablings = List<CopperCabling>.from(
          currentFloor!.copperCablings,
        );
        final copperCabling = copperCablings[componentIndex];
        if (photoIndex >= copperCabling.photos.length) return;
        final photo = copperCabling.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        copperCablings[componentIndex] = copperCabling.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          copperCablings: copperCablings,
        );
        break;
      case 'FiberOpticCabling':
        if (componentIndex >= currentFloor!.fiberOpticCablings.length) return;
        final fiberOpticCablings = List<FiberOpticCabling>.from(
          currentFloor!.fiberOpticCablings,
        );
        final fiberOpticCabling = fiberOpticCablings[componentIndex];
        if (photoIndex >= fiberOpticCabling.photos.length) return;
        final photo = fiberOpticCabling.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        fiberOpticCablings[componentIndex] = fiberOpticCabling.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          fiberOpticCablings: fiberOpticCablings,
        );
        break;
      case 'CustomComponent':
        if (componentIndex >= currentFloor!.customComponents.length) return;
        final customComponents = List<CustomComponent>.from(
          currentFloor!.customComponents,
        );
        final customComponent = customComponents[componentIndex];
        if (photoIndex >= customComponent.photos.length) return;
        final photo = customComponent.photos[photoIndex];
        final updatedPhoto = photo.copyWith(comment: comment);
        customComponents[componentIndex] = customComponent.updatePhoto(
          photoIndex,
          updatedPhoto,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          customComponents: customComponents,
        );
        break;
      default:
        return;
    }

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    _autoSave();
    _markAsChanged();
    notifyListeners();
  }

  Future<void> _removePhotoFromComponent(
    int componentIndex,
    int photoIndex,
    String componentType,
  ) async {
    if (_currentReport == null ||
        currentFloor == null ||
        componentIndex < 0 ||
        photoIndex < 0)
      return;

    _setLoading(true);

    try {
      String? photoUrl;

      // Get photo URL for deletion
      switch (componentType) {
        case 'NetworkCabinet':
          if (componentIndex >= currentFloor!.networkCabinets.length) return;
          final cabinet = currentFloor!.networkCabinets[componentIndex];
          if (photoIndex >= cabinet.photos.length) return;
          photoUrl = cabinet.photos[photoIndex].url;
          break;
        case 'Perforation':
          if (componentIndex >= currentFloor!.perforations.length) return;
          final perforation = currentFloor!.perforations[componentIndex];
          if (photoIndex >= perforation.photos.length) return;
          photoUrl = perforation.photos[photoIndex].url;
          break;
        case 'AccessTrap':
          if (componentIndex >= currentFloor!.accessTraps.length) return;
          final accessTrap = currentFloor!.accessTraps[componentIndex];
          if (photoIndex >= accessTrap.photos.length) return;
          photoUrl = accessTrap.photos[photoIndex].url;
          break;
        case 'CablePath':
          if (componentIndex >= currentFloor!.cablePaths.length) return;
          final cablePath = currentFloor!.cablePaths[componentIndex];
          if (photoIndex >= cablePath.photos.length) return;
          photoUrl = cablePath.photos[photoIndex].url;
          break;
        case 'CableTrunking':
          if (componentIndex >= currentFloor!.cableTrunkings.length) return;
          final cableTrunking = currentFloor!.cableTrunkings[componentIndex];
          if (photoIndex >= cableTrunking.photos.length) return;
          photoUrl = cableTrunking.photos[photoIndex].url;
          break;
        case 'Conduit':
          if (componentIndex >= currentFloor!.conduits.length) return;
          final conduit = currentFloor!.conduits[componentIndex];
          if (photoIndex >= conduit.photos.length) return;
          photoUrl = conduit.photos[photoIndex].url;
          break;
        case 'CopperCabling':
          if (componentIndex >= currentFloor!.copperCablings.length) return;
          final copperCabling = currentFloor!.copperCablings[componentIndex];
          if (photoIndex >= copperCabling.photos.length) return;
          photoUrl = copperCabling.photos[photoIndex].url;
          break;
        case 'FiberOpticCabling':
          if (componentIndex >= currentFloor!.fiberOpticCablings.length) return;
          final fiberOpticCabling =
              currentFloor!.fiberOpticCablings[componentIndex];
          if (photoIndex >= fiberOpticCabling.photos.length) return;
          photoUrl = fiberOpticCabling.photos[photoIndex].url;
          break;
        case 'CustomComponent':
          if (componentIndex >= currentFloor!.customComponents.length) return;
          final customComponent =
              currentFloor!.customComponents[componentIndex];
          if (photoIndex >= customComponent.photos.length) return;
          photoUrl = customComponent.photos[photoIndex].url;
          break;
        default:
          return;
      }

      // Delete photo from storage
      if (photoUrl.isNotEmpty) {
        try {
          await UniversalPhotoService.instance.deletePhoto(photoUrl);
        } catch (e) {
          // Silent fail for photo deletion
        }
      }

      // Remove photo from component
      final floors = List<Floor>.from(_currentReport!.floors);

      switch (componentType) {
        case 'NetworkCabinet':
          final cabinets = List<NetworkCabinet>.from(
            currentFloor!.networkCabinets,
          );
          cabinets[componentIndex] = cabinets[componentIndex].removePhoto(
            photoIndex,
          );
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            networkCabinets: cabinets,
          );
          break;
        case 'Perforation':
          final perforations = List<Perforation>.from(
            currentFloor!.perforations,
          );
          perforations[componentIndex] = perforations[componentIndex]
              .removePhoto(photoIndex);
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            perforations: perforations,
          );
          break;
        case 'AccessTrap':
          final accessTraps = List<AccessTrap>.from(currentFloor!.accessTraps);
          accessTraps[componentIndex] = accessTraps[componentIndex].removePhoto(
            photoIndex,
          );
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            accessTraps: accessTraps,
          );
          break;
        case 'CablePath':
          final cablePaths = List<CablePath>.from(currentFloor!.cablePaths);
          cablePaths[componentIndex] = cablePaths[componentIndex].removePhoto(
            photoIndex,
          );
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            cablePaths: cablePaths,
          );
          break;
        case 'CableTrunking':
          final cableTrunkings = List<CableTrunking>.from(
            currentFloor!.cableTrunkings,
          );
          cableTrunkings[componentIndex] = cableTrunkings[componentIndex]
              .removePhoto(photoIndex);
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            cableTrunkings: cableTrunkings,
          );
          break;
        case 'Conduit':
          final conduits = List<Conduit>.from(currentFloor!.conduits);
          conduits[componentIndex] = conduits[componentIndex].removePhoto(
            photoIndex,
          );
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            conduits: conduits,
          );
          break;
        case 'CopperCabling':
          final copperCablings = List<CopperCabling>.from(
            currentFloor!.copperCablings,
          );
          copperCablings[componentIndex] = copperCablings[componentIndex]
              .removePhoto(photoIndex);
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            copperCablings: copperCablings,
          );
          break;
        case 'FiberOpticCabling':
          final fiberOpticCablings = List<FiberOpticCabling>.from(
            currentFloor!.fiberOpticCablings,
          );
          fiberOpticCablings[componentIndex] =
              fiberOpticCablings[componentIndex].removePhoto(photoIndex);
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            fiberOpticCablings: fiberOpticCablings,
          );
          break;
        case 'CustomComponent':
          final customComponents = List<CustomComponent>.from(
            currentFloor!.customComponents,
          );
          customComponents[componentIndex] = customComponents[componentIndex]
              .removePhoto(photoIndex);
          floors[_currentFloorIndex] = currentFloor!.copyWith(
            customComponents: customComponents,
          );
          break;
        default:
          return;
      }

      _currentReport = _currentReport!.copyWith(
        floors: floors,
        lastModified: DateTime.now(),
      );

      await _autoSave();
      _markAsChanged();
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove photo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _updateComponentWithPhoto(
    int componentIndex,
    String componentType,
    Photo photo,
  ) {
    if (_currentReport == null || currentFloor == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);

    switch (componentType) {
      case 'NetworkCabinet':
        if (componentIndex >= currentFloor!.networkCabinets.length) return;
        final cabinets = List<NetworkCabinet>.from(
          currentFloor!.networkCabinets,
        );
        cabinets[componentIndex] = cabinets[componentIndex].addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          networkCabinets: cabinets,
        );
        break;
      case 'Perforation':
        if (componentIndex >= currentFloor!.perforations.length) return;
        final perforations = List<Perforation>.from(currentFloor!.perforations);
        perforations[componentIndex] = perforations[componentIndex].addPhoto(
          photo,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          perforations: perforations,
        );
        break;
      case 'AccessTrap':
        if (componentIndex >= currentFloor!.accessTraps.length) return;
        final accessTraps = List<AccessTrap>.from(currentFloor!.accessTraps);
        accessTraps[componentIndex] = accessTraps[componentIndex].addPhoto(
          photo,
        );
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          accessTraps: accessTraps,
        );
        break;
      case 'CablePath':
        if (componentIndex >= currentFloor!.cablePaths.length) return;
        final cablePaths = List<CablePath>.from(currentFloor!.cablePaths);
        cablePaths[componentIndex] = cablePaths[componentIndex].addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          cablePaths: cablePaths,
        );
        break;
      case 'CableTrunking':
        if (componentIndex >= currentFloor!.cableTrunkings.length) return;
        final cableTrunkings = List<CableTrunking>.from(
          currentFloor!.cableTrunkings,
        );
        cableTrunkings[componentIndex] = cableTrunkings[componentIndex]
            .addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          cableTrunkings: cableTrunkings,
        );
        break;
      case 'Conduit':
        if (componentIndex >= currentFloor!.conduits.length) return;
        final conduits = List<Conduit>.from(currentFloor!.conduits);
        conduits[componentIndex] = conduits[componentIndex].addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(conduits: conduits);
        break;
      case 'CopperCabling':
        if (componentIndex >= currentFloor!.copperCablings.length) return;
        final copperCablings = List<CopperCabling>.from(
          currentFloor!.copperCablings,
        );
        copperCablings[componentIndex] = copperCablings[componentIndex]
            .addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          copperCablings: copperCablings,
        );
        break;
      case 'FiberOpticCabling':
        if (componentIndex >= currentFloor!.fiberOpticCablings.length) return;
        final fiberOpticCablings = List<FiberOpticCabling>.from(
          currentFloor!.fiberOpticCablings,
        );
        fiberOpticCablings[componentIndex] = fiberOpticCablings[componentIndex]
            .addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          fiberOpticCablings: fiberOpticCablings,
        );
        break;
      case 'CustomComponent':
        if (componentIndex >= currentFloor!.customComponents.length) return;
        final customComponents = List<CustomComponent>.from(
          currentFloor!.customComponents,
        );
        customComponents[componentIndex] = customComponents[componentIndex]
            .addPhoto(photo);
        floors[_currentFloorIndex] = currentFloor!.copyWith(
          customComponents: customComponents,
        );
        break;
      default:
        return;
    }

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );
  }

  void addComponentByType(String type) {
    switch (type) {
      case 'Baie Informatique':
        addNetworkCabinet();
        break;
      case 'Percement':
        addPerforation();
        break;
      case 'Trappe d\'accès':
        addAccessTrap();
        break;
      case 'Chemin de câbles':
        addCablePath();
        break;
      case 'Goulotte':
        addCableTrunking();
        break;
      case 'Conduit':
        addConduit();
        break;
      case 'Câblage cuivre':
        addCopperCabling();
        break;
      case 'Câblage fibre optique':
        addFiberOpticCabling();
        break;
      case 'Composant personnalisé':
        addCustomComponent();
        break;
      default:
        _setError('Unknown component type: $type');
    }
  }

  void updateBasicInfo({
    DateTime? date,
    String? clientName,
    String? location,
    String? projectManager,
    List<String>? technicians,
    String? accompanyingPerson,
  }) {
    if (_currentReport == null) return;

    _currentReport = _currentReport!.copyWith(
      date: date,
      clientName: clientName,
      location: location,
      projectManager: projectManager,
      technicians: technicians,
      accompanyingPerson: accompanyingPerson,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void updateProjectContext(String context) {
    if (_currentReport == null) return;

    _currentReport = _currentReport!.copyWith(
      projectContext: context,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  void updateConclusion({
    String? conclusion,
    int? estimatedDurationDays,
    List<String>? assumptions,
  }) {
    if (_currentReport == null) return;

    _currentReport = _currentReport!.copyWith(
      conclusion: conclusion,
      estimatedDurationDays: estimatedDurationDays,
      assumptions: assumptions,
      lastModified: DateTime.now(),
    );

    _markAsChanged();
    notifyListeners();
  }

  bool validateAllSections() {
    if (_currentReport == null) return false;

    final basicInfoValid =
        _currentReport!.clientName.isNotEmpty &&
        _currentReport!.location.isNotEmpty &&
        _currentReport!.projectManager.isNotEmpty &&
        _currentReport!.technicians.isNotEmpty;

    if (!basicInfoValid) return false;

    if (_currentReport!.projectContext.isEmpty) return false;

    final hasComponents =
        _currentReport!.floors.isNotEmpty &&
        _currentReport!.floors.any((floor) => floor.hasComponents);
    if (!hasComponents) return false;

    if (_currentReport!.conclusion.isEmpty) return false;

    return true;
  }

  bool isConclusionValid() {
    if (_currentReport == null) return false;
    return _currentReport!.conclusion.isNotEmpty &&
        _currentReport!.estimatedDurationDays > 0;
  }

  bool isBasicInfoValid() {
    if (_currentReport == null) return false;
    return _currentReport!.clientName.isNotEmpty &&
        _currentReport!.location.isNotEmpty &&
        _currentReport!.projectManager.isNotEmpty &&
        _currentReport!.technicians.isNotEmpty;
  }

  bool isProjectContextValid() {
    if (_currentReport == null) return false;
    return _currentReport!.projectContext.isNotEmpty;
  }

  bool isComponentsValid() {
    if (_currentReport == null) return false;
    return _currentReport!.floors.isNotEmpty &&
        _currentReport!.floors.any((floor) => floor.hasComponents);
  }

  bool isStepComplete(int step) {
    if (_currentReport == null) return false;

    switch (step) {
      case 0:
        return isBasicInfoValid();
      case 1:
        return isProjectContextValid();
      case 2:
        return isComponentsValid();
      case 3:
        return isConclusionValid();
      default:
        return false;
    }
  }

  bool _isNewReport() {
    return _currentReport?.id.isEmpty ?? true;
  }

  void _markAsChanged() {
    _hasUnsavedChanges = true;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await UniversalPhotoService.instance.deleteReportPhotos(reportId);
      await _reportService.deleteReport(reportId);
    } catch (e) {
      _setError('Failed to delete report: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
