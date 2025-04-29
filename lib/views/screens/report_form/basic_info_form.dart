// lib/views/screens/report_form/basic_info_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../widgets/report_form/section_header.dart';
import '../../widgets/report_form/form_text_field.dart';

/// The first step in the technical visit report form.
/// Collects basic information such as date, client, location, etc.
class BasicInfoForm extends StatefulWidget {
  const BasicInfoForm({super.key});

  @override
  _BasicInfoFormState createState() => _BasicInfoFormState();
}

class _BasicInfoFormState extends State<BasicInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _locationController = TextEditingController();
  final _projectManagerController = TextEditingController();
  final _accompanyingPersonController = TextEditingController();
  final _techniciansController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  @override
  void dispose() {
    _clientController.dispose();
    _locationController.dispose();
    _projectManagerController.dispose();
    _accompanyingPersonController.dispose();
    _techniciansController.dispose();
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
        _selectedDate = report.date;
        _clientController.text = report.clientName;
        _locationController.text = report.location;
        _projectManagerController.text = report.projectManager;
        _accompanyingPersonController.text = report.accompanyingPerson;
        _techniciansController.text = report.technicians.join(', ');
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

    // Convert comma-separated technicians to a list
    final List<String> technicians =
        _techniciansController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    viewModel.updateBasicInfo(
      date: _selectedDate,
      clientName: _clientController.text,
      location: _locationController.text,
      projectManager: _projectManagerController.text,
      technicians: technicians,
      accompanyingPerson: _accompanyingPersonController.text,
    );

    viewModel.saveDraft();
  }

  /// Show date picker and update selected date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'), // French locale
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _saveFormData();
    }
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
            title: 'Informations de base',
            subtitle:
                'Veuillez saisir les informations générales concernant cette visite technique.',
            icon: Icons.info_outline,
          ),

          // Date Field
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date de visite *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateFormat.format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Client Field
          FormTextField(
            label: 'Client',
            hintText: 'Nom du client',
            controller: _clientController,
            required: true,
          ),

          // Location Field
          FormTextField(
            label: 'Lieu',
            hintText: 'Adresse ou emplacement',
            controller: _locationController,
            required: true,
          ),

          // Project Manager Field
          FormTextField(
            label: 'Responsable de projet',
            hintText: 'Nom du responsable',
            controller: _projectManagerController,
            required: true,
          ),

          // Technicians Field
          FormTextField(
            label: 'Techniciens intervenants',
            hintText: 'Noms des techniciens (séparés par des virgules)',
            controller: _techniciansController,
            required: true,
          ),

          // Accompanying Person Field
          FormTextField(
            label: 'Nom de l\'accompagnant',
            hintText: 'Personne accompagnant la visite',
            controller: _accompanyingPersonController,
          ),
        ],
      ),
    );
  }
}
