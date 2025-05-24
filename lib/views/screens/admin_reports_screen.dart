// lib/views/screens/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../view_models/admin_view_model.dart';
import '../../models/technical_visit_report.dart';
import '../../utils/notification_utils.dart';
import '../widgets/app_sidebar.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  _AdminReportsScreenState createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter options with their display names and colors
  final Map<String, Map<String, dynamic>> _filterOptions = {
    'all': {
      'label': 'Tous',
      'color': Colors.purple,
      'icon': Icons.list_alt,
      'description': 'Tous les rapports',
    },
    'submitted': {
      'label': 'Soumis',
      'color': Colors.orange,
      'icon': Icons.assignment_turned_in,
      'description': 'En attente de révision',
    },
    'reviewed': {
      'label': 'Examinés',
      'color': Colors.blue,
      'icon': Icons.fact_check,
      'description': 'Révisés et validés',
    },
    'approved': {
      'label': 'Approuvés',
      'color': Colors.green,
      'icon': Icons.check_circle,
      'description': 'Finalisés et approuvés',
    },
    'draft': {
      'label': 'Brouillons',
      'color': Colors.grey,
      'icon': Icons.edit_note,
      'description': 'Rapports en cours d\'édition',
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

    // Listen to search changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get initial filter from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null &&
        args['filter'] != null &&
        _filterOptions.containsKey(args['filter'])) {
      setState(() {
        _selectedFilter = args['filter'];
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppSidebar(
        userRole: 'admin',
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
      ),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestion des Rapports',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade800,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the data
              setState(() {});
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header with search and filters
                _buildHeaderSection(),

                // Reports list
                Expanded(child: _buildReportsList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          _buildSearchBar(),

          const SizedBox(height: 20),

          // Filter chips
          _buildFilterChips(),

          const SizedBox(height: 16),

          // Current filter info
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
          hintText: 'Rechercher par client, lieu, technicien...',
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
          final filterKey = _filterOptions.keys.elementAt(index);
          final filterData = _filterOptions[filterKey]!;
          final isSelected = _selectedFilter == filterKey;

          return Container(
            margin: EdgeInsets.only(
              right: index < _filterOptions.length - 1 ? 8 : 0,
            ),
            child: StreamBuilder<List<TechnicalVisitReport>>(
              stream: _getStreamForFilter(filterKey),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;

                return GestureDetector(
                  onTap: () => _changeFilter(filterKey),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? filterData['color']
                              : (filterData['color'] as Color).withOpacity(
                                0.08,
                              ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? filterData['color']
                                : (filterData['color'] as Color).withOpacity(
                                  0.25,
                                ),
                        width: 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: (filterData['color'] as Color)
                                      .withOpacity(0.2),
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
                          filterData['icon'] as IconData,
                          size: 14,
                          color:
                              isSelected ? Colors.white : filterData['color'],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${filterData['label']} ($count)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color:
                                isSelected ? Colors.white : filterData['color'],
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
    final filterData = _filterOptions[_selectedFilter]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (filterData['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (filterData['color'] as Color).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (filterData['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              filterData['icon'] as IconData,
              size: 16,
              color: filterData['color'],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrage: ${filterData['label']}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: filterData['color'],
                  ),
                ),
                Text(
                  filterData['description'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: (filterData['color'] as Color).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<TechnicalVisitReport>>(
          stream: _getStreamForFilter(_selectedFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des rapports...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            List<TechnicalVisitReport> reports = snapshot.data ?? [];

            // Apply search filter
            if (_searchQuery.isNotEmpty) {
              reports =
                  reports.where((report) {
                    return report.clientName.toLowerCase().contains(
                          _searchQuery,
                        ) ||
                        report.location.toLowerCase().contains(_searchQuery) ||
                        report.technicianName.toLowerCase().contains(
                          _searchQuery,
                        ) ||
                        report.projectManager.toLowerCase().contains(
                          _searchQuery,
                        );
                  }).toList();
            }

            if (reports.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportCard(report, viewModel);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReportCard(
    TechnicalVisitReport report,
    AdminViewModel viewModel,
  ) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (report.status) {
      case 'draft':
        statusColor = Colors.grey;
        statusIcon = Icons.edit_note;
        statusText = 'BROUILLON';
        break;
      case 'submitted':
        statusColor = Colors.orange;
        statusIcon = Icons.assignment_turned_in;
        statusText = 'SOUMIS';
        break;
      case 'reviewed':
        statusColor = Colors.blue;
        statusIcon = Icons.fact_check;
        statusText = 'EXAMINÉ';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'APPROUVÉ';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = report.status.toUpperCase();
    }

    final displayDate =
        report.status == 'draft'
            ? (report.lastModified ?? report.createdAt)
            : (report.submittedAt ?? report.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
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

            // Report content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and client
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
                                Expanded(
                                  child: Text(
                                    report.location.isNotEmpty
                                        ? report.location
                                        : 'Lieu non spécifié',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
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

                  const SizedBox(height: 12),

                  // Technician and project manager info
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Par: ${report.technicianName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                'Chef: ${report.projectManager.isNotEmpty ? report.projectManager : "Non spécifié"}',
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

                  // Action buttons
                  Row(
                    children: [
                      // PDF Button (for non-draft reports)
                      if (report.status != 'draft') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewReportPdf(report, viewModel),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Status action button
                      if (report.status == 'submitted') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _updateReportStatus(
                                  report,
                                  'reviewed',
                                  viewModel,
                                ),
                            icon: const Icon(Icons.fact_check, size: 16),
                            label: const Text('Examiner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ] else if (report.status == 'reviewed') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _updateReportStatus(
                                  report,
                                  'approved',
                                  viewModel,
                                ),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Approuver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ] else if (report.status == 'draft') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewDraftReport(report),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Modifier'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade600,
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Approuvé',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(width: 8),

                      // Delete button
                      IconButton(
                        onPressed:
                            () => _confirmDeleteReport(report, viewModel),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.red.shade400,
                        tooltip: 'Supprimer',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          padding: const EdgeInsets.all(8),
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
    );
  }

  Widget _buildEmptyState() {
    final filterData = _filterOptions[_selectedFilter]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (filterData['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              filterData['icon'] as IconData,
              size: 64,
              color: (filterData['color'] as Color).withOpacity(0.6),
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
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Stream<List<TechnicalVisitReport>> _getStreamForFilter(String filter) {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    switch (filter) {
      case 'submitted':
        return viewModel.getSubmittedReportsStream();
      case 'reviewed':
        return viewModel.getReviewedReportsStream();
      case 'approved':
        return viewModel.getApprovedReportsStream();
      case 'draft':
        // You'll need to add this method to AdminViewModel
        return viewModel.getAllReportsStream().map(
          (reports) => reports.where((r) => r.status == 'draft').toList(),
        );
      case 'all':
      default:
        return viewModel.getAllReportsStream();
    }
  }

  String _getEmptyStateText() {
    switch (_selectedFilter) {
      case 'draft':
        return 'brouillon';
      case 'submitted':
        return 'soumis';
      case 'reviewed':
        return 'examiné';
      case 'approved':
        return 'approuvé';
      default:
        return 'disponible';
    }
  }

  // Action methods
  Future<void> _viewReportPdf(
    TechnicalVisitReport report,
    AdminViewModel viewModel,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfFile = await viewModel.generateReportPdf(report.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (pdfFile != null) {
        if (Platform.isAndroid || Platform.isIOS) {
          final result = await OpenFile.open(pdfFile.path);
          if (result.type != 'done' && mounted) {
            NotificationUtils.showError(
              context,
              'Impossible d\'ouvrir le PDF: ${result.message}',
            );
          }
        } else {
          NotificationUtils.showInfo(
            context,
            'PDF généré à: ${pdfFile.path}',
            duration: const Duration(seconds: 5),
          );
        }
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          viewModel.errorMessage ?? 'Erreur lors de la génération du PDF',
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        NotificationUtils.showError(
          context,
          'Erreur lors de la génération du PDF: $e',
        );
      }
    }
  }

  Future<void> _updateReportStatus(
    TechnicalVisitReport report,
    String newStatus,
    AdminViewModel viewModel,
  ) async {
    final statusText = newStatus == 'reviewed' ? 'examiner' : 'approuver';

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  '${statusText.substring(0, 1).toUpperCase()}${statusText.substring(1)} ce rapport ?',
                ),
                content: Text(
                  'Êtes-vous sûr de vouloir $statusText ce rapport ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      statusText.substring(0, 1).toUpperCase() +
                          statusText.substring(1),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      final success = await viewModel.updateReportStatus(report.id, newStatus);

      if (success && mounted) {
        NotificationUtils.showSuccess(
          context,
          'Rapport ${newStatus == "reviewed" ? "examiné" : "approuvé"} avec succès',
        );
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          viewModel.errorMessage ?? 'Échec de la mise à jour du statut',
        );
      }
    }
  }

  Future<void> _confirmDeleteReport(
    TechnicalVisitReport report,
    AdminViewModel viewModel,
  ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Supprimer ce rapport ?'),
                content: const Text(
                  'Cette action est irréversible. Voulez-vous vraiment supprimer ce rapport ?',
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

  void _viewDraftReport(TechnicalVisitReport report) {
    // Navigate to report editing screen for drafts
    // This would typically navigate to the report form screen with the report ID
    NotificationUtils.showInfo(
      context,
      'Fonctionnalité de modification des brouillons en cours de développement',
    );
  }
}
