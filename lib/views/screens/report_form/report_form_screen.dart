// lib/views/screens/report_form/report_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../../utils/notification_utils.dart';
import '../../widgets/report_form/form_text_field.dart';
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
          if (viewModel.currentReport?.status == 'draft')
            TextButton.icon(
              onPressed: viewModel.isLoading ? null : _saveDraft,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Sauvegarder'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                backgroundColor: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                'Composants techniques',
                'Documentez les équipements et installations',
                Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              const FloorSelector(),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: _componentsScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ComponentTypeSelector(
                  componentTypes: viewModel.componentTypes,
                  selectedType: viewModel.selectedComponentType,
                  onTypeSelected: (type) {
                    _hideKeyboard();
                    viewModel.setSelectedComponentType(type);
                    if (type != null) {
                      viewModel.addComponentByType(type);
                      viewModel.setSelectedComponentType(null);
                      // Scroll to bottom after adding component
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _scrollToBottom();
                      });
                    }
                  },
                ),

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
    final floor = viewModel.currentFloor!;

    return Column(
      children: [
        // Network Cabinets
        if (floor.networkCabinets.isNotEmpty)
          _buildNetworkCabinetsSection(viewModel, floor.networkCabinets),

        // Perforations
        if (floor.perforations.isNotEmpty)
          _buildPerforationsSection(viewModel, floor.perforations),

        // Access Traps
        if (floor.accessTraps.isNotEmpty)
          _buildAccessTrapsSection(viewModel, floor.accessTraps),

        // Cable Paths
        if (floor.cablePaths.isNotEmpty)
          _buildCablePathsSection(viewModel, floor.cablePaths),

        // Cable Trunkings
        if (floor.cableTrunkings.isNotEmpty)
          _buildCableTrunkingsSection(viewModel, floor.cableTrunkings),

        // Conduits
        if (floor.conduits.isNotEmpty)
          _buildConduitsSection(viewModel, floor.conduits),

        // Copper Cablings
        if (floor.copperCablings.isNotEmpty)
          _buildCopperCablingsSection(viewModel, floor.copperCablings),

        // Fiber Optic Cablings
        if (floor.fiberOpticCablings.isNotEmpty)
          _buildFiberOpticCablingsSection(viewModel, floor.fiberOpticCablings),

        // Custom Components
        if (floor.customComponents.isNotEmpty)
          _buildCustomComponentsSection(viewModel, floor.customComponents),
      ],
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
                child:
                    viewModel.isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(_getNextButtonText()),
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
      // Validate current step before proceeding
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
          _showValidationError('Veuillez renseigner le nom du client');
          return false;
        }
        if (_locationController.text.trim().isEmpty) {
          _showValidationError('Veuillez renseigner le lieu d\'intervention');
          return false;
        }
        if (_projectManagerController.text.trim().isEmpty) {
          _showValidationError('Veuillez renseigner le chef de projet');
          return false;
        }
        if (_technicians.isEmpty) {
          _showValidationError('Veuillez ajouter au moins un technicien');
          return false;
        }
        return true;
      case 1: // Project context step
        if (_projectContextController.text.trim().isEmpty) {
          _showValidationError('Veuillez décrire le contexte du projet');
          return false;
        }
        return true;
      case 2: // Components step
        // Allow to proceed but encourage adding components
        return true;
      case 3: // Conclusion step
        if (_conclusionController.text.trim().isEmpty) {
          _showValidationError('Veuillez rédiger une conclusion');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    NotificationUtils.showError(context, message);
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

    final success = await viewModel.saveDraft();

    if (success && mounted) {
      NotificationUtils.showSuccess(context, 'Brouillon sauvegardé');
    } else if (mounted && viewModel.errorMessage != null) {
      NotificationUtils.showError(context, viewModel.errorMessage!);
    }
  }

  Future<void> _submitReport(TechnicalVisitReportViewModel viewModel) async {
    if (!viewModel.validateAllSections()) {
      NotificationUtils.showError(
        context,
        'Veuillez compléter toutes les sections requises',
      );
      return;
    }

    final success = await viewModel.submitReport();

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted && viewModel.errorMessage != null) {
      NotificationUtils.showError(context, viewModel.errorMessage!);
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quitter le rapport ?'),
            content: const Text(
              'Vos modifications seront automatiquement sauvegardées comme brouillon.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuer l\'édition'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Auto-save as draft before leaving
                  await _saveDraft();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Sauvegarder et quitter'),
              ),
            ],
          ),
    );
  }

  // Component sections builders
  Widget _buildNetworkCabinetsSection(
    TechnicalVisitReportViewModel viewModel,
    List<NetworkCabinet> cabinets,
  ) {
    return DynamicListSection<NetworkCabinet>(
      title: 'Baies Informatiques',
      subtitle: 'Armoires contenant les équipements réseau',
      icon: Icons.dns_outlined,
      items: cabinets,
      componentType: 'Baie Informatique',
      itemBuilder:
          (cabinet, index) =>
              _buildNetworkCabinetForm(viewModel, cabinet, index),
      onAddItem: () {
        _hideKeyboard();
        viewModel.addNetworkCabinet();
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      },
      onRemoveItem: (index) => viewModel.removeNetworkCabinet(index),
      onAddOtherComponentType: () {
        _hideKeyboard();
        viewModel.setSelectedComponentType(null);
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      },
    );
  }

  Widget _buildNetworkCabinetForm(
    TechnicalVisitReportViewModel viewModel,
    NetworkCabinet cabinet,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Nom de la baie',
                initialValue: cabinet.name,
                onChanged:
                    (value) => _updateNetworkCabinet(
                      viewModel,
                      index,
                      cabinet.copyWith(name: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: cabinet.location,
                onChanged:
                    (value) => _updateNetworkCabinet(
                      viewModel,
                      index,
                      cabinet.copyWith(location: value),
                    ),
              ),
            ),
          ],
        ),

        FormDropdown<String>(
          label: 'État de la baie',
          value: cabinet.cabinetState,
          items:
              ['Neuve', 'Bonne', 'Correcte', 'À remplacer']
                  .map(
                    (state) =>
                        DropdownMenuItem(value: state, child: Text(state)),
                  )
                  .toList(),
          onChanged:
              (value) => _updateNetworkCabinet(
                viewModel,
                index,
                cabinet.copyWith(cabinetState: value ?? ''),
              ),
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Unités rack totales',
                value: cabinet.totalRackUnits,
                min: 1,
                max: 100,
                onChanged:
                    (value) => _updateNetworkCabinet(
                      viewModel,
                      index,
                      cabinet.copyWith(totalRackUnits: value?.toInt() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Unités disponibles',
                value: cabinet.availableRackUnits,
                min: 0,
                max: 100,
                onChanged:
                    (value) => _updateNetworkCabinet(
                      viewModel,
                      index,
                      cabinet.copyWith(availableRackUnits: value?.toInt() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormNumberField(
          label: 'Prises disponibles',
          value: cabinet.availableOutlets,
          min: 0,
          max: 50,
          onChanged:
              (value) => _updateNetworkCabinet(
                viewModel,
                index,
                cabinet.copyWith(availableOutlets: value?.toInt() ?? 0),
              ),
        ),

        FormTextField(
          label: 'Notes',
          initialValue: cabinet.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateNetworkCabinet(
                viewModel,
                index,
                cabinet.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateNetworkCabinet(
    TechnicalVisitReportViewModel viewModel,
    int index,
    NetworkCabinet cabinet,
  ) {
    viewModel.updateNetworkCabinet(index, cabinet);
  }

  Widget _buildPerforationsSection(
    TechnicalVisitReportViewModel viewModel,
    List<Perforation> perforations,
  ) {
    return DynamicListSection<Perforation>(
      title: 'Percements',
      subtitle: 'Passages pour câbles dans murs ou planchers',
      icon: Icons.architecture,
      items: perforations,
      componentType: 'Percement',
      itemBuilder:
          (perforation, index) =>
              _buildPerforationForm(viewModel, perforation, index),
      onAddItem: () => viewModel.addPerforation(),
      onRemoveItem: (index) => viewModel.removePerforation(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildPerforationForm(
    TechnicalVisitReportViewModel viewModel,
    Perforation perforation,
    int index,
  ) {
    return Column(
      children: [
        FormTextField(
          label: 'Emplacement',
          initialValue: perforation.location,
          onChanged:
              (value) => _updatePerforation(
                viewModel,
                index,
                perforation.copyWith(location: value),
              ),
        ),

        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Type de mur/plancher',
                initialValue: perforation.wallType,
                onChanged:
                    (value) => _updatePerforation(
                      viewModel,
                      index,
                      perforation.copyWith(wallType: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Épaisseur (cm)',
                value: perforation.wallDepth,
                min: 1,
                max: 200,
                decimal: true,
                onChanged:
                    (value) => _updatePerforation(
                      viewModel,
                      index,
                      perforation.copyWith(wallDepth: value?.toDouble() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Notes',
          initialValue: perforation.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updatePerforation(
                viewModel,
                index,
                perforation.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updatePerforation(
    TechnicalVisitReportViewModel viewModel,
    int index,
    Perforation perforation,
  ) {
    viewModel.updatePerforation(index, perforation);
  }

  Widget _buildAccessTrapsSection(
    TechnicalVisitReportViewModel viewModel,
    List<AccessTrap> traps,
  ) {
    return DynamicListSection<AccessTrap>(
      title: 'Trappes d\'accès',
      subtitle: 'Ouvertures pour accéder aux zones techniques',
      icon: Icons.door_sliding_outlined,
      items: traps,
      componentType: 'Trappe d\'accès',
      itemBuilder:
          (trap, index) => _buildAccessTrapForm(viewModel, trap, index),
      onAddItem: () => viewModel.addAccessTrap(),
      onRemoveItem: (index) => viewModel.removeAccessTrap(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildAccessTrapForm(
    TechnicalVisitReportViewModel viewModel,
    AccessTrap trap,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: trap.location,
                onChanged:
                    (value) => _updateAccessTrap(
                      viewModel,
                      index,
                      trap.copyWith(location: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Dimensions',
                initialValue: trap.trapSize,
                onChanged:
                    (value) => _updateAccessTrap(
                      viewModel,
                      index,
                      trap.copyWith(trapSize: value),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Notes',
          initialValue: trap.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateAccessTrap(
                viewModel,
                index,
                trap.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateAccessTrap(
    TechnicalVisitReportViewModel viewModel,
    int index,
    AccessTrap trap,
  ) {
    viewModel.updateAccessTrap(index, trap);
  }

  Widget _buildCablePathsSection(
    TechnicalVisitReportViewModel viewModel,
    List<CablePath> paths,
  ) {
    return DynamicListSection<CablePath>(
      title: 'Chemins de câbles',
      subtitle: 'Supports pour acheminer les câbles',
      icon: Icons.linear_scale,
      items: paths,
      componentType: 'Chemin de câbles',
      itemBuilder: (path, index) => _buildCablePathForm(viewModel, path, index),
      onAddItem: () => viewModel.addCablePath(),
      onRemoveItem: (index) => viewModel.removeCablePath(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildCablePathForm(
    TechnicalVisitReportViewModel viewModel,
    CablePath path,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: path.location,
                onChanged:
                    (value) => _updateCablePath(
                      viewModel,
                      index,
                      path.copyWith(location: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Dimensions',
                initialValue: path.size,
                onChanged:
                    (value) => _updateCablePath(
                      viewModel,
                      index,
                      path.copyWith(size: value),
                    ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: path.lengthInMeters,
                min: 0,
                max: 1000,
                decimal: true,
                onChanged:
                    (value) => _updateCablePath(
                      viewModel,
                      index,
                      path.copyWith(lengthInMeters: value?.toDouble() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Hauteur (m)',
                value: path.heightInMeters,
                min: 0,
                max: 50,
                decimal: true,
                onChanged:
                    (value) => _updateCablePath(
                      viewModel,
                      index,
                      path.copyWith(heightInMeters: value?.toDouble() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Type de fixation',
          initialValue: path.fixationType,
          onChanged:
              (value) => _updateCablePath(
                viewModel,
                index,
                path.copyWith(fixationType: value),
              ),
        ),

        FormTextField(
          label: 'Notes',
          initialValue: path.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateCablePath(
                viewModel,
                index,
                path.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateCablePath(
    TechnicalVisitReportViewModel viewModel,
    int index,
    CablePath path,
  ) {
    viewModel.updateCablePath(index, path);
  }

  Widget _buildCableTrunkingsSection(
    TechnicalVisitReportViewModel viewModel,
    List<CableTrunking> trunkings,
  ) {
    return DynamicListSection<CableTrunking>(
      title: 'Goulottes',
      subtitle: 'Canaux pour protéger et dissimuler les câbles',
      icon: Icons.power_input,
      items: trunkings,
      componentType: 'Goulotte',
      itemBuilder:
          (trunking, index) =>
              _buildCableTrunkingForm(viewModel, trunking, index),
      onAddItem: () => viewModel.addCableTrunking(),
      onRemoveItem: (index) => viewModel.removeCableTrunking(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildCableTrunkingForm(
    TechnicalVisitReportViewModel viewModel,
    CableTrunking trunking,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: trunking.location,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(location: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Dimensions',
                initialValue: trunking.size,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(size: value),
                    ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: trunking.lengthInMeters,
                min: 0,
                max: 1000,
                decimal: true,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(lengthInMeters: value?.toDouble() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Hauteur (m)',
                value: trunking.workHeight,
                min: 0,
                max: 50,
                decimal: true,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(workHeight: value?.toDouble() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Angles intérieurs',
                value: trunking.innerAngles,
                min: 0,
                max: 100,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(innerAngles: value?.toInt() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FormNumberField(
                label: 'Angles extérieurs',
                value: trunking.outerAngles,
                min: 0,
                max: 100,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(outerAngles: value?.toInt() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FormNumberField(
                label: 'Angles plats',
                value: trunking.flatAngles,
                min: 0,
                max: 100,
                onChanged:
                    (value) => _updateCableTrunking(
                      viewModel,
                      index,
                      trunking.copyWith(flatAngles: value?.toInt() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Notes',
          initialValue: trunking.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateCableTrunking(
                viewModel,
                index,
                trunking.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateCableTrunking(
    TechnicalVisitReportViewModel viewModel,
    int index,
    CableTrunking trunking,
  ) {
    viewModel.updateCableTrunking(index, trunking);
  }

  Widget _buildConduitsSection(
    TechnicalVisitReportViewModel viewModel,
    List<Conduit> conduits,
  ) {
    return DynamicListSection<Conduit>(
      title: 'Conduits',
      subtitle: 'Tubes pour protéger les câbles',
      icon: Icons.rotate_90_degrees_ccw,
      items: conduits,
      componentType: 'Conduit',
      itemBuilder:
          (conduit, index) => _buildConduitForm(viewModel, conduit, index),
      onAddItem: () => viewModel.addConduit(),
      onRemoveItem: (index) => viewModel.removeConduit(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildConduitForm(
    TechnicalVisitReportViewModel viewModel,
    Conduit conduit,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: conduit.location,
                onChanged:
                    (value) => _updateConduit(
                      viewModel,
                      index,
                      conduit.copyWith(location: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Diamètre',
                initialValue: conduit.size,
                onChanged:
                    (value) => _updateConduit(
                      viewModel,
                      index,
                      conduit.copyWith(size: value),
                    ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: conduit.lengthInMeters,
                min: 0,
                max: 1000,
                decimal: true,
                onChanged:
                    (value) => _updateConduit(
                      viewModel,
                      index,
                      conduit.copyWith(lengthInMeters: value?.toDouble() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Hauteur (m)',
                value: conduit.workHeight,
                min: 0,
                max: 50,
                decimal: true,
                onChanged:
                    (value) => _updateConduit(
                      viewModel,
                      index,
                      conduit.copyWith(workHeight: value?.toDouble() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Notes',
          initialValue: conduit.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateConduit(
                viewModel,
                index,
                conduit.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateConduit(
    TechnicalVisitReportViewModel viewModel,
    int index,
    Conduit conduit,
  ) {
    viewModel.updateConduit(index, conduit);
  }

  Widget _buildCopperCablingsSection(
    TechnicalVisitReportViewModel viewModel,
    List<CopperCabling> cablings,
  ) {
    return DynamicListSection<CopperCabling>(
      title: 'Câblages cuivre',
      subtitle: 'Câbles réseau en cuivre (Cat5e, Cat6, etc.)',
      icon: Icons.cable,
      items: cablings,
      componentType: 'Câblage cuivre',
      itemBuilder:
          (cabling, index) =>
              _buildCopperCablingForm(viewModel, cabling, index),
      onAddItem: () => viewModel.addCopperCabling(),
      onRemoveItem: (index) => viewModel.removeCopperCabling(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildCopperCablingForm(
    TechnicalVisitReportViewModel viewModel,
    CopperCabling cabling,
    int index,
  ) {
    return Column(
      children: [
        FormTextField(
          label: 'Emplacement',
          initialValue: cabling.location,
          onChanged:
              (value) => _updateCopperCabling(
                viewModel,
                index,
                cabling.copyWith(location: value),
              ),
        ),

        FormTextField(
          label: 'Description du trajet',
          initialValue: cabling.pathDescription,
          multiline: true,
          maxLines: 2,
          onChanged:
              (value) => _updateCopperCabling(
                viewModel,
                index,
                cabling.copyWith(pathDescription: value),
              ),
        ),

        Row(
          children: [
            Expanded(
              child: FormDropdown<String>(
                label: 'Catégorie',
                value: cabling.category,
                items:
                    ['Cat5e', 'Cat6', 'Cat6A', 'Cat7']
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged:
                    (value) => _updateCopperCabling(
                      viewModel,
                      index,
                      cabling.copyWith(category: value ?? ''),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: cabling.lengthInMeters,
                min: 0,
                max: 1000,
                decimal: true,
                onChanged:
                    (value) => _updateCopperCabling(
                      viewModel,
                      index,
                      cabling.copyWith(lengthInMeters: value?.toDouble() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormNumberField(
          label: 'Hauteur de travail (m)',
          value: cabling.workHeight,
          min: 0,
          max: 50,
          decimal: true,
          onChanged:
              (value) => _updateCopperCabling(
                viewModel,
                index,
                cabling.copyWith(workHeight: value?.toDouble() ?? 0),
              ),
        ),

        FormTextField(
          label: 'Notes',
          initialValue: cabling.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateCopperCabling(
                viewModel,
                index,
                cabling.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateCopperCabling(
    TechnicalVisitReportViewModel viewModel,
    int index,
    CopperCabling cabling,
  ) {
    viewModel.updateCopperCabling(index, cabling);
  }

  Widget _buildFiberOpticCablingsSection(
    TechnicalVisitReportViewModel viewModel,
    List<FiberOpticCabling> cablings,
  ) {
    return DynamicListSection<FiberOpticCabling>(
      title: 'Câblages fibre optique',
      subtitle: 'Câbles à fibre optique haute performance',
      icon: Icons.fiber_manual_record,
      items: cablings,
      componentType: 'Câblage fibre optique',
      itemBuilder:
          (cabling, index) =>
              _buildFiberOpticCablingForm(viewModel, cabling, index),
      onAddItem: () => viewModel.addFiberOpticCabling(),
      onRemoveItem: (index) => viewModel.removeFiberOpticCabling(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildFiberOpticCablingForm(
    TechnicalVisitReportViewModel viewModel,
    FiberOpticCabling cabling,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: cabling.location,
                onChanged:
                    (value) => _updateFiberOpticCabling(
                      viewModel,
                      index,
                      cabling.copyWith(location: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormDropdown<String>(
                label: 'Type de fibre',
                value: cabling.fiberType,
                items:
                    [
                          'Monomode',
                          'Multimode OM3',
                          'Multimode OM4',
                          'Multimode OM5',
                        ]
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged:
                    (value) => _updateFiberOpticCabling(
                      viewModel,
                      index,
                      cabling.copyWith(fiberType: value ?? ''),
                    ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Nombre de tiroirs',
                min: 1,
                max: 50,
                onChanged:
                    (value) => _updateFiberOpticCabling(
                      viewModel,
                      index,
                      cabling.copyWith(drawerCount: value?.toInt() ?? 1),
                    ),
                value: null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Nombre de conduits',
                value: cabling.conduitCount,
                min: 1,
                max: 100,
                onChanged:
                    (value) => _updateFiberOpticCabling(
                      viewModel,
                      index,
                      cabling.copyWith(conduitCount: value?.toInt() ?? 1),
                    ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: cabling.lengthInMeters,
                min: 0,
                max: 10000,
                decimal: true,
                onChanged:
                    (value) => _updateFiberOpticCabling(
                      viewModel,
                      index,
                      cabling.copyWith(lengthInMeters: value?.toDouble() ?? 0),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Hauteur (m)',
                value: cabling.workHeight,
                min: 0,
                max: 50,
                decimal: true,
                onChanged:
                    (value) => _updateFiberOpticCabling(
                      viewModel,
                      index,
                      cabling.copyWith(workHeight: value?.toDouble() ?? 0),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Notes',
          initialValue: cabling.notes,
          multiline: true,
          maxLines: 3,
          onChanged:
              (value) => _updateFiberOpticCabling(
                viewModel,
                index,
                cabling.copyWith(notes: value),
              ),
        ),
      ],
    );
  }

  void _updateFiberOpticCabling(
    TechnicalVisitReportViewModel viewModel,
    int index,
    FiberOpticCabling cabling,
  ) {
    viewModel.updateFiberOpticCabling(index, cabling);
  }

  Widget _buildCustomComponentsSection(
    TechnicalVisitReportViewModel viewModel,
    List<CustomComponent> components,
  ) {
    return DynamicListSection<CustomComponent>(
      title: 'Composants personnalisés',
      subtitle: 'Éléments sur mesure selon vos besoins',
      icon: Icons.add_box,
      items: components,
      componentType: 'Composant personnalisé',
      itemBuilder:
          (component, index) =>
              _buildCustomComponentForm(viewModel, component, index),
      onAddItem: () => viewModel.addCustomComponent(),
      onRemoveItem: (index) => viewModel.removeCustomComponent(index),
      onAddOtherComponentType: () => viewModel.setSelectedComponentType(null),
    );
  }

  Widget _buildCustomComponentForm(
    TechnicalVisitReportViewModel viewModel,
    CustomComponent component,
    int index,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FormTextField(
                label: 'Nom du composant',
                initialValue: component.name,
                required: true,
                onChanged:
                    (value) => _updateCustomComponent(
                      viewModel,
                      index,
                      component.copyWith(name: value),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Emplacement',
                initialValue: component.location,
                onChanged:
                    (value) => _updateCustomComponent(
                      viewModel,
                      index,
                      component.copyWith(location: value),
                    ),
              ),
            ),
          ],
        ),

        FormTextField(
          label: 'Description',
          initialValue: component.description,
          multiline: true,
          maxLines: 3,
          hintText: 'Décrivez ce composant et ses caractéristiques...',
          onChanged:
              (value) => _updateCustomComponent(
                viewModel,
                index,
                component.copyWith(description: value),
              ),
        ),

        FormTextField(
          label: 'Notes techniques',
          initialValue: component.notes,
          multiline: true,
          maxLines: 3,
          hintText: 'Observations, recommandations ou remarques spécifiques...',
          onChanged:
              (value) => _updateCustomComponent(
                viewModel,
                index,
                component.copyWith(notes: value),
              ),
        ),

        const SizedBox(height: 16),

        // Photo section
        ComponentPhotoSection(
          componentIndex: index,
          photos: component.photos,
          componentType: 'Composant personnalisé',
        ),
      ],
    );
  }

  void _updateCustomComponent(
    TechnicalVisitReportViewModel viewModel,
    int index,
    CustomComponent component,
  ) {
    viewModel.updateCustomComponent(index, component);
  }
}
