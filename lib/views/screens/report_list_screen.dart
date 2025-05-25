// lib/views/screens/report_list_screen.dart
import 'dart:async';
import 'dart:io';
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

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _fabAnimationController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final Map<String, Map<String, dynamic>> _filterOptions = {
    'all': {
      'label': 'Tous',
      'color': Colors.indigo,
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
    _initializeAnimations();
    _setupSearch();
  }

  void _initializeAnimations() {
    // Header animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Content animation
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _fabAnimationController.forward();
    });
  }

  void _setupSearch() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _navigateBackToDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.technician,
      (route) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAnimatedAppBar(),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Column(
                  children: [_buildHeaderSection(), const SizedBox(height: 8)],
                ),
              ),
            ),
          ),
          _buildReportsList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _navigateBackToDashboard,
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.indigo.shade600,
              ),
              tooltip: 'Retour au tableau de bord',
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        title: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: const Text(
              'Mes Rapports',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade600,
                Colors.blue.shade500,
                Colors.cyan.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    onPressed: () => _searchController.clear(),
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
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final key = _filterOptions.keys.elementAt(index);
          final data = _filterOptions[key]!;
          final isSelected = _selectedFilter == key;

          return Container(
            margin: EdgeInsets.only(
              right: index < _filterOptions.length - 1 ? 12 : 0,
            ),
            child: StreamBuilder<List<TechnicalVisitReport>>(
              stream: _getStreamForFilter(key),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _changeFilter(key),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? data['color']
                                  : (data['color'] as Color).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isSelected
                                    ? data['color']
                                    : (data['color'] as Color).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: (data['color'] as Color)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
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
                              size: 16,
                              color: isSelected ? Colors.white : data['color'],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${data['label']} ($count)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color:
                                    isSelected ? Colors.white : data['color'],
                              ),
                            ),
                          ],
                        ),
                      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (data['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (data['color'] as Color).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (data['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data['icon'], size: 18, color: data['color']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrage: ${data['label']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: data['color'],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['description'],
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildReportsList() {
    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<TechnicalVisitReport>>(
          stream: _getStreamForFilter(_selectedFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des rapports...'),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(
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
              return SliverFillRemaining(child: _buildEmptyState());
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: _buildReportCard(reports[index]),
                        ),
                      );
                    },
                  );
                }, childCount: reports.length),
              ),
            );
          },
        );
      },
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToForm(report.id),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Status header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
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
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
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
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dateFormat.format(displayDate)} • ${timeFormat.format(displayDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Report content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and location
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
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

                    const SizedBox(height: 12),

                    // Project manager info
                    Row(
                      children: [
                        Icon(
                          Icons.manage_accounts,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
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

                    const SizedBox(height: 20),

                    // Action buttons
                    _buildActionButtons(report),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(TechnicalVisitReport report) {
    return Row(
      children: [
        if (report.status == 'draft') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _navigateToForm(report.id),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade600,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _confirmDeleteReport(report),
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red.shade400,
              tooltip: 'Supprimer',
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
        if (report.status == 'submitted') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _viewReportPdf(report),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('Voir PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final data = _filterOptions[_selectedFilter]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Effacer la recherche'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nouveau Rapport',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
}
