// lib/views/screens/report_form/report_form_screen.dart
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

  // Add overlay entry for custom notification
  OverlayEntry? _notificationOverlay;

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
    _pageController = PageController();
    _componentsScrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeReport();
    _animationController.forward();
  }

  @override
  void dispose() {
    _notificationOverlay?.remove(); // Clean up overlay
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
      if (widget.reportId != null) {
        await viewModel.loadReport(widget.reportId!);
        _populateFormFields(viewModel);
      } else {
        await viewModel.initNewReport();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFormFields(TechnicalVisitReportViewModel viewModel) {
    final report = viewModel.currentReport;
    if (report != null) {
      _clientNameController.text = report.clientName;
      _locationController.text = report.location;
      _projectManagerController.text = report.projectManager;
      _accompanyingPersonController.text = report.accompanyingPerson;
      _projectContextController.text = report.projectContext;
      _conclusionController.text = report.conclusion;
      _technicians.clear();
      _technicians.addAll(report.technicians);
      _assumptions.clear();
      _assumptions.addAll(report.assumptions);
      _estimatedDays = report.estimatedDurationDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(viewModel),
                _buildProgressIndicator(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
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
          ),
        );
      },
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
          // Removed the save button as requested
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
        // Fixed header that stays visible
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Floor selector - always visible
              Container(
                padding: const EdgeInsets.all(16),
                child: const FloorSelector(),
              ),
            ],
          ),
        ),

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

                _buildSimpleComponentSelector(viewModel),

                const SizedBox(height: 24),

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
    // Import the existing FloorComponentsForm and use its _buildComponentSections method
    // or simply return the form content directly
    return const FloorComponentsForm(); // You'll need to import this
  }

  Widget _buildSimpleComponentSelector(
    TechnicalVisitReportViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajouter un composant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choisissez le type de composant à documenter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _hideKeyboard();
                _showComponentTypeDialog(viewModel);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Sélectionner un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildTechniciansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Techniciens présents',
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

        // List of technicians
        if (_technicians.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children:
                  _technicians.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.blue.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.value)),
                          IconButton(
                            onPressed: () => _removeTechnician(entry.key),
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
          onPressed: _addTechnician,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter un technicien'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            side: BorderSide(color: Colors.blue.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
    // Hide keyboard when moving to next step
    _hideKeyboard();

    if (_currentStep < _totalSteps - 1) {
      // Validate current step before proceeding - ENHANCED VALIDATION
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

  void _scrollToBottom() {
    if (_componentsScrollController.hasClients) {
      _componentsScrollController.animateTo(
        _componentsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
        // Allow to proceed but encourage adding components
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

  void _showComponentTypeDialog(TechnicalVisitReportViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir un composant',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sélectionnez le type de composant à ajouter',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),

                // Component options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Highlighted: Custom component first
                        _buildComponentOption(
                          'Composant personnalisé',
                          'Créer un composant sur mesure selon vos besoins',
                          Icons.add_box,
                          Colors.pink,
                          true,
                          () => _addComponent(
                            viewModel,
                            'Composant personnalisé',
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'COMPOSANTS STANDARD',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Standard components
                        ...viewModel.componentTypes
                            .where((type) => type != 'Composant personnalisé')
                            .map(
                              (type) => _buildComponentOption(
                                type,
                                _getComponentDescription(type),
                                _getComponentIcon(type),
                                _getComponentColor(type),
                                false,
                                () => _addComponent(viewModel, type),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildComponentOption(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isHighlighted,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isHighlighted ? color.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isHighlighted
                        ? color.withOpacity(0.3)
                        : Colors.grey.shade200,
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isHighlighted ? color : Colors.black87,
                              ),
                            ),
                          ),
                          if (isHighlighted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'RECOMMANDÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addComponent(TechnicalVisitReportViewModel viewModel, String type) {
    Navigator.pop(context);
    _hideKeyboard();

    viewModel.addComponentByType(type);

    // Scroll to bottom after adding component
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToBottom();
    });
  }

  // Helper methods for component descriptions, icons, and colors
  String _getComponentDescription(String type) {
    switch (type) {
      case 'Baie Informatique':
        return 'Armoire contenant les équipements réseau';
      case 'Percement':
        return 'Passage pour câbles dans murs ou planchers';
      case 'Trappe d\'accès':
        return 'Ouverture pour accéder aux zones techniques';
      case 'Chemin de câbles':
        return 'Support pour acheminer les câbles';
      case 'Goulotte':
        return 'Canal pour protéger et dissimuler les câbles';
      case 'Conduit':
        return 'Tube pour protéger les câbles';
      case 'Câblage cuivre':
        return 'Câbles réseau en cuivre (Cat5e, Cat6, etc.)';
      case 'Câblage fibre optique':
        return 'Câbles à fibre optique haute performance';
      case 'Composant personnalisé':
        return 'Créer un composant sur mesure selon vos besoins';
      default:
        return 'Sélectionnez un type de composant';
    }
  }

  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'Baie Informatique':
        return Icons.dns_outlined;
      case 'Percement':
        return Icons.architecture;
      case 'Trappe d\'accès':
        return Icons.door_sliding_outlined;
      case 'Chemin de câbles':
        return Icons.linear_scale;
      case 'Goulotte':
        return Icons.power_input;
      case 'Conduit':
        return Icons.rotate_90_degrees_ccw;
      case 'Câblage cuivre':
        return Icons.cable;
      case 'Câblage fibre optique':
        return Icons.fiber_manual_record;
      case 'Composant personnalisé':
        return Icons.add_box;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getComponentColor(String type) {
    switch (type) {
      case 'Baie Informatique':
        return Colors.blue;
      case 'Percement':
        return Colors.orange;
      case 'Trappe d\'accès':
        return Colors.purple;
      case 'Chemin de câbles':
        return Colors.green;
      case 'Goulotte':
        return Colors.teal;
      case 'Conduit':
        return Colors.indigo;
      case 'Câblage cuivre':
        return Colors.amber;
      case 'Câblage fibre optique':
        return Colors.red;
      case 'Composant personnalisé':
        return Colors.pink;
      default:
        return Colors.grey;
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
      await viewModel.saveDraft();
      // Removed the success notification since it happens in background now
    } catch (e) {
      // Silently handle errors since this runs in background
      debugPrint('Error saving draft: $e');
    }
  }

  Future<void> _submitReport(TechnicalVisitReportViewModel viewModel) async {
    // HIDE KEYBOARD WHEN SUBMITTING REPORT
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quitter le rapport',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Que souhaitez-vous faire ?',
                                style: TextStyle(
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
                          'Voulez-vous sauvegarder vos modifications avant de quitter ?',
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
                                  'Vos modifications seront sauvegardées en tant que brouillon',
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
                              Navigator.pop(
                                context,
                              ); // Close exit confirmation dialog

                              // OPTIONAL: Show loading indicator briefly
                              final BuildContext loadingContext = context;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              // Trigger save draft in background
                              _saveDraft(); // This already runs without await and saves silently

                              // Pop loading dialog after saving starts
                              if (Navigator.canPop(loadingContext)) {
                                Navigator.pop(loadingContext);
                              }

                              // Go back to ReportList
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Sauvegarder et quitter'),
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
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(
                                context,
                              ); // Exit form without saving
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
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
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
