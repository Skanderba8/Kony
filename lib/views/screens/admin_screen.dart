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
import '../../services/notification_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Report filter state
  final String _selectedReportFilter = 'all';
  final List<String> _reportFilters = [
    'all',
    'submitted',
    'reviewed',
    'approved',
  ];

  // Notification state
  int _submittedCount = 0;
  int _reviewedCount = 0;
  int _approvedCount = 0;
  int _newSubmittedCount = 0;
  DateTime? _lastViewedSubmittedTime;
  final bool _hasCheckedNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    _loadNotificationData();
    _loadReportCounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    // Save the current time when leaving the admin screen
    NotificationService.saveLastOpenTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background, save the time
      NotificationService.saveLastOpenTime();
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground, refresh notifications
      _loadNotificationData();
      _loadReportCounts();
    }
  }

  // Load notification data from SharedPreferences
  Future<void> _loadNotificationData() async {
    _lastViewedSubmittedTime =
        await NotificationService.getLastViewedSubmittedTime();
    if (_lastViewedSubmittedTime == null) {
      // If no previous data, set it to now (first time user)
      await NotificationService.saveLastViewedSubmittedTime();
      _lastViewedSubmittedTime = DateTime.now();
    }
    setState(() {});
  }

  Future<void> _loadReportCounts() async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    // Listen to submitted reports stream and calculate new reports
    viewModel.getSubmittedReportsStream().listen((reports) {
      if (mounted) {
        final int oldSubmittedCount = _submittedCount;

        setState(() {
          _submittedCount = reports.length;

          // Calculate new submitted reports since last viewed time
          if (_lastViewedSubmittedTime != null) {
            _newSubmittedCount =
                reports.where((report) {
                  final DateTime reportTime =
                      report.submittedAt ?? report.createdAt;
                  return reportTime.isAfter(_lastViewedSubmittedTime!);
                }).length;
          } else {
            _newSubmittedCount = 0;
          }
        });

        // Debug logging
        debugPrint('Submitted reports count: $_submittedCount');
        debugPrint('New submitted reports: $_newSubmittedCount');
        debugPrint('Last viewed time: $_lastViewedSubmittedTime');
      }
    });

    viewModel.getReviewedReportsStream().listen((reports) {
      if (mounted) {
        setState(() {
          _reviewedCount = reports.length;
        });
      }
    });

    viewModel.getApprovedReportsStream().listen((reports) {
      if (mounted) {
        setState(() {
          _approvedCount = reports.length;
        });
      }
    });
  }

  // Navigation methods
  void _navigateToUserManagement() {
    Navigator.pushNamed(context, AppRoutes.userManagement);
  }

  void _navigateToStatistics() {
    Navigator.pushNamed(context, AppRoutes.statistics);
  }

  // Handle logout
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

  // Show reports for selected filter
  void _showReportsList(String filter) {
    // Navigate to the dedicated reports screen with the selected filter
    Navigator.pushNamed(
      context,
      '/admin-reports',
      arguments: {'filter': filter},
    );
  }

  void _markSubmittedNotificationsAsRead() async {
    // Save current time as last viewed submitted time
    await NotificationService.saveLastViewedSubmittedTime();

    setState(() {
      _newSubmittedCount = 0;
      _lastViewedSubmittedTime = DateTime.now();
    });

    NotificationUtils.showSuccess(context, 'Notifications marquées comme lues');
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('Notifications'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_newSubmittedCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_newSubmittedCount nouveau${_newSubmittedCount > 1 ? 'x' : ''} rapport${_newSubmittedCount > 1 ? 's' : ''} soumis',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Aucune nouvelle notification'),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (_newSubmittedCount > 0)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReportsList('submitted');
                  },
                  child: const Text('Voir Rapports'),
                ),
            ],
          ),
    );
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
          'Administration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(),

                  const SizedBox(height: 24),

                  // Notifications Section (if there are new reports)
                  if (_newSubmittedCount > 0) ...[
                    _buildNotificationsSection(),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 8),

                  // Quick Stats Section
                  _buildQuickStatsSection(),

                  const SizedBox(height: 32),

                  // Reports Management Section
                  _buildReportsManagementSection(),

                  const SizedBox(height: 32),

                  // Administration Tools Section
                  _buildAdministrationToolsSection(),

                  const SizedBox(height: 32),

                  // System Information Section
                  _buildSystemInformationSection(),

                  const SizedBox(height: 20),

                  // Footer
                  _buildFooterSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Administrateur',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Admin message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.yellow, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gérez les utilisateurs, supervisez les rapports et analysez les performances',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notification_important,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouveaux Rapports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      '$_newSubmittedCount rapport${_newSubmittedCount > 1 ? 's' : ''} soumis depuis votre dernière consultation',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _newSubmittedCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReportsList('submitted'),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Voir les Rapports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _markSubmittedNotificationsAsRead,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Marquer Lu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu Rapide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Rapports\nSoumis',
                    value: _submittedCount.toString(),
                    icon: Icons.assignment_turned_in,
                    color: Colors.orange,
                    onTap: () => _showReportsList('submitted'),
                    hasNotification: _newSubmittedCount > 0,
                    notificationCount: _newSubmittedCount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Rapports\nExaminés',
                    value: _reviewedCount.toString(),
                    icon: Icons.fact_check,
                    color: Colors.blue,
                    onTap: () => _showReportsList('reviewed'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Rapports\nApprouvés',
                    value: _approvedCount.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: () => _showReportsList('approved'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                hasNotification ? color.withOpacity(0.5) : Colors.grey.shade100,
            width: hasNotification ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(hasNotification ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            // Notification badge
            if (hasNotification && notificationCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    notificationCount > 99
                        ? '99+'
                        : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion des Rapports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Consultez et gérez tous les rapports techniques',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // Reports filter buttons
        _buildReportsFilterCard(),

        const SizedBox(height: 16),

        // All Reports button
        _buildAllReportsCard(),
      ],
    );
  }

  Widget _buildReportsFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtrer par Statut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cliquez sur un statut pour voir les rapports',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filter buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      title: 'Soumis',
                      description: 'Rapports en attente de révision',
                      icon: Icons.assignment_turned_in,
                      color: Colors.orange,
                      onTap: () => _showReportsList('submitted'),
                      hasNotification: _newSubmittedCount > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterButton(
                      title: 'Examinés',
                      description: 'Rapports révisés et validés',
                      icon: Icons.fact_check,
                      color: Colors.blue,
                      onTap: () => _showReportsList('reviewed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      title: 'Approuvés',
                      description: 'Rapports finalisés et approuvés',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onTap: () => _showReportsList('approved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterButton(
                      title: 'Tous',
                      description: 'Afficher tous les rapports',
                      icon: Icons.list_alt,
                      color: Colors.purple,
                      onTap: () => _showReportsList('all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                hasNotification
                    ? color.withOpacity(0.6)
                    : color.withOpacity(0.3),
            width: hasNotification ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
            if (hasNotification)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllReportsCard() {
    return GestureDetector(
      onTap:
          () => _showReportsList(
            'all',
          ), // This will now navigate to the dedicated screen
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.view_list, color: Colors.white, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voir Tous les Rapports',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Accédez à la liste complète de tous les rapports techniques',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAdministrationToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outils d\'Administration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildAdminToolCard(
                title: 'Gestion des\nUtilisateurs',
                icon: Icons.people,
                color: Colors.teal,
                onTap: _navigateToUserManagement,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAdminToolCard(
                title: 'Statistiques\net Analyses',
                icon: Icons.analytics,
                color: Colors.indigo,
                onTap: _navigateToStatistics,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminToolCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Accéder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInformationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Information Système',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Système fonctionnel - Tous les services sont opérationnels. '
            'Utilisez les outils ci-dessus pour gérer les utilisateurs et superviser les rapports techniques.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Kony - Administration Système',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.3',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // Bottom sheet for reports list
  Widget _buildReportsBottomSheet(String filter) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        _getFilterTitle(filter),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Refresh action
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),

              // Reports list
              Expanded(child: _buildReportsList(filter, scrollController)),
            ],
          ),
        );
      },
    );
  }

  String _getFilterTitle(String filter) {
    switch (filter) {
      case 'submitted':
        return 'Rapports Soumis';
      case 'reviewed':
        return 'Rapports Examinés';
      case 'approved':
        return 'Rapports Approuvés';
      case 'all':
        return 'Tous les Rapports';
      default:
        return 'Rapports';
    }
  }

  Widget _buildReportsList(String filter, ScrollController scrollController) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        Stream<List<TechnicalVisitReport>> stream;

        switch (filter) {
          case 'submitted':
            stream = viewModel.getSubmittedReportsStream();
            break;
          case 'reviewed':
            stream = viewModel.getReviewedReportsStream();
            break;
          case 'approved':
            stream = viewModel.getApprovedReportsStream();
            break;
          case 'all':
          default:
            stream = viewModel.getAllReportsStream();
            break;
        }

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
                    Text('Erreur: ${snapshot.error}'),
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
                      'Aucun rapport ${_getFilterDescription(filter)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportListItem(report);
              },
            );
          },
        );
      },
    );
  }

  String _getFilterDescription(String filter) {
    switch (filter) {
      case 'submitted':
        return 'soumis';
      case 'reviewed':
        return 'examiné';
      case 'approved':
        return 'approuvé';
      case 'all':
        return 'disponible';
      default:
        return '';
    }
  }

  Widget _buildReportListItem(TechnicalVisitReport report) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (report.status) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.clientName.isNotEmpty
                        ? report.clientName
                        : 'Rapport sans nom',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location and technician info
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location.isNotEmpty
                        ? report.location
                        : 'Lieu non spécifié',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Par: ${report.technicianName}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Soumis: ${dateFormat.format(report.submittedAt ?? report.createdAt)} à ${timeFormat.format(report.submittedAt ?? report.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Row(
                  children: [
                    // PDF Button
                    IconButton(
                      onPressed: () => _viewReportPdf(report),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      color: Colors.red.shade600,
                      tooltip: 'Voir PDF',
                    ),

                    // Status update buttons
                    if (report.status == 'submitted')
                      IconButton(
                        onPressed:
                            () => _updateReportStatus(report, 'reviewed'),
                        icon: const Icon(Icons.fact_check, size: 18),
                        color: Colors.blue,
                        tooltip: 'Marquer comme examiné',
                      ),

                    if (report.status == 'reviewed')
                      IconButton(
                        onPressed:
                            () => _updateReportStatus(report, 'approved'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        color: Colors.green,
                        tooltip: 'Approuver',
                      ),

                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDeleteReport(report),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red.shade400,
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Report management methods (keeping existing functionality)
  Future<void> _viewReportPdf(TechnicalVisitReport report) async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

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
          try {
            final result = await OpenFile.open(pdfFile.path);
            if (result.type != 'done') {
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
      // Close loading dialog if still showing
      if (mounted) Navigator.of(context).pop();
      debugPrint('Error generating PDF: $e');
      NotificationUtils.showError(
        context,
        'Erreur lors de la génération du PDF: $e',
      );
    }
  }

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
}
