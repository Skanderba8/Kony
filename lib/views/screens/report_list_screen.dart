// lib/views/screens/report_list_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:kony/views/widgets/app_sidebar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'package:kony/app/routes.dart';
import 'package:kony/services/pdf_generation_service.dart';
import '../../models/technical_visit_report.dart';
import '../../services/technical_visit_report_service.dart';
import '../../utils/notification_utils.dart';
import '../../view_models/technical_visit_report_view_model.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/report_form/report_form_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedFilter = 'all';

  final Map<String, Map<String, dynamic>> _filterOptions = {
    'all': {
      'label': 'Tous',
      'color': Colors.purple,
      'icon': Icons.list_alt,
      'description': 'Tous les rapports',
    },
    'draft': {
      'label': 'Brouillons',
      'color': Colors.orange,
      'icon': Icons.edit_note,
      'description': 'Rapports en cours d\'édition',
    },
    'submitted': {
      'label': 'Soumis',
      'color': Colors.blue,
      'icon': Icons.send,
      'description': 'En attente de réponse',
    },
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _navigateToForm([String? reportId]) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.reportForm,
      arguments: reportId != null ? {'reportId': reportId} : null,
    );

    if (result == true && mounted) {
      NotificationUtils.showSuccess(context, 'Rapport mis à jour avec succès');
    }
  }

  Future<void> _confirmDeleteReport(TechnicalVisitReport report) async {
    final bool confirmed =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
      try {
        final service = Provider.of<TechnicalVisitReportService>(
          context,
          listen: false,
        );
        await service.deleteReport(report.id);

        if (mounted) {
          NotificationUtils.showSuccess(context, 'Brouillon supprimé.');
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
  }

  Future<void> _viewReportPdf(TechnicalVisitReport report) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final pdfService = Provider.of<PdfGenerationService>(
        context,
        listen: false,
      );
      final File pdfFile = await pdfService.generateTechnicalReportPdf(report);

      if (mounted) Navigator.pop(context);

      if (Platform.isAndroid || Platform.isIOS) {
        await OpenFile.open(pdfFile.path);
      } else {
        NotificationUtils.showInfo(context, 'PDF généré à: ${pdfFile.path}');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Erreur lors de la génération du PDF: $e',
        );
      }
    }
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildFilterInfo(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par client, lieu...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final key = _filterOptions.keys.elementAt(index);
          final data = _filterOptions[key]!;
          final isSelected = _selectedFilter == key;

          return Container(
            margin: EdgeInsets.only(
              right: index < _filterOptions.length - 1 ? 8 : 0,
            ),
            child: StreamBuilder<List<TechnicalVisitReport>>(
              stream: _getStreamForFilter(key),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return GestureDetector(
                  onTap: () => _changeFilter(key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? data['color']
                              : (data['color'] as Color).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? data['color']
                                : (data['color'] as Color).withOpacity(0.25),
                        width: 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: (data['color'] as Color).withOpacity(
                                    0.2,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data['icon'],
                          size: 14,
                          color: isSelected ? Colors.white : data['color'],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${data['label']} ($count)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSelected ? Colors.white : data['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterInfo() {
    final data = _filterOptions[_selectedFilter]!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (data['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (data['color'] as Color).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (data['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data['icon'], size: 16, color: data['color']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrage: ${data['label']}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: data['color'],
                  ),
                ),
                Text(
                  data['description'],
                  style: TextStyle(
                    fontSize: 11,
                    color: (data['color'] as Color).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final data = _filterOptions[_selectedFilter]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (data['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data['icon'],
              size: 64,
              color: (data['color'] as Color).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat pour "$_searchQuery"'
                : 'Aucun rapport ${_getEmptyStateText()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Les rapports ${_getEmptyStateText()} apparaîtront ici',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _searchController.clear(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  String _getEmptyStateText() {
    switch (_selectedFilter) {
      case 'draft':
        return 'brouillon';
      case 'submitted':
        return 'soumis';
      default:
        return 'disponible';
    }
  }

  Stream<List<TechnicalVisitReport>> _getStreamForFilter(String filter) {
    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    switch (filter) {
      case 'draft':
        return viewModel.getDraftReportsStream();

      case 'submitted':
        return viewModel.getSubmittedReportsStream();

      case 'all':
      default:
        // Combine drafts + submitted using a single stream that emits when either changes
        return Rx.combineLatest2(
          viewModel.getDraftReportsStream(),
          viewModel.getSubmittedReportsStream(),
          (
            List<TechnicalVisitReport> drafts,
            List<TechnicalVisitReport> submitted,
          ) {
            return [...drafts, ...submitted];
          },
        );
    }
  }

  Widget _buildReportCard(TechnicalVisitReport report) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');

    IconData statusIcon;
    Color statusColor;
    String statusLabel;

    switch (report.status) {
      case 'draft':
        statusIcon = Icons.edit_note;
        statusColor = Colors.orange;
        statusLabel = 'BROUILLON';
        break;
      case 'submitted':
        statusIcon = Icons.send;
        statusColor = Colors.blue;
        statusLabel = 'SOUMIS';
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
        statusLabel = 'INCONNU';
    }

    final displayDate =
        report.status == 'draft'
            ? report.lastModified ?? report.createdAt
            : report.submittedAt ?? report.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToForm(report.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, size: 16, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dateFormat.format(displayDate)} • ${timeFormat.format(displayDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.clientName.isNotEmpty
                                    ? report.clientName
                                    : 'Rapport sans nom',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    report.location.isNotEmpty
                                        ? report.location
                                        : 'Lieu non spécifié',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.manage_accounts,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Responsable: ${report.projectManager.isNotEmpty ? report.projectManager : "Non spécifié"}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (report.status == 'draft')
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToForm(report.id),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Modifier'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade600,
                                side: BorderSide(color: Colors.orange.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        if (report.status == 'draft') const SizedBox(width: 8),
                        if (report.status == 'draft')
                          IconButton(
                            onPressed: () => _confirmDeleteReport(report),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                          ),
                        if (report.status == 'submitted')
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _viewReportPdf(report),
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text('Voir PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<TechnicalVisitReport>>(
          stream: _getStreamForFilter(_selectedFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString()),
                  ],
                ),
              );
            }

            List<TechnicalVisitReport> reports = snapshot.data ?? [];

            if (_searchQuery.isNotEmpty) {
              reports =
                  reports.where((r) {
                    return r.clientName.toLowerCase().contains(_searchQuery) ||
                        r.location.toLowerCase().contains(_searchQuery);
                  }).toList();
            }

            if (reports.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return _buildReportCard(reports[index]);
              },
            );
          },
        );
      },
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Mes Rapports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to dashboard
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.technician,
              (route) => false,
            );
          },
        ),
        actions: [
          // Sidebar toggle
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      drawer: AppSidebar(
        userRole: 'technician',
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeaderSection(),
              Expanded(child: _buildReportsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
