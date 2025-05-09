// lib/view_models/technical_visit_report_view_model.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
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
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart'; // Correct import
import '../services/pdf_generation_service.dart';

/// ViewModel for creating and managing technical visit reports.
///
/// This ViewModel implements the floor-based organization approach, allowing users
/// to create and manage floors with multiple component types in each floor.
/// It handles all business logic for the report creation workflow, including:
/// - Loading and saving reports
/// - Managing floor navigation
/// - Adding/updating/removing technical components
/// - Validation of report data
///
/// Follows MVVM architectural pattern with unidirectional data flow:
/// 1. UI events trigger ViewModel methods
/// 2. ViewModel updates models and notifies listeners
/// 3. UI rebuilds based on ViewModel state changes
class TechnicalVisitReportViewModel extends ChangeNotifier {
  // Services for persistence and authentication
  final TechnicalVisitReportService _reportService;
  final AuthService _authService;
  final PdfGenerationService _pdfService;

  // Current report being edited
  TechnicalVisitReport? _currentReport;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;
  int _currentFloorIndex = 0;
  String? _selectedComponentType;

  // Possible component types that can be added to a floor
  final List<String> componentTypes = [
    'Baie Informatique',
    'Percement',
    'Trappe d\'accès',
    'Chemin de câbles',
    'Goulotte',
    'Conduit',
    'Câblage cuivre',
    'Câblage fibre optique',
  ];

  // Getters to expose state to the UI layer
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

  /// Constructor with dependency injection for services
  ///
  /// Follows dependency inversion principle by accepting service interfaces
  /// rather than concrete implementations.
  // Update the constructor to include PdfGenerationService
  TechnicalVisitReportViewModel({
    required TechnicalVisitReportService reportService,
    required AuthService authService,
    required PdfGenerationService pdfService, // Add this line
  }) : _reportService = reportService,
       _authService = authService,
       _pdfService = pdfService; // Add this line

  /// Initialize a new draft report
  ///
  /// Creates a new draft report with default values and the current user's information.
  /// Sets the current step to the first step and initializes with a default floor.
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
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize new report: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load an existing report for editing
  ///
  /// Retrieves a report from the service by ID and initializes the ViewModel state.
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
      notifyListeners();
    } catch (e) {
      _setError('Failed to load report: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save the current report as a draft
  ///
  /// Persists the current report state to the service, creating a new report
  /// if it's a new draft or updating an existing one.
  /// Save the current report as a draft
  ///
  /// Persists the current report state to the service, creating a new report
  /// if it's a new draft or updating an existing one.
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
      debugPrint('Saving draft report with ID: ${updatedReport.id}');
      if (_isNewReport()) {
        debugPrint('Creating new draft report in Firestore');
        await _reportService.createReport(updatedReport);
        debugPrint('New draft saved successfully with ID: ${updatedReport.id}');
      } else {
        debugPrint('Updating existing draft report in Firestore');
        await _reportService.updateReport(updatedReport);
        debugPrint('Draft updated successfully with ID: ${updatedReport.id}');
      }
      _currentReport = updatedReport;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving draft: $e');
      _setError('Failed to save draft: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Submit the completed report
  ///
  /// Changes the report status to 'submitted', generates a PDF,
  /// saves it, and updates the UI accordingly.
  /// Validates that all required fields are completed before submission.
  // In TechnicalVisitReportViewModel
  // In TechnicalVisitReportViewModel class - update the submitReport method

  Future<bool> submitReport() async {
    if (_currentReport == null) {
      _setError('No report to submit');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Perform validation
      if (!validateAllSections()) {
        _setError('Veuillez compléter toutes les sections requises');
        return false;
      }

      debugPrint('Preparing submission for report ID: ${_currentReport!.id}');

      // First ensure the report exists in Firestore by saving it
      await _reportService.createReport(_currentReport!);
      debugPrint('Ensured report exists in Firestore');

      // Critical: Create a fully prepared report with all changes in a single object
      final reportToSubmit = _currentReport!.copyWith(
        status: 'submitted',
        submittedAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      // Log the operation for debugging
      debugPrint('Submitting report with status: ${reportToSubmit.status}');

      // SINGLE ATOMIC OPERATION: This must match your security rules expectations
      await _reportService.updateReport(reportToSubmit);
      debugPrint('Report successfully submitted to Firestore');

      // Update local state after successful submission
      _currentReport = reportToSubmit;

      // Handle PDF generation separately
      try {
        debugPrint('Starting PDF generation');
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
            debugPrint('Error opening PDF: $e');
          }
        }
      } catch (pdfError) {
        debugPrint(
          'PDF generation failed but report was successfully submitted: $pdfError',
        );
      }

      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors with better messages
      String errorMsg;

      if (e.code == 'not-found') {
        errorMsg =
            'Le rapport n\'existe pas dans la base de données. Veuillez d\'abord l\'enregistrer comme brouillon.';
      } else if (e.code == 'permission-denied') {
        errorMsg =
            'Vous n\'avez pas les permissions nécessaires pour cette action.';
      } else {
        errorMsg = 'Erreur Firebase lors de la soumission: ${e.message}';
      }

      debugPrint(errorMsg);
      _setError(errorMsg);
      return false;
    } catch (e) {
      final errorMsg = 'Erreur lors de la soumission du rapport: $e';
      debugPrint(errorMsg);
      _setError(errorMsg);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  // Refresh the current report

  /// Get all draft reports for the current technician
  ///
  /// Returns a stream of reports with 'draft' status for the current user.
  /// Get all draft reports for the current technician
  ///
  /// Returns a stream of reports with 'draft' status for the current user.
  Stream<List<TechnicalVisitReport>> getDraftReportsStream() {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint(
        'User is not authenticated, returning empty draft reports stream',
      );
      return Stream.value([]);
    }
    debugPrint('Fetching draft reports stream for user: ${user.uid}');
    return _reportService.getDraftReportsStream(user.uid);
  }

  /// Get all submitted reports for the current technician
  ///
  /// Returns a stream of reports with non-draft status for the current user.
  Stream<List<TechnicalVisitReport>> getSubmittedReportsStream() {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint(
        'User is not authenticated, returning empty submitted reports stream',
      );
      return Stream.value([]);
    }
    debugPrint('Fetching submitted reports stream for user: ${user.uid}');
    return _reportService.getSubmittedReportsStream(user.uid);
  }

  /// Navigate to a specific step in the report form
  ///
  /// Updates the current step index and triggers UI update.
  void navigateToStep(int step) {
    if (step >= 0 && step <= 6) {
      // Assuming 7 steps total (0-6)
      _currentStep = step;
      notifyListeners();
    }
  }

  /// Move to the next step in the report form
  ///
  /// Increments the current step index if not at the last step.
  /// Returns true if navigation was successful.
  bool nextStep() {
    if (_currentStep < 6) {
      // Assuming 7 steps total (0-6)
      _currentStep++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Move to the previous step in the report form
  ///
  /// Decrements the current step index if not at the first step.
  /// Returns true if navigation was successful.
  bool previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Set the current floor index
  ///
  /// Updates which floor is currently being edited and resets the selected component type.
  void setCurrentFloorIndex(int index) {
    if (_currentReport != null &&
        index >= 0 &&
        index < _currentReport!.floors.length) {
      _currentFloorIndex = index;
      _selectedComponentType =
          null; // Reset selected component when floor changes
      notifyListeners();
    }
  }

  /// Set the selected component type
  ///
  /// Updates which component type is currently selected for adding to the floor.
  void setSelectedComponentType(String? type) {
    _selectedComponentType = type;
    notifyListeners();
  }

  /// Add a new floor to the report
  ///
  /// Creates a new floor with a default name based on floor number and adds it to the report.
  /// Updates the current floor index to the newly added floor.
  void addFloor() {
    if (_currentReport == null) return;

    final floors = List<Floor>.from(_currentReport!.floors);
    final floorNumber = floors.length + 1;

    // Generate a more natural floor name based on number
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

    // Switch to the newly added floor
    _currentFloorIndex = floors.length - 1;
    _selectedComponentType = null;

    notifyListeners();
  }

  /// Update a floor's name
  ///
  /// Changes the name of the floor at the specified index.
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

    notifyListeners();
  }

  /// Delete a floor
  ///
  /// Removes the floor at the specified index from the report.
  /// Ensures at least one floor always remains in the report.
  /// Adjusts the current floor index if needed.
  void deleteFloor(int index) {
    if (_currentReport == null ||
        index < 0 ||
        index >= _currentReport!.floors.length ||
        _currentReport!.floors.length <= 1) // Keep at least one floor
      return;

    final floors = List<Floor>.from(_currentReport!.floors);
    floors.removeAt(index);

    _currentReport = _currentReport!.copyWith(
      floors: floors,
      lastModified: DateTime.now(),
    );

    // Adjust current floor index if needed
    if (_currentFloorIndex >= floors.length) {
      _currentFloorIndex = floors.length - 1;
    }

    notifyListeners();
  }

  /// Add a network cabinet to the current floor
  ///
  /// Creates a new network cabinet with default values and adds it to the current floor.
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

    notifyListeners();
  }

  /// Update a network cabinet in the current floor
  ///
  /// Replaces the network cabinet at the specified index with the updated version.
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

    notifyListeners();
  }

  /// Remove a network cabinet from the current floor
  /// /// Remove a network cabinet from the current floor
  ///
  /// Deletes the network cabinet at the specified index from the current floor.
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

    notifyListeners();
  }

  /// Add a perforation to the current floor
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

    notifyListeners();
  }

  /// Update a perforation in the current floor
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

    notifyListeners();
  }

  /// Remove a perforation from the current floor
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

    notifyListeners();
  }

  /// Add an access trap to the current floor
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

    notifyListeners();
  }

  /// Update an access trap in the current floor
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

    notifyListeners();
  }

  /// Remove an access trap from the current floor
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

    notifyListeners();
  }

  /// Add a cable path to the current floor
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

    notifyListeners();
  }

  /// Update a cable path in the current floor
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

    notifyListeners();
  }

  /// Remove a cable path from the current floor
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

    notifyListeners();
  }

  /// Add a cable trunking to the current floor
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

    notifyListeners();
  }

  /// Update a cable trunking in the current floor
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

    notifyListeners();
  }

  /// Remove a cable trunking from the current floor
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

    notifyListeners();
  }

  /// Add a conduit to the current floor
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

    notifyListeners();
  }

  /// Update a conduit in the current floor
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

    notifyListeners();
  }

  /// Remove a conduit from the current floor
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

    notifyListeners();
  }

  /// Add copper cabling to the current floor
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

    notifyListeners();
  }

  /// Update copper cabling in the current floor
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

    notifyListeners();
  }

  /// Remove copper cabling from the current floor
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

    notifyListeners();
  }

  /// Add fiber optic cabling to the current floor
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

    notifyListeners();
  }

  /// Update fiber optic cabling in the current floor
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

    notifyListeners();
  }

  /// Remove fiber optic cabling from the current floor
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

    notifyListeners();
  }

  /// Add a component based on the selected type
  ///
  /// This method acts as a factory method pattern implementation that centralizes
  /// the creation logic for all component types based on a string identifier.
  /// It maps the human-readable component type name to the appropriate add method.
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
      default:
        // Unknown component type, log error or handle appropriately
        _setError('Unknown component type: $type');
    }
  }

  /// Update basic information of the report
  ///
  /// Updates general information fields for the report.
  /// Uses named parameters for flexibility and clarity.
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

    notifyListeners();
  }

  /// Update the project context section
  ///
  /// Updates the detailed description of the project context.
  void updateProjectContext(String context) {
    if (_currentReport == null) return;

    _currentReport = _currentReport!.copyWith(
      projectContext: context,
      lastModified: DateTime.now(),
    );

    notifyListeners();
  }

  /// Update conclusion section
  ///
  /// Updates the conclusion fields including estimated duration and assumptions.
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

    notifyListeners();
  }

  /// Helper method to check if this is a completely new report
  ///
  /// Determines if the report is being created for the first time by
  /// comparing creation and modification timestamps.
  /// Helper method to check if this is a completely new report
  ///
  /// Determines if the report is being created for the first time by
  /// comparing creation and modification timestamps.
  bool _isNewReport() {
    // If report has an empty ID or hasn't been saved to Firestore yet
    return _currentReport?.id.isEmpty ?? true;
  }

  /// Validate all required sections of the report
  ///
  /// Performs comprehensive validation across report sections
  /// to ensure all required fields are completed.
  bool validateAllSections() {
    if (_currentReport == null) return false;

    // Basic validation - check that essential fields are non-empty
    final basicInfoValid =
        _currentReport!.clientName.isNotEmpty &&
        _currentReport!.location.isNotEmpty &&
        _currentReport!.projectManager.isNotEmpty &&
        _currentReport!.technicians.isNotEmpty;

    if (!basicInfoValid) return false;

    // Validate project context
    if (_currentReport!.projectContext.isEmpty) return false;

    // Validate floor-based components
    final hasComponents =
        _currentReport!.floors.isNotEmpty &&
        _currentReport!.floors.any((floor) => floor.hasComponents);
    if (!hasComponents) return false;

    // Validate conclusion
    if (_currentReport!.conclusion.isEmpty) return false;

    // All sections valid
    return true;
  }

  bool isConclusionValid() {
    if (_currentReport == null) return false;

    // Validate conclusion section
    return _currentReport!.conclusion.isNotEmpty &&
        _currentReport!.estimatedDurationDays > 0;
  }

  bool isBasicInfoValid() {
    if (_currentReport == null) return false;

    // Validate basic information fields
    return _currentReport!.clientName.isNotEmpty &&
        _currentReport!.location.isNotEmpty &&
        _currentReport!.projectManager.isNotEmpty &&
        _currentReport!.technicians.isNotEmpty;
  }

  bool isProjectContextValid() {
    if (_currentReport == null) return false;

    // Validate project context
    return _currentReport!.projectContext.isNotEmpty;
  }

  bool isComponentsValid() {
    if (_currentReport == null) return false;

    // Validate that we have at least one floor with components
    return _currentReport!.floors.isNotEmpty &&
        _currentReport!.floors.any((floor) => floor.hasComponents);
  }

  bool isStepComplete(int step) {
    if (_currentReport == null) return false;

    switch (step) {
      case 0: // Basic info step
        return isBasicInfoValid();
      case 1: // Project context step
        return isProjectContextValid();
      case 2: // Floor components step
        return isComponentsValid();
      case 3: // Conclusion step
        return isConclusionValid();
      default:
        return false;
    }
  }

  /// Helper method to set loading state
  ///
  /// Updates the loading indicator state and notifies listeners.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Helper method to set error message
  ///
  /// Updates the error message state and notifies listeners.
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Helper method to clear error message
  ///
  /// Clears any existing error message and notifies listeners.
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
