// lib/views/screens/report_form/conclusion_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../widgets/report_form/section_header.dart';
import '../../widgets/report_form/form_text_field.dart';
import '../../widgets/report_form/form_number_field.dart';

/// The fourth and final step in the technical visit report form.
/// Captures the conclusion, duration estimate, and assumptions.
class ConclusionForm extends StatefulWidget {
  const ConclusionForm({super.key});

  @override
  _ConclusionFormState createState() => _ConclusionFormState();
}

class _ConclusionFormState extends State<ConclusionForm> {
  final _formKey = GlobalKey<FormState>();
  final _conclusionController = TextEditingController();
  final _assumptionsController = TextEditingController();
  int _estimatedDurationDays = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  @override
  void dispose() {
    _conclusionController.dispose();
    _assumptionsController.dispose();
    super.dispose();
  }

  /// Initialize form with data from the current report
  void _initializeFormData() {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );
    final report = viewModel.currentReport;

    if (report != null) {
      setState(() {
        _conclusionController.text = report.conclusion;
        _estimatedDurationDays = report.estimatedDurationDays;
        _assumptionsController.text = report.assumptions.join('\n');
      });
    }
  }

  /// Save form data to the report
  void _saveFormData() {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    // Convert assumptions text to a list, splitting by newlines
    final List<String> assumptions =
        _assumptionsController.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    viewModel.updateConclusion(
      conclusion: _conclusionController.text,
      estimatedDurationDays: _estimatedDurationDays,
      assumptions: assumptions,
    );

    viewModel.saveDraft();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: _saveFormData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Conclusion',
            subtitle:
                'Résumez les conclusions de la visite technique et précisez les éléments importants pour le déploiement.',
            icon: Icons.summarize_outlined,
          ),

          // Conclusion text field
          FormTextField(
            label: 'Conclusion générale',
            hintText:
                'Décrivez les conclusions générales de la visite et vos recommandations...',
            controller: _conclusionController,
            multiline: true,
            maxLines: 8,
            required: true,
            keyboardType: TextInputType.multiline,
          ),

          // Estimated duration
          FormNumberField(
            label: 'Durée estimée du déploiement (jours)',
            value: _estimatedDurationDays,
            min: 1,
            max: 365,
            required: true,
            decimal: false,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _estimatedDurationDays = value.toInt();
                });
                _saveFormData();
              }
            },
          ),

          // Assumptions and prerequisites
          FormTextField(
            label: 'Hypothèses et prérequis',
            hintText:
                'Listez chaque hypothèse ou prérequis sur une ligne distincte.\nEx: Accès au site garanti pendant les heures de travail\nEx: Alimentation électrique disponible dans tous les locaux',
            controller: _assumptionsController,
            multiline: true,
            maxLines: 6,
            required: false,
            keyboardType: TextInputType.multiline,
          ),

          // Helper text
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Ces informations apparaîtront dans la section "Conclusion" du rapport final. '
              'Veuillez inclure toutes les observations importantes, les recommandations, '
              'ainsi que les conditions préalables nécessaires au bon déroulement du projet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
