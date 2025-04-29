// lib/views/screens/report_form/project_context_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../widgets/report_form/section_header.dart';
import '../../widgets/report_form/form_text_field.dart';

/// The second step in the technical visit report form.
/// Captures the project context as a rich text field.
class ProjectContextForm extends StatefulWidget {
  const ProjectContextForm({super.key});

  @override
  _ProjectContextFormState createState() => _ProjectContextFormState();
}

class _ProjectContextFormState extends State<ProjectContextForm> {
  final _formKey = GlobalKey<FormState>();
  final _contextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  @override
  void dispose() {
    _contextController.dispose();
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
        _contextController.text = report.projectContext;
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
    viewModel.updateProjectContext(_contextController.text);
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
            title: 'Contexte du projet',
            subtitle:
                'Décrivez le contexte général du projet et les objectifs de la visite technique.',
            icon: Icons.description_outlined,
          ),

          FormTextField(
            label: 'Description du contexte',
            hintText:
                'Après analyse du rapport d\'audit en interne, nous avons établi une visite de site afin de valider la faisabilité et d\'anticiper des éventuelles imprévue liée au déploiement...',
            controller: _contextController,
            multiline: true,
            maxLines: 15,
            required: true,
            keyboardType: TextInputType.multiline,
          ),

          // Helper text
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Ce texte apparaîtra dans la section "Contexte du projet" du rapport final. '
              'Veuillez inclure les informations pertinentes concernant l\'objectif du déploiement, '
              'les études préalables, et les principaux défis identifiés.',
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
