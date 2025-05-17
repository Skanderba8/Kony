// lib/views/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:kony/views/widgets/app_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../view_models/admin_view_model.dart';
import '../../models/technical_visit_report.dart';
import '../../utils/notification_utils.dart';
import '../../app/routes.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Navigation vers l'écran de gestion des utilisateurs
  void _navigateToUserManagement() {
    Navigator.pushNamed(context, AppRoutes.userManagement);
  }

  // Gestion de la déconnexion
  Future<void> _logout() async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    try {
      await viewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          "Erreur lors de la déconnexion: ${viewModel.errorMessage ?? e}",
        );
      }
    }
  }

  // Ouvrir le PDF associé à un rapport de visite technique
  Future<void> _viewReportPdf(TechnicalVisitReport report) async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfFile = await viewModel.generateReportPdf(report.id);

      // Fermer l'indicateur de chargement
      if (mounted) Navigator.of(context).pop();

      if (pdfFile != null) {
        if (Platform.isAndroid || Platform.isIOS) {
          try {
            final result = await OpenFile.open(pdfFile.path);
            // Vérifier si l'ouverture a réussi d'une manière compatible avec n'importe quelle version de open_file
            if (result.type != 'done' && result.type != 'done') {
              debugPrint('Could not open PDF: ${result.message}');
              if (mounted) {
                NotificationUtils.showError(
                  context,
                  'Impossible d\'ouvrir le PDF: ${result.message}',
                );
              }
            }
          } catch (e) {
            debugPrint('Exception opening PDF: $e');
            if (mounted) {
              NotificationUtils.showError(
                context,
                'Échec de l\'ouverture du PDF: $e',
              );
            }
          }
        } else {
          NotificationUtils.showInfo(
            context,
            'PDF généré à: ${pdfFile.path}',
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        if (mounted) {
          NotificationUtils.showError(
            context,
            viewModel.errorMessage ?? 'Erreur lors de la génération du PDF',
          );
        }
      }
    } catch (e) {
      // Fermer l'indicateur de chargement s'il est toujours affiché
      if (mounted) Navigator.of(context).pop();
      debugPrint('Error generating PDF: $e');
      NotificationUtils.showError(
        context,
        'Erreur lors de la génération du PDF: $e',
      );
    }
  }

  // Mettre à jour le statut d'un rapport de visite technique
  Future<void> _updateReportStatus(
    TechnicalVisitReport report,
    String newStatus,
  ) async {
    final String statusText =
        newStatus == 'reviewed' ? 'Marquer comme Examiné' : 'Approuver';

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('$statusText?'),
                content: Text(
                  'Êtes-vous sûr de vouloir $statusText ce rapport?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(statusText),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      final viewModel = Provider.of<AdminViewModel>(context, listen: false);
      final success = await viewModel.updateReportStatus(report.id, newStatus);

      if (success && mounted) {
        NotificationUtils.showSuccess(
          context,
          'Rapport marqué comme ${newStatus.toUpperCase()} avec succès',
        );
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          viewModel.errorMessage ??
              'Échec de la mise à jour du statut du rapport',
        );
      }
    }
  }

  // Supprimer un rapport de visite technique
  Future<void> _confirmDeleteReport(TechnicalVisitReport report) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Supprimer le Rapport ?'),
                content: const Text(
                  'Êtes-vous sûr de vouloir supprimer ce rapport ? Cette action ne peut pas être annulée.',
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
      final viewModel = Provider.of<AdminViewModel>(context, listen: false);
      final success = await viewModel.deleteReport(report.id);

      if (success && mounted) {
        NotificationUtils.showSuccess(context, 'Rapport supprimé avec succès');
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          viewModel.errorMessage ?? 'Échec de la suppression du rapport',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppSidebar(
        userRole: 'admin',
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
      ),
      appBar: AppBar(
        title: const Text(
          'Tableau de Bord Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        automaticallyImplyLeading: false,

        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Soumis'),
            Tab(text: 'Examinés'),
            Tab(text: 'Approuvés'),
          ],
        ),
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, viewModel, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Onglet des rapports soumis
              _buildReportList(
                viewModel.getSubmittedReportsStream(),
                'submitted',
              ),

              // Onglet des rapports examinés
              _buildReportList(
                viewModel.getReviewedReportsStream(),
                'reviewed',
              ),

              // Onglet des rapports approuvés
              _buildReportList(
                viewModel.getApprovedReportsStream(),
                'approved',
              ),
            ],
          );
        },
      ),
    );
  }

  // Construire une liste de rapports basée sur le flux fourni et le statut
  Widget _buildReportList(
    Stream<List<TechnicalVisitReport>> stream,
    String status,
  ) {
    return StreamBuilder<List<TechnicalVisitReport>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des rapports: ${snapshot.error}',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () => setState(() {}), // Forcer le rafraîchissement
                  child: const Text('Réessayer'),
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
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'submitted'
                      ? 'Aucun rapport soumis'
                      : (status == 'reviewed'
                          ? 'Aucun rapport examiné'
                          : 'Aucun rapport approuvé'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report, status);
          },
        );
      },
    );
  }

  // Construire une carte pour afficher un rapport de visite technique
  Widget _buildReportCard(TechnicalVisitReport report, String status) {
    // Obtenir la couleur du statut
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'submitted':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment_turned_in;
        break;
      case 'reviewed':
        statusColor = Colors.purple;
        statusIcon = Icons.fact_check;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    // Obtenir la date à afficher
    final displayDate = report.submittedAt ?? report.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête du statut
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  status == 'submitted'
                      ? 'SOUMIS'
                      : (status == 'reviewed' ? 'EXAMINÉ' : 'APPROUVÉ'),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Soumis: ${_dateFormat.format(displayDate)} à ${_timeFormat.format(displayDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Contenu du rapport
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations sur le client
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.clientName.isNotEmpty
                                ? report.clientName
                                : '(Pas de nom de client)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lieu',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.location.isNotEmpty
                                ? report.location
                                : '(Pas d\'emplacement)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations sur le technicien
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Technicien',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.technicianName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chef de Projet',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.projectManager.isNotEmpty
                                ? report.projectManager
                                : '(Non spécifié)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Résumé des étages et des composants
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInfoBadge(
                        'Étages',
                        '${report.floors.length}',
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        'Composants',
                        _calculateTotalComponents(report).toString(),
                        Colors.amber.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        'Durée Est.',
                        '${report.estimatedDurationDays} jours',
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Boutons d'action - corrige le problème de débordement
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    // Bouton de suppression
                    IconButton(
                      onPressed: () => _confirmDeleteReport(report),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      tooltip: 'Supprimer le Rapport',
                    ),

                    // Bouton d'affichage du PDF
                    OutlinedButton.icon(
                      onPressed: () => _viewReportPdf(report),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Voir PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    // Boutons de mise à jour du statut en fonction du statut actuel
                    if (status == 'submitted')
                      ElevatedButton.icon(
                        onPressed:
                            () => _updateReportStatus(report, 'reviewed'),
                        icon: const Icon(Icons.fact_check, size: 18),
                        label: const Text('Marquer comme Examiné'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                    if (status == 'reviewed')
                      ElevatedButton.icon(
                        onPressed:
                            () => _updateReportStatus(report, 'approved'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire un badge d'information avec une étiquette et une valeur
  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Calculer le nombre total de composants sur tous les étages
  int _calculateTotalComponents(TechnicalVisitReport report) {
    int total = 0;
    for (final floor in report.floors) {
      total += floor.totalComponentCount;
    }
    return total;
  }
}
