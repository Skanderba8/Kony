// lib/views/screens/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../view_models/admin_view_model.dart';
import '../../models/technical_visit_report.dart';
import '../../utils/notification_utils.dart';
import '../../app/routes.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  _AdminReportsScreenState createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _searchAnimationController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _searchScaleAnimation;

  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter options with refined colors
  final Map<String, Map<String, dynamic>> _filterOptions = {
    'all': {
      'label': 'Tous',
      'color': Colors.indigo,
      'icon': Icons.list_alt,
      'description': 'Tous les rapports',
    },
    'submitted': {
      'label': 'Soumis',
      'color': Colors.blue,
      'icon': Icons.assignment_turned_in,
      'description': 'En attente de révision',
    },
    'reviewed': {
      'label': 'Examinés',
      'color': Colors.teal,
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
      'color': Colors.orange,
      'icon': Icons.edit_note,
      'description': 'Rapports en cours d\'édition',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSearch();
    // Removed _getInitialFilter() from initState - it's too early
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move the initial filter logic here - this is called after the route is available
    _getInitialFilter();
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

    // Search animation
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _searchScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _searchAnimationController.forward();
    });
  }

  void _setupSearch() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _getInitialFilter() {
    // This is now safe to call since the route is available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null &&
        args['filter'] != null &&
        _filterOptions.containsKey(args['filter'])) {
      if (mounted) {
        setState(() {
          _selectedFilter = args['filter'];
        });
      }
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _navigateBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.admin,
      (route) => false,
    );
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
              onPressed: _navigateBack,
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.indigo.shade600,
              ),
              tooltip: 'Retour au tableau de bord',
            ),
          ),
        ),
      ),
      actions: [
        SlideTransition(
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
                onPressed: () => setState(() {}),
                icon: Icon(Icons.refresh, color: Colors.indigo.shade600),
                tooltip: 'Actualiser',
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        title: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: const Text(
              'Gestion des Rapports',
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
                Colors.teal.shade400,
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
          ScaleTransition(
            scale: _searchScaleAnimation,
            child: _buildSearchBar(),
          ),
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
          final filterKey = _filterOptions.keys.elementAt(index);
          final filterData = _filterOptions[filterKey]!;
          final isSelected = _selectedFilter == filterKey;

          return Container(
            margin: EdgeInsets.only(
              right: index < _filterOptions.length - 1 ? 12 : 0,
            ),
            child: StreamBuilder<List<TechnicalVisitReport>>(
              stream: _getStreamForFilter(filterKey),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _changeFilter(filterKey),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? filterData['color']
                                  : (filterData['color'] as Color).withOpacity(
                                    0.08,
                                  ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isSelected
                                    ? filterData['color']
                                    : (filterData['color'] as Color)
                                        .withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: (filterData['color'] as Color)
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
                              filterData['icon'],
                              size: 16,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : filterData['color'],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${filterData['label']} ($count)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : filterData['color'],
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
    final filterData = _filterOptions[_selectedFilter]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (filterData['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (filterData['color'] as Color).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (filterData['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              filterData['icon'],
              size: 18,
              color: filterData['color'],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrage: ${filterData['label']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: filterData['color'],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  filterData['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
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
                child: _buildErrorState(snapshot.error.toString()),
              );
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
              return SliverFillRemaining(child: _buildEmptyState());
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                          child: _buildReportCard(reports[index], viewModel),
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
        statusColor = Colors.orange;
        statusIcon = Icons.edit_note;
        statusText = 'BROUILLON';
        break;
      case 'submitted':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment_turned_in;
        statusText = 'SOUMIS';
        break;
      case 'reviewed':
        statusColor = Colors.teal;
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
      child: Column(
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                // Title and client
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
                          const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
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

                const SizedBox(height: 20),

                // Action buttons
                _buildActionButtons(report, viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    TechnicalVisitReport report,
    AdminViewModel viewModel,
  ) {
    return Row(
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Status action button
        if (report.status == 'submitted') ...[
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed:
                  () => _updateReportStatus(report, 'reviewed', viewModel),
              icon: const Icon(Icons.fact_check, size: 16),
              label: const Text('Examiner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ] else if (report.status == 'reviewed') ...[
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed:
                  () => _updateReportStatus(report, 'approved', viewModel),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Approuver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ] else if (report.status == 'draft') ...[
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => _viewDraftReport(report),
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
        ] else ...[
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 8),
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

        const SizedBox(width: 12),

        // Delete button
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _confirmDeleteReport(report, viewModel),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade400,
            tooltip: 'Supprimer',
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final filterData = _filterOptions[_selectedFilter]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                filterData['icon'],
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
      ),
    );
  }

  Stream<List<TechnicalVisitReport>> _getStreamForFilter(String filter) {
    try {
      final viewModel = Provider.of<AdminViewModel>(context, listen: false);

      switch (filter) {
        case 'submitted':
          return viewModel.getSubmittedReportsStream();
        case 'reviewed':
          return viewModel.getReviewedReportsStream();
        case 'approved':
          return viewModel.getApprovedReportsStream();
        case 'draft':
          return viewModel.getAllReportsStream().map(
            (reports) => reports.where((r) => r.status == 'draft').toList(),
          );
        case 'all':
        default:
          return viewModel.getAllReportsStream();
      }
    } catch (e) {
      // If AdminViewModel is not available, return empty stream
      debugPrint('AdminViewModel not found: $e');
      return Stream.value(<TechnicalVisitReport>[]);
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
    NotificationUtils.showInfo(
      context,
      'Fonctionnalité de modification des brouillons en cours de développement',
    );
  }
}
