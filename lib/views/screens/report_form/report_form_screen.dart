// lib/views/screens/report_form/report_form_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../../utils/notification_utils.dart';
import '../../widgets/report_form/form_text_field.dart';
import 'floor_components_form.dart';
import '../../widgets/report_form/form_dropdown.dart';
import '../../widgets/report_form/form_checkbox.dart';
import '../../widgets/report_form/section_header.dart';
import '../../widgets/report_form/floor_selector.dart';
import '../../widgets/report_form/component_type_selector.dart';
import '../../widgets/report_form/dynamic_list_section.dart';
import '../../widgets/report_form/form_number_field.dart';
import '../../../models/report_sections/network_cabinet.dart';
import '../../../models/report_sections/perforation.dart';
import '../../../models/report_sections/access_trap.dart';
import '../../../models/report_sections/cable_path.dart';
import '../../../models/report_sections/cable_trunking.dart';
import '../../../models/report_sections/conduit.dart';
import '../../../models/report_sections/copper_cabling.dart';
import '../../../models/report_sections/fiber_optic_cabling.dart';
import '../../../models/report_sections/custom_component.dart';
import '../../widgets/report_form/component_photo_section.dart';
import '../../widgets/custom_notification.dart';

class ReportFormScreen extends StatefulWidget {
  final String? reportId;

  const ReportFormScreen({super.key, this.reportId});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _componentsScrollController;
  String? _actualReportId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the report ID from route arguments if not passed directly
    if (_actualReportId == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _actualReportId = widget.reportId ?? args?['reportId'];

      debugPrint('=== REPORT FORM ARGUMENTS ===');
      debugPrint('Widget reportId: ${widget.reportId}');
      debugPrint('Route arguments: $args');
      debugPrint('Final reportId: $_actualReportId');
      debugPrint('=============================');
    }
  }

  // Add overlay entry for custom notification
  OverlayEntry? _notificationOverlay;

  // Floor selector visibility state
  bool _showFloatingFloorSelector = false;

  void _showValidationError(String message) {
    _showCustomNotification(message, Icons.warning, Colors.orange);
  }

  void _showCustomNotification(String message, IconData icon, Color color) {
    // Remove existing overlay if any
    _notificationOverlay?.remove();

    _notificationOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 80, // Below the header
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_notificationOverlay!);

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _notificationOverlay?.remove();
      _notificationOverlay = null;
    });
  }

  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  // Form controllers
  final _clientNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _projectManagerController = TextEditingController();
  final _accompanyingPersonController = TextEditingController();
  final _projectContextController = TextEditingController();
  final _conclusionController = TextEditingController();
  final _assumptionController = TextEditingController();

  final List<String> _technicians = [];
  final List<String> _assumptions = [];
  int _estimatedDays = 1;

  @override
  void initState() {
    super.initState();
    _hasPopulatedForm = false; // Reset the flag
    _pageController = PageController();
    _componentsScrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Add scroll listener for components step
    _componentsScrollController.addListener(_onComponentsScroll);

    _initializeReport();
    _animationController.forward();

    // Check if we need to populate form after everything is set up
    _checkAndPopulateForm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReport();
    });
  }

  void _onComponentsScroll() {
    if (_currentStep == 2) {
      // Components step
      // Show floating floor selector when scrolled down
      final shouldShow = _componentsScrollController.offset > 100;
      if (shouldShow != _showFloatingFloorSelector) {
        setState(() {
          _showFloatingFloorSelector = shouldShow;
        });
      }
    }
  }

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _pageController.dispose();
    _componentsScrollController.dispose();
    _animationController.dispose();
    _clientNameController.dispose();
    _locationController.dispose();
    _projectManagerController.dispose();
    _accompanyingPersonController.dispose();
    _projectContextController.dispose();
    _conclusionController.dispose();
    _assumptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeReport() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);

    try {
      if (_actualReportId != null && _actualReportId!.isNotEmpty) {
        // Load existing report (could be draft or submitted)
        debugPrint('Loading existing report with ID: $_actualReportId');
        await viewModel.loadReport(_actualReportId!);

        // Schedule form population for after the current build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final report = viewModel.currentReport;
          if (report != null && mounted) {
            debugPrint(
              'Report loaded successfully: ${report.clientName}, Status: ${report.status}',
            );
            _populateFormFieldsSimple(viewModel);
          } else {
            debugPrint('Report failed to load or is null');
          }
        });
      } else {
        // Create new report
        debugPrint('Creating new report (no ID provided)');
        await viewModel.initNewReport();
      }
    } catch (e) {
      debugPrint('Error initializing report: $e');
      if (mounted) {
        _showCustomNotification(
          'Erreur lors du chargement du rapport',
          Icons.error,
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add this simple form population method
  bool _hasPopulatedForm = false;

  void _populateFormFieldsSimple(TechnicalVisitReportViewModel viewModel) {
    final report = viewModel.currentReport;
    if (report == null || _hasPopulatedForm) {
      debugPrint('Cannot populate form: report is null or already populated');
      return;
    }

    debugPrint('=== POPULATING FORM FIELDS ===');
    debugPrint('Report ID: ${report.id}');
    debugPrint('Client: ${report.clientName}');
    debugPrint('Location: ${report.location}');
    debugPrint('Status: ${report.status}');

    // Set the flag first to prevent multiple populations
    _hasPopulatedForm = true;

    // Populate all form controllers
    _clientNameController.text = report.clientName;
    _locationController.text = report.location;
    _projectManagerController.text = report.projectManager;
    _accompanyingPersonController.text = report.accompanyingPerson;
    _projectContextController.text = report.projectContext;
    _conclusionController.text = report.conclusion;

    // Populate lists
    _technicians.clear();
    _technicians.addAll(report.technicians);
    _assumptions.clear();
    _assumptions.addAll(report.assumptions);
    _estimatedDays = report.estimatedDurationDays;

    debugPrint('Form controllers populated:');
    debugPrint('- Client: "${_clientNameController.text}"');
    debugPrint('- Location: "${_locationController.text}"');
    debugPrint('- Project Manager: "${_projectManagerController.text}"');
    debugPrint(
      '- Project Context length: ${_projectContextController.text.length}',
    );
    debugPrint('- Conclusion length: ${_conclusionController.text.length}');
    debugPrint('================================');

    // Force rebuild to show the populated data
    if (mounted) {
      setState(() {});
    }

    // Show success message for draft loading
    if (report.status == 'draft') {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showCustomNotification(
            'Brouillon chargé avec toutes vos données',
            Icons.check_circle,
            Colors.green,
          );
        }
      });
    }
  }

  // 2. Update _populateFormFields method - Remove setState wrapper
  void _populateFormFields(TechnicalVisitReportViewModel viewModel) {
    final report = viewModel.currentReport;
    if (report == null) {
      debugPrint('No report to populate from');
      return;
    }

    debugPrint('=== POPULATING FORM FIELDS ===');
    debugPrint('Report ID: ${report.id}');
    debugPrint('Status: ${report.status}');
    debugPrint('Client Name: "${report.clientName}"');
    debugPrint('Location: "${report.location}"');
    debugPrint('Project Manager: "${report.projectManager}"');
    debugPrint('Project Context: "${report.projectContext}"');
    debugPrint('Conclusion: "${report.conclusion}"');

    // Basic info - Direct assignment without setState
    _clientNameController.text = report.clientName;
    _locationController.text = report.location;
    _projectManagerController.text = report.projectManager;
    _accompanyingPersonController.text = report.accompanyingPerson;

    // Project context
    _projectContextController.text = report.projectContext;

    // Conclusion
    _conclusionController.text = report.conclusion;

    // Lists and values
    _technicians.clear();
    _technicians.addAll(report.technicians);

    _assumptions.clear();
    _assumptions.addAll(report.assumptions);

    _estimatedDays = report.estimatedDurationDays;

    // Debug form controllers after population
    debugPrint('=== FORM CONTROLLERS AFTER POPULATION ===');
    debugPrint('Client Controller: "${_clientNameController.text}"');
    debugPrint('Location Controller: "${_locationController.text}"');
    debugPrint(
      'Project Manager Controller: "${_projectManagerController.text}"',
    );
    debugPrint(
      'Project Context Controller: "${_projectContextController.text}"',
    );
    debugPrint('Conclusion Controller: "${_conclusionController.text}"');
    debugPrint('Technicians List: $_technicians');
    debugPrint('Assumptions List: $_assumptions');
    debugPrint('Estimated Days: $_estimatedDays');

    // Trigger a rebuild to show the populated data
    if (mounted) {
      setState(() {
        // Just trigger rebuild
      });
    }

    // Show success message for draft loading
    if (report.status == 'draft') {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showCustomNotification(
            'Brouillon chargé avec toutes vos données sauvegardées',
            Icons.check_circle,
            Colors.green,
          );
        }
      });
    }

    debugPrint('=== FORM POPULATION COMPLETED ===');
  }

  void _checkAndPopulateForm() {
    if (widget.reportId != null) {
      // Use addPostFrameCallback to ensure this runs after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewModel = Provider.of<TechnicalVisitReportViewModel>(
          context,
          listen: false,
        );

        if (viewModel.currentReport != null &&
            _clientNameController.text.isEmpty &&
            viewModel.currentReport!.clientName.isNotEmpty) {
          debugPrint('Detected unpopulated form, populating now...');
          _populateFormFields(viewModel);
        }
      });
    }
  }

  // 3. Add this method to force refresh form fields
  void _forceRefreshFormFields() {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    if (viewModel.currentReport != null) {
      setState(() {
        // This will trigger a rebuild and show the populated data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement du rapport...'),
            ],
          ),
        ),
      );
    }

    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(viewModel),
                    _buildProgressIndicator(),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentStep = index;
                              // Reset floating floor selector when leaving components step
                              if (index != 2) {
                                _showFloatingFloorSelector = false;
                              }
                            });
                            viewModel.navigateToStep(index);
                          },
                          children: [
                            _buildBasicInfoStep(viewModel),
                            _buildProjectContextStep(viewModel),
                            _buildComponentsStep(viewModel),
                            _buildConclusionStep(viewModel),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomNavigation(viewModel),
                  ],
                ),

                // Floating floor selector for components step
                if (_showFloatingFloorSelector && _currentStep == 2)
                  _buildFloatingFloorSelector(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingFloorSelector(TechnicalVisitReportViewModel viewModel) {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 18,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: viewModel.currentFloorIndex,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                      onChanged: (int? index) {
                        if (index != null) {
                          viewModel.setCurrentFloorIndex(index);
                        }
                      },
                      items:
                          viewModel.floors
                              .asMap()
                              .entries
                              .map<DropdownMenuItem<int>>((entry) {
                                return DropdownMenuItem<int>(
                                  value: entry.key,
                                  child: Text(entry.value.name),
                                );
                              })
                              .toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => viewModel.addFloor(),
                  tooltip: 'Ajouter un étage',
                  color: Colors.blue.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TechnicalVisitReportViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.close, size: 24),
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reportId != null
                      ? 'Modifier le rapport'
                      : 'Nouveau rapport',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Étape ${_currentStep + 1} sur $_totalSteps',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentStep + 1) / _totalSteps,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep(TechnicalVisitReportViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Informations générales',
            'Renseignez les détails de base de votre intervention',
            Icons.info_outline,
          ),

          const SizedBox(height: 24),

          FormTextField(
            label: 'Nom du client',
            controller: _clientNameController,
            required: true,
            hintText: 'Entrez le nom du client ou de l\'entreprise',
            onChanged: (value) => _updateBasicInfo(),
          ),

          FormTextField(
            label: 'Lieu d\'intervention',
            controller: _locationController,
            required: true,
            hintText: 'Adresse complète du site',
            onChanged: (value) => _updateBasicInfo(),
          ),

          Row(
            children: [
              Expanded(
                child: FormTextField(
                  label: 'Chef de projet',
                  controller: _projectManagerController,
                  required: true,
                  hintText: 'Nom du responsable',
                  onChanged: (value) => _updateBasicInfo(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildDateSelector(viewModel)),
            ],
          ),

          _buildTechniciansSection(),

          FormTextField(
            label: 'Personne accompagnatrice',
            controller: _accompanyingPersonController,
            hintText: 'Nom de la personne présente sur site (optionnel)',
            onChanged: (value) => _updateBasicInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectContextStep(TechnicalVisitReportViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Contexte du projet',
            'Décrivez le contexte et les objectifs de l\'intervention',
            Icons.description_outlined,
          ),

          const SizedBox(height: 24),

          FormTextField(
            label: 'Description du projet',
            controller: _projectContextController,
            required: true,
            multiline: true,
            maxLines: 8,
            hintText:
                'Décrivez en détail le contexte, les objectifs et les enjeux de ce projet...',
            onChanged: (value) => _updateProjectContext(),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Conseils de rédaction',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Précisez les besoins techniques identifiés\n'
                  '• Mentionnez les contraintes du site\n'
                  '• Indiquez les attentes du client\n'
                  '• Décrivez l\'environnement existant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsStep(TechnicalVisitReportViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _componentsScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Step header
                _buildStepHeader(
                  'Composants techniques',
                  'Documentez les équipements et installations',
                  Icons.category_outlined,
                ),

                const SizedBox(height: 24),

                // Floor selector (only visible when not floating)
                if (!_showFloatingFloorSelector)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: FloorSelector(),
                  ),

                if (viewModel.currentFloor != null)
                  _buildComponentsList(viewModel),

                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentsList(TechnicalVisitReportViewModel viewModel) {
    return const FloorComponentsForm();
  }

  Widget _buildConclusionStep(TechnicalVisitReportViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Conclusion et recommandations',
            'Synthétisez vos observations et recommandations',
            Icons.assignment_turned_in_outlined,
          ),

          const SizedBox(height: 24),

          FormTextField(
            label: 'Conclusion générale',
            controller: _conclusionController,
            required: true,
            multiline: true,
            maxLines: 6,
            hintText:
                'Résumez vos observations, recommandations et conclusions...',
            onChanged: (value) => _updateConclusion(),
          ),

          const SizedBox(height: 24),

          _buildAssumptionsSection(),

          const SizedBox(height: 24),

          FormNumberField(
            label: 'Durée estimée du projet (jours)',
            value: _estimatedDays,
            min: 1,
            max: 365,
            required: true,
            onChanged: (value) {
              setState(() => _estimatedDays = value?.toInt() ?? 1);
              _updateConclusion();
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Récapitulatif du rapport',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildReportSummary(viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(TechnicalVisitReportViewModel viewModel) {
    final report = viewModel.currentReport;
    final selectedDate = report?.date ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Date de visite',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, viewModel),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // In report_form_screen.dart, replace the _buildTechniciansSection() method:

  Widget _buildTechniciansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Technicien présent', // Changed from plural to singular
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Auto-populated current technician info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          FirebaseAuth.instance.currentUser?.email
                              ?.split('@')
                              .first ??
                          'Technicien',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (FirebaseAuth.instance.currentUser?.email != null)
                      Text(
                        FirebaseAuth.instance.currentUser!.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Automatique',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAssumptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hypothèses et prérequis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        if (_assumptions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(
              children:
                  _assumptions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.value)),
                          IconButton(
                            onPressed: () => _removeAssumption(entry.key),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                            color: Colors.red.shade400,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: _addAssumption,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter une hypothèse'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade700,
            side: BorderSide(color: Colors.orange.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSummary(TechnicalVisitReportViewModel viewModel) {
    final report = viewModel.currentReport;
    if (report == null) return const SizedBox.shrink();

    // Count components by type
    Map<String, int> componentCounts = {
      'Baies informatiques': 0,
      'Percements': 0,
      'Trappes d\'accès': 0,
      'Chemins de câbles': 0,
      'Goulottes': 0,
      'Conduits': 0,
      'Câblages cuivre': 0,
      'Câblages fibre optique': 0,
      'Composants personnalisés': 0,
    };

    int totalComponents = 0;
    for (final floor in report.floors) {
      componentCounts['Baies informatiques'] =
          componentCounts['Baies informatiques']! +
          floor.networkCabinets.length;
      componentCounts['Percements'] =
          componentCounts['Percements']! + floor.perforations.length;
      componentCounts['Trappes d\'accès'] =
          componentCounts['Trappes d\'accès']! + floor.accessTraps.length;
      componentCounts['Chemins de câbles'] =
          componentCounts['Chemins de câbles']! + floor.cablePaths.length;
      componentCounts['Goulottes'] =
          componentCounts['Goulottes']! + floor.cableTrunkings.length;
      componentCounts['Conduits'] =
          componentCounts['Conduits']! + floor.conduits.length;
      componentCounts['Câblages cuivre'] =
          componentCounts['Câblages cuivre']! + floor.copperCablings.length;
      componentCounts['Câblages fibre optique'] =
          componentCounts['Câblages fibre optique']! +
          floor.fiberOpticCablings.length;
      componentCounts['Composants personnalisés'] =
          componentCounts['Composants personnalisés']! +
          floor.customComponents.length;
      totalComponents += floor.totalComponentCount ?? 0;
    }

    // Filter out components with 0 count
    final nonEmptyComponents =
        componentCounts.entries.where((entry) => entry.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow('Client', report.clientName),
        _buildSummaryRow('Lieu', report.location),
        _buildSummaryRow('Étages', '${report.floors.length}'),
        _buildSummaryRow('Total composants', '$totalComponents'),

        if (nonEmptyComponents.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Détail des composants:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...nonEmptyComponents.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),
        _buildSummaryRow(
          'Durée estimée',
          '$_estimatedDays jour${_estimatedDays > 1 ? 's' : ''}',
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(TechnicalVisitReportViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Précédent'),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: 16),

            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _getNextButtonAction(viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(_getNextButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  VoidCallback? _getNextButtonAction(TechnicalVisitReportViewModel viewModel) {
    if (viewModel.isLoading) return null;

    return _currentStep < _totalSteps - 1
        ? _nextStep
        : () => _submitReport(viewModel);
  }

  String _getNextButtonText() {
    if (_currentStep < _totalSteps - 1) {
      return 'Suivant';
    }
    return 'Soumettre le rapport';
  }

  void _nextStep() {
    _hideKeyboard();

    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    _hideKeyboard();

    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic info step
        if (_clientNameController.text.trim().isEmpty) {
          _showValidationError('Veuillez renseigner le nom du client *');
          return false;
        }
        if (_locationController.text.trim().isEmpty) {
          _showValidationError('Veuillez renseigner le lieu d\'intervention *');
          return false;
        }
        if (_projectManagerController.text.trim().isEmpty) {
          _showValidationError('Veuillez renseigner le chef de projet *');
          return false;
        }
        if (_technicians.isEmpty) {
          _showValidationError('Veuillez ajouter au moins un technicien *');
          return false;
        }
        return true;
      case 1: // Project context step
        if (_projectContextController.text.trim().isEmpty) {
          _showValidationError('Veuillez décrire le contexte du projet *');
          return false;
        }
        return true;
      case 2: // Components step
        return true;
      case 3: // Conclusion step
        if (_conclusionController.text.trim().isEmpty) {
          _showValidationError('Veuillez rédiger une conclusion *');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TechnicalVisitReportViewModel viewModel,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.currentReport?.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateBasicInfo();
    }
  }

  void _addTechnician() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un technicien'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nom du technicien',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _technicians.add(controller.text.trim());
                  });
                  _updateBasicInfo();
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removeTechnician(int index) {
    setState(() {
      _technicians.removeAt(index);
    });
    _updateBasicInfo();
  }

  void _addAssumption() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter une hypothèse'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Hypothèse ou prérequis',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _assumptions.add(controller.text.trim());
                  });
                  _updateConclusion();
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removeAssumption(int index) {
    setState(() {
      _assumptions.removeAt(index);
    });
    _updateConclusion();
  }

  void _updateBasicInfo() {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    viewModel.updateBasicInfo(
      clientName: _clientNameController.text,
      location: _locationController.text,
      projectManager: _projectManagerController.text,
      technicians: List.from(_technicians),
      accompanyingPerson: _accompanyingPersonController.text,
    );
  }

  void _updateProjectContext() {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    viewModel.updateProjectContext(_projectContextController.text);
  }

  void _updateConclusion() {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    viewModel.updateConclusion(
      conclusion: _conclusionController.text,
      estimatedDurationDays: _estimatedDays,
      assumptions: List.from(_assumptions),
    );
  }

  Future<void> _saveDraft() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    try {
      final success = await viewModel.saveDraft();
      if (success) {
        debugPrint('Draft saved successfully');
      } else {
        throw Exception('Failed to save draft');
      }
    } catch (e) {
      debugPrint('Error saving draft: $e');
      rethrow;
    }
  }

  Future<void> _submitReport(TechnicalVisitReportViewModel viewModel) async {
    _hideKeyboard();

    if (!viewModel.validateAllSections()) {
      _showValidationError('Veuillez compléter toutes les sections requises');
      return;
    }

    final success = await viewModel.submitReport();

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted && viewModel.errorMessage != null) {
      _showValidationError(viewModel.errorMessage!);
    }
  }

  void _showExitDialog() {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    final bool isDraft = viewModel.currentReport?.status == 'draft';
    final bool hasChanges = viewModel.hasUnsavedChanges;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: null,
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade500,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.exit_to_app,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quitter le rapport',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDraft
                                    ? 'Sauvegarder le brouillon ?'
                                    : 'Que souhaitez-vous faire ?',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          hasChanges
                              ? 'Vous avez des modifications non sauvegardées. Voulez-vous les sauvegarder en tant que brouillon ?'
                              : 'Voulez-vous sauvegarder vos modifications avant de quitter ?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isDraft
                                      ? 'Le brouillon sera sauvegardé et vous pourrez le reprendre plus tard'
                                      : 'Vos modifications seront sauvegardées en tant que brouillon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        // Save and exit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Close the dialog first
                              Navigator.of(dialogContext).pop();

                              // Show loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (loadingContext) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              try {
                                // Save draft
                                await _saveDraft();

                                // Close loading dialog and form
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  Navigator.of(context).pop(); // Close form
                                }
                              } catch (e) {
                                // Close loading dialog and show error
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  _showCustomNotification(
                                    'Erreur lors de la sauvegarde',
                                    Icons.error,
                                    Colors.red,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: Text(
                              isDraft
                                  ? 'Sauvegarder et quitter'
                                  : 'Sauvegarder comme brouillon',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Exit without saving button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(); // Close dialog
                              Navigator.of(context).pop(); // Close form
                            },
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            label: Text(
                              'Quitter sans sauvegarder',
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continuer l\'édition',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
