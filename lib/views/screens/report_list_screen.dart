// lib/views/screens/report_list_screen.dart
import 'package:flutter/material.dart';
import 'package:kony/app/routes.dart';
import 'package:kony/services/pdf_generation_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/technical_visit_report_view_model.dart';
import '../../models/technical_visit_report.dart';
import '../../services/technical_visit_report_service.dart';
import '../screens/report_form/report_form_screen.dart';
import '../../utils/notification_utils.dart';
import 'dart:io';
import '../screens/pdf_viewer_screen.dart';
import '../../app/routes.dart';

/// Screen that displays a list of technical visit reports for the technician.
/// Allows creating new reports and managing existing ones.
class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the ViewModel when dependencies change
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );
  }

  /// Navigate back to the technician home screen
  void _navigateBack() {
    Navigator.of(context).pop();
  }

  /// Start creating a new report
  Future<void> _createNewReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportFormScreen()),
    );

    if (result == true) {
      // Report was submitted successfully, show notification
      if (mounted) {
        NotificationUtils.showSuccess(context, 'Rapport soumis avec succès !');
      }
    }
  }

  /// Open an existing report for editing or viewing
  Future<void> _openReport(TechnicalVisitReport report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportFormScreen(reportId: report.id),
      ),
    );

    if (result == true && mounted) {
      // Report was submitted successfully, show notification
      NotificationUtils.showSuccess(context, 'Rapport soumis avec succès !');
    }
  }

  /// Show delete confirmation dialog
  Future<void> _confirmDeleteReport(TechnicalVisitReport report) async {
    if (report.status != 'draft') {
      // Only draft reports can be deleted
      NotificationUtils.showWarning(
        context,
        'Seuls les rapports en brouillon peuvent être supprimés.',
      );
      return;
    }

    final bool confirmed =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Supprimer ce brouillon ?'),
                content: const Text(
                  'Cette action est irréversible. Voulez-vous vraiment supprimer ce brouillon de rapport ?',
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
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      _deleteReport(report);
    }
  }

  /// Delete a report
  Future<void> _deleteReport(TechnicalVisitReport report) async {
    try {
      // Access the service directly through Provider - better for separation of concerns
      await Provider.of<TechnicalVisitReportService>(
        context,
        listen: false,
      ).deleteReport(report.id);

      if (mounted) {
        NotificationUtils.showSuccess(
          context,
          'Brouillon supprimé avec succès.',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Erreur lors de la suppression: $e',
        );
      }
    }
  }

  /// Get an appropriate color for the report status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      case 'reviewed':
        return Colors.purple;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get an appropriate icon for the report status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_note;
      case 'submitted':
        return Icons.send;
      case 'reviewed':
        return Icons.fact_check;
      case 'approved':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  /// Get a translated status label
  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Brouillon';
      case 'submitted':
        return 'Soumis';
      case 'reviewed':
        return 'Examiné';
      case 'approved':
        return 'Approuvé';
      default:
        return status;
    }
  }

  /// Show filter options for reports
  void _showFilterOptions() {
    // This is a placeholder for future filter functionality
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrer les rapports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Placeholder for future filter options
                const Text(
                  'Options de filtrage à venir dans une prochaine mise à jour.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visites Techniques',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
        actions: [
          // Filter button (for future use)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filtrer',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [Tab(text: 'Brouillons'), Tab(text: 'Soumis')],
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewReport,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Drafts Tab
          _buildReportList(true),

          // Submitted Reports Tab
          _buildReportList(false),
        ],
      ),
    );
  }

  /// Builds a list of reports based on whether they are drafts or submitted
  Widget _buildReportList(bool showDrafts) {
    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<TechnicalVisitReport>>(
          stream:
              showDrafts
                  ? viewModel.getDraftReportsStream()
                  : viewModel.getSubmittedReportsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement des rapports',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showDrafts ? Icons.edit_note : Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      showDrafts
                          ? 'Aucun brouillon disponible'
                          : 'Aucun rapport soumis',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      showDrafts
                          ? 'Commencez par créer un nouveau rapport'
                          : 'Vos rapports soumis apparaîtront ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (showDrafts) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewReport,
                        icon: const Icon(Icons.add),
                        label: const Text('Nouveau rapport'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportCard(report, showDrafts);
              },
            );
          },
        );
      },
    );
  }

  /// Builds a card representing a single report
  Widget _buildReportCard(TechnicalVisitReport report, bool isDraft) {
    final bool hasClientName = report.clientName.isNotEmpty;
    final String displayTitle =
        hasClientName ? report.clientName : 'Rapport sans nom';

    final String subtitle =
        hasClientName ? report.location : 'Brouillon en cours d\'édition';

    final DateTime displayDate =
        isDraft
            ? report.lastModified ?? report.createdAt
            : report.submittedAt ?? report.createdAt;

    final String dateLabel = isDraft ? 'Modifié le' : 'Soumis le';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openReport(report),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge at top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(report.status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(report.status),
                    size: 16,
                    color: _getStatusColor(report.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(report.status),
                    style: TextStyle(
                      color: _getStatusColor(report.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Report content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateFormat.format(displayDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _timeFormat.format(displayDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Footer with action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Project manager or technician name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Responsable',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.projectManager.isNotEmpty
                                  ? report.projectManager
                                  : 'Non spécifié',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    report.projectManager.isEmpty
                                        ? Colors.grey.shade400
                                        : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Action buttons based on status
                      Row(
                        children: [
                          if (isDraft) ...[
                            // Delete button for drafts
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              onPressed: () => _confirmDeleteReport(report),
                              tooltip: 'Supprimer',
                              visualDensity: VisualDensity.compact,
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openReport(report),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Continuer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Edit button (just a pen icon) for submitted reports
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () => _openReport(report),
                              tooltip: 'Modifier',
                              visualDensity: VisualDensity.compact,
                            ),
                            // Prominent PDF button for submitted reports
                            ElevatedButton.icon(
                              onPressed: () => _viewReportPdf(report),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('Voir PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewReportPdf(TechnicalVisitReport report) async {
    try {
      // Show loading indicator dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );

      // Get the PDF generation service
      final pdfService = Provider.of<PdfGenerationService>(
        context,
        listen: false,
      );

      // Generate the PDF
      final File pdfFile = await pdfService.generateTechnicalReportPdf(report);

      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to PDF viewer
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PdfViewerScreen(
                  pdfFile: pdfFile,
                  reportName:
                      report.clientName.isNotEmpty
                          ? report.clientName
                          : 'Rapport de visite technique',
                ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error notification
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Erreur lors de la génération du PDF: $e',
        );
      }
    }
  }
}
