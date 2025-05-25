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

  // Notification state
  int _submittedCount = 0;
  int _reviewedCount = 0;
  int _approvedCount = 0;
  int _totalReports = 0;
  int _newSubmittedCount = 0;
  DateTime? _lastViewedSubmittedTime;

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
    NotificationService.saveLastOpenTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      NotificationService.saveLastOpenTime();
    } else if (state == AppLifecycleState.resumed) {
      _loadNotificationData();
      _loadReportCounts();
    }
  }

  Future<void> _loadNotificationData() async {
    _lastViewedSubmittedTime =
        await NotificationService.getLastViewedSubmittedTime();
    if (_lastViewedSubmittedTime == null) {
      await NotificationService.saveLastViewedSubmittedTime();
      _lastViewedSubmittedTime = DateTime.now();
    }
    setState(() {});
  }

  Future<void> _loadReportCounts() async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    viewModel.getSubmittedReportsStream().listen((reports) {
      if (mounted) {
        setState(() {
          _submittedCount = reports.length;
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

    viewModel.getAllReportsStream().listen((reports) {
      if (mounted) {
        setState(() {
          _totalReports = reports.length;
        });
      }
    });
  }

  void _navigateToUserManagement() {
    Navigator.pushNamed(context, AppRoutes.userManagement);
  }

  void _navigateToStatistics() {
    Navigator.pushNamed(context, AppRoutes.statistics);
  }

  void _showReportsList(String filter) {
    Navigator.pushNamed(
      context,
      '/admin-reports',
      arguments: {'filter': filter},
    );
  }

  void _markSubmittedNotificationsAsRead() async {
    await NotificationService.saveLastViewedSubmittedTime();
    setState(() {
      _newSubmittedCount = 0;
      _lastViewedSubmittedTime = DateTime.now();
    });
    NotificationUtils.showSuccess(context, 'Notifications marquées comme lues');
  }

  Widget _buildNotificationDropdown(AdminViewModel viewModel) {
    return StreamBuilder<List<TechnicalVisitReport>>(
      stream: viewModel.getSubmittedReportsStream(),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        final newReports =
            reports.where((report) {
              if (_lastViewedSubmittedTime == null) return false;
              final reportTime = report.submittedAt ?? report.createdAt;
              return reportTime.isAfter(_lastViewedSubmittedTime!);
            }).toList();

        return PopupMenuButton<String>(
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(
            minWidth: 320,
            maxWidth: 350,
            maxHeight: 400,
          ),
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
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: null,
                  tooltip: 'Notifications',
                ),
                if (newReports.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${newReports.length}',
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
          itemBuilder: (context) {
            if (newReports.isEmpty) {
              return [
                const PopupMenuItem<String>(
                  enabled: false,
                  child: _EmptyNotificationItem(),
                ),
              ];
            }

            final items = <PopupMenuItem<String>>[];

            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: _NotificationHeader(count: newReports.length),
              ),
            );

            for (int i = 0; i < newReports.length && i < 5; i++) {
              items.add(
                PopupMenuItem<String>(
                  value: newReports[i].id,
                  child: _NotificationItem(report: newReports[i]),
                ),
              );
            }

            if (newReports.length > 5) {
              items.add(
                PopupMenuItem<String>(
                  value: 'show_all',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Voir ${newReports.length - 5} de plus...',
                        style: TextStyle(
                          color: Colors.indigo.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            items.add(
              PopupMenuItem<String>(
                value: 'mark_read',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.done_all,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Marquer comme lu',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return items;
          },
          onSelected: (value) {
            if (value == 'mark_read') {
              _markSubmittedNotificationsAsRead();
            } else if (value == 'show_all') {
              _showReportsList('submitted');
            } else
              _showReportsList('submitted');
          },
        );
      },
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
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade800,
        centerTitle: true,
        actions: [
          Consumer<AdminViewModel>(
            builder: (context, viewModel, child) {
              return _buildNotificationDropdown(viewModel);
            },
          ),
        ],
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
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  if (_newSubmittedCount > 0) ...[
                    _buildNotificationBanner(),
                    const SizedBox(height: 24),
                  ],
                  _buildQuickStatsGrid(),
                  const SizedBox(height: 32),
                  _buildReportsManagementSection(),
                  const SizedBox(height: 32),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                  _buildSystemStatusSection(),
                  const SizedBox(height: 20),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                    colors: [Colors.indigo.shade500, Colors.indigo.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Administration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.indigo.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gérez les utilisateurs, supervisez les rapports et analysez les performances du système',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo.shade700,
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

  Widget _buildNotificationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notification_important_outlined,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouveaux rapports soumis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      '$_newSubmittedCount rapport${_newSubmittedCount > 1 ? 's' : ''} en attente de révision',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReportsList('submitted'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Examiner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _markSubmittedNotificationsAsRead,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Marquer lu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
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
                title: 'Total',
                subtitle: 'Rapports',
                value: _totalReports.toString(),
                icon: Icons.assessment_outlined,
                color: Colors.indigo,
                onTap: () => _showReportsList('all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'En attente',
                subtitle: 'À examiner',
                value: _submittedCount.toString(),
                icon: Icons.pending_actions_outlined,
                color: Colors.orange,
                onTap: () => _showReportsList('submitted'),
                hasNotification: _newSubmittedCount > 0,
                notificationCount: _newSubmittedCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Examinés',
                subtitle: 'Révisés',
                value: _reviewedCount.toString(),
                icon: Icons.fact_check_outlined,
                color: Colors.blue,
                onTap: () => _showReportsList('reviewed'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Approuvés',
                subtitle: 'Finalisés',
                value: _approvedCount.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
                onTap: () => _showReportsList('approved'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
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
        padding: const EdgeInsets.all(20),
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
          border:
              hasNotification
                  ? Border.all(color: color.withOpacity(0.3), width: 1)
                  : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (hasNotification && notificationCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
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
          'Gestion des rapports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Accès rapide aux différents statuts de rapports',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildReportFilterButton(
                      title: 'Soumis',
                      description: 'Attendent révision',
                      icon: Icons.assignment_turned_in_outlined,
                      color: Colors.orange,
                      onTap: () => _showReportsList('submitted'),
                      hasNotification: _newSubmittedCount > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReportFilterButton(
                      title: 'Examinés',
                      description: 'Prêts approbation',
                      icon: Icons.fact_check_outlined,
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
                    child: _buildReportFilterButton(
                      title: 'Approuvés',
                      description: 'Validation finale',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onTap: () => _showReportsList('approved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReportFilterButton(
                      title: 'Tous',
                      description: 'Vue complète',
                      icon: Icons.view_list_outlined,
                      color: Colors.indigo,
                      onTap: () => _showReportsList('all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportFilterButton({
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
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                hasNotification
                    ? color.withOpacity(0.3)
                    : color.withOpacity(0.1),
            width: hasNotification ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
            if (hasNotification)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outils d\'administration',
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
              child: _buildActionCard(
                title: 'Utilisateurs',
                description: 'Gérer les comptes et permissions',
                icon: Icons.people_outline,
                color: Colors.teal,
                onTap: _navigateToUserManagement,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Statistiques',
                description: 'Analyses et tableaux de bord',
                icon: Icons.analytics_outlined,
                color: Colors.purple,
                onTap: _navigateToStatistics,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Accéder',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 12, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'État du système',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Services',
                  'Opérationnels',
                  Colors.green,
                  Icons.cloud_done_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  'Base de données',
                  'Connectée',
                  Colors.green,
                  Icons.storage_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Sauvegardes',
                  'À jour',
                  Colors.green,
                  Icons.backup_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  'Sécurité',
                  'Active',
                  Colors.green,
                  Icons.security_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String status,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            'Version 1.1.0',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // Report management methods
  Future<void> _viewReportPdf(TechnicalVisitReport report) async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfFile = await viewModel.generateReportPdf(report.id);

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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                      foregroundColor: Colors.white,
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

// Notification dropdown helper widgets
class _NotificationHeader extends StatelessWidget {
  final int count;

  const _NotificationHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
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
              color: Colors.indigo.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 16,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelles notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.indigo.shade800,
                  ),
                ),
                Text(
                  '$count nouveau${count > 1 ? 'x' : ''} rapport${count > 1 ? 's' : ''} soumis',
                  style: TextStyle(fontSize: 12, color: Colors.indigo.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final TechnicalVisitReport report;

  const _NotificationItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(report.submittedAt ?? report.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              size: 16,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: report.technicianName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' a soumis un rapport'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (report.clientName.isNotEmpty)
                  Text(
                    'Client: ${report.clientName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return 'Il y a ${(difference.inDays / 7).floor()} sem';
    }
  }
}

class _EmptyNotificationItem extends StatelessWidget {
  const _EmptyNotificationItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune nouvelle notification',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vous êtes à jour !',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
