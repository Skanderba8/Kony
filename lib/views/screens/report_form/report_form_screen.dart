// lib/views/screens/report_form/report_form_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../widgets/report_form/form_step_indicator.dart';
import '../../widgets/report_form/floor_selector.dart';
import '../../../utils/notification_utils.dart';

// Import form steps
import 'basic_info_form.dart';
import 'project_context_form.dart';
import 'floor_components_form.dart';
import 'conclusion_form.dart';

/// Main screen to manage the multi-step technical visit report form.
/// Now integrates the floor-based component organization.
class ReportFormScreen extends StatefulWidget {
  final String? reportId;

  const ReportFormScreen({super.key, this.reportId});

  @override
  _ReportFormScreenState createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  bool _isInitialized = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReport();
      // Setup auto-save every 30 seconds
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _autoSave();
      });
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Auto-save the report without UI feedback
  Future<void> _autoSave() async {
    if (_isInitialized && !_isLoading && !_isSaving) {
      final viewModel = Provider.of<TechnicalVisitReportViewModel>(
        context,
        listen: false,
      );

      if (viewModel.currentReport != null) {
        await viewModel.saveDraft();
        debugPrint('Auto-saved report at ${DateTime.now()}');
      }
    }
  }

  /// Initialize the report, either by loading an existing one or creating a new draft
  Future<void> _initializeReport() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    try {
      if (widget.reportId != null) {
        // Load existing report
        await viewModel.loadReport(widget.reportId!);
      } else {
        // Create new report
        await viewModel.initNewReport();
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      NotificationUtils.showError(
        context,
        'Erreur lors de l\'initialisation du rapport: $e',
      );
    }
  }

  /// Set loading state for UI feedback
  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  /// Handle step navigation
  void _navigateToStep(int step) {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );
    viewModel.navigateToStep(step);

    // Scroll to top when changing steps
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Move to the next step
  Future<void> _nextStep() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    // Always save before proceeding
    await viewModel.saveDraft();

    if (viewModel.nextStep()) {
      // Scroll to top when changing steps
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Also update the _previousStep method to save before navigating
  void _previousStep() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    // Save current state before going back
    await viewModel.saveDraft();

    if (viewModel.previousStep()) {
      // Scroll to top when changing steps
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Display confirmation dialog before submitting the report
  Future<void> _confirmSubmitReport() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    if (!viewModel.canSubmit) {
      NotificationUtils.showWarning(
        context,
        'Veuillez compléter toutes les sections requises avant de soumettre le rapport.',
      );
      return;
    }

    final bool confirmed =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Soumettre le rapport ?'),
                content: const Text(
                  'Une fois soumis, le rapport sera transmis pour examen et ne pourra plus être modifié. '
                  'Êtes-vous sûr de vouloir soumettre ce rapport ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Soumettre'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      _submitReport();
    }
  }

  /// Submit the report
  Future<void> _submitReport() async {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    try {
      _setLoading(true);

      // First validate all required fields are completed
      if (!viewModel.validateAllSections()) {
        NotificationUtils.showWarning(
          context,
          'Veuillez compléter toutes les sections requises avant de soumettre le rapport.',
        );
        _setLoading(false);
        return;
      }

      // Save any pending changes first
      await viewModel.saveDraft();

      // Submit the report - this will generate the PDF internally
      final success = await viewModel.submitReport();

      if (success && mounted) {
        NotificationUtils.showSuccess(
          context,
          'Rapport soumis avec succès ! Le PDF a été généré.',
        );

        // Navigate back to the list screen after successful submission
        Navigator.of(context).pop(true);
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          'Une erreur est survenue lors de la soumission du rapport: ${viewModel.errorMessage ?? "Erreur inconnue"}',
        );
      }
    } catch (e, stackTrace) {
      // Enhanced error logging with stack trace
      debugPrint('ERROR in _submitReport: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        NotificationUtils.showError(
          context,
          'Erreur lors de la soumission du rapport: $e',
        );
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  /// Display confirmation dialog before discarding changes and going back
  Future<bool> _confirmExit() async {
    // Save the current state automatically
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    if (viewModel.currentReport != null) {
      await viewModel.saveDraft();
    }

    final bool confirmed =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Quitter l\'édition ?'),
                content: const Text(
                  'Voulez-vous quitter l\'édition de ce rapport ? '
                  'Vos modifications ont été automatiquement enregistrées comme brouillon.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Quitter'),
                  ),
                ],
              ),
        ) ??
        false;

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: // In lib/views/screens/report_form/report_form_screen.dart
        // Update the actions section in the AppBar
        AppBar(
          title: Consumer<TechnicalVisitReportViewModel>(
            builder: (context, viewModel, _) {
              final report = viewModel.currentReport;
              final appBarTitle =
                  report == null || report.clientName.isEmpty
                      ? 'Nouveau rapport'
                      : 'Rapport: ${report.clientName}';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      appBarTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Floor selector only on step 2
                  if (viewModel.currentStep == 2) const FloorSelector(),
                ],
              );
            },
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            Consumer<TechnicalVisitReportViewModel>(
              builder: (context, viewModel, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSaving || viewModel.isLoading
                            ? null
                            : () async {
                              setState(() => _isSaving = true);
                              await viewModel.saveDraft();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Brouillon enregistré avec succès',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                setState(() => _isSaving = false);
                              }
                            },
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade100,

        body: Consumer<TechnicalVisitReportViewModel>(
          builder: (context, viewModel, _) {
            // Show loading indicator while initializing
            if (!_isInitialized || viewModel.currentReport == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Define titles for each step
            final stepTitles = [
              'Infos de base',
              'Contexte',
              'Composants',
              'Conclusion',
            ];

            // Get the current step content
            Widget currentStepContent;
            switch (viewModel.currentStep) {
              case 0:
                currentStepContent = const BasicInfoForm();
                break;
              case 1:
                currentStepContent = const ProjectContextForm();
                break;
              case 2:
                // This is our new floor-based component form
                currentStepContent = const FloorComponentsForm();
                break;
              case 3:
                currentStepContent = const ConclusionForm();
                break;
              default:
                currentStepContent = const Center(
                  child: Text('Cette section est en cours de développement.'),
                );
            }

            return Column(
              children: [
                // Step indicator
                FormStepIndicator(
                  currentStep: viewModel.currentStep,
                  totalSteps: stepTitles.length,
                  onStepTapped: _navigateToStep,
                  stepTitles: stepTitles,
                  stepsCompleted: [
                    viewModel.isBasicInfoValid(),
                    viewModel.isProjectContextValid(),
                    viewModel.isComponentsValid(),
                    viewModel.isConclusionValid(),
                  ],
                ),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: currentStepContent,
                    ),
                  ),
                ),

                // Navigation buttons
                // In file: lib/views/screens/report_form/report_form_screen.dart

                // Update the navigation buttons section in the build method
                // Replace the existing navigation buttons with this improved version:
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      OutlinedButton.icon(
                        onPressed:
                            viewModel.currentStep > 0 && !_isLoading
                                ? _previousStep
                                : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Précédent'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // Next/Submit button
                      if (viewModel.currentStep < stepTitles.length - 1)
                        ElevatedButton.icon(
                          onPressed:
                              _isLoading || viewModel.isLoading
                                  ? null
                                  : () async {
                                    setState(() => _isLoading = true);
                                    await _nextStep();
                                    if (mounted)
                                      setState(() => _isLoading = false);
                                  },
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.arrow_forward),
                          label: const Text('Suivant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed:
                              _isLoading ||
                                      viewModel.isLoading ||
                                      !viewModel.canSubmit
                                  ? null
                                  : _confirmSubmitReport,
                          icon:
                              _isLoading || viewModel.isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.check),
                          label: Text(
                            viewModel.canSubmit
                                ? 'Soumettre'
                                : 'Compléter le rapport',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                viewModel.canSubmit
                                    ? Colors.green
                                    : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
