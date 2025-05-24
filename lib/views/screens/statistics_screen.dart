// lib/views/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/statistics_view_model.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/statistics/report_trend_chart.dart';
import '../widgets/statistics/component_distribution_chart.dart';
import '../widgets/statistics/technician_productivity_chart.dart';
import '../widgets/statistics/location_distribution_chart.dart';
import '../widgets/statistics/duration_statistics_chart.dart';
import '../widgets/statistics/stats_summary_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFirstLoad = true;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isFirstLoad) {
      _isFirstLoad = false;
      // Load statistics when screen is first shown
      Future.microtask(() {
        Provider.of<StatisticsViewModel>(
          context,
          listen: false,
        ).loadAllStatistics();
      });
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Statistiques & Analyses',
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
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<StatisticsViewModel>(
                context,
                listen: false,
              ).loadAllStatistics();
            },
            tooltip: 'Actualiser les données',
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Consumer<StatisticsViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des statistiques...'),
                      ],
                    ),
                  );
                }

                if (viewModel.errorMessage != null) {
                  return _buildErrorState(viewModel);
                }

                // Check if there are any reports
                if (viewModel.reports.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildStatisticsContent(viewModel);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(StatisticsViewModel viewModel) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
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
              viewModel.errorMessage!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => viewModel.loadAllStatistics(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucune donnée disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aucun rapport trouvé pour générer des statistiques.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(StatisticsViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          _buildHeaderSection(viewModel),

          // Summary Cards Section
          _buildSummarySection(viewModel),

          // Charts Section
          _buildChartsSection(viewModel),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(StatisticsViewModel viewModel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de Bord Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Analyses détaillées des performances et tendances',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick stats in header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        'Rapports Total',
                        viewModel.totalReports.toString(),
                        Icons.assignment,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Composants',
                        viewModel.totalComponents.toString(),
                        Icons.category,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Techniciens',
                        viewModel.technicianProductivity.length.toString(),
                        Icons.people,
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

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummarySection(StatisticsViewModel viewModel) {
    // Calculate summary stats
    final totalReports = viewModel.totalReports;
    final completedReports =
        viewModel.reports.where((r) => r.status != 'draft').length;
    final completionRate =
        totalReports > 0
            ? (completedReports / totalReports * 100).toStringAsFixed(1)
            : '0';

    final averageComponents =
        viewModel.totalComponents / (totalReports > 0 ? totalReports : 1);

    final avgHours = viewModel.averageCompletionTime;
    final avgDays = avgHours / 24;

    // Format with 1 decimal place
    final formatter = NumberFormat('#,##0.0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indicateurs Clés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSummaryCard(
                'Rapports Terminés',
                '$completionRate%',
                Icons.check_circle_outline,
                Colors.green,
                subtitle: '$completedReports sur $totalReports',
              ),
              _buildSummaryCard(
                'Composants par Rapport',
                formatter.format(averageComponents),
                Icons.category,
                Colors.blue,
                subtitle: 'moyenne générale',
              ),
              _buildSummaryCard(
                'Durée de Traitement',
                '${formatter.format(avgDays)} jours',
                Icons.timer,
                Colors.purple,
                subtitle: 'temps moyen',
              ),
              _buildSummaryCard(
                'Estimation Projet',
                '${formatter.format(viewModel.durationStatistics['average'] ?? 0)} jours',
                Icons.calendar_today,
                Colors.orange,
                subtitle: 'durée estimée',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(StatisticsViewModel viewModel) {
    return Column(
      children: [
        const SizedBox(height: 32),

        // Section title
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Analyses Détaillées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Report trend chart
        _buildChartCard(
          'Évolution des Rapports',
          Icons.trending_up,
          Colors.blue,
          SizedBox(
            height: 300,
            child: ReportTrendChart(monthlyStats: viewModel.monthlyStats),
          ),
        ),

        const SizedBox(height: 24),

        // Component distribution chart
        _buildChartCard(
          'Répartition des Composants',
          Icons.pie_chart,
          Colors.green,
          SizedBox(
            height: 300,
            child: ComponentDistributionChart(
              distribution: viewModel.componentDistribution,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Technician productivity chart
        _buildChartCard(
          'Productivité des Techniciens',
          Icons.person,
          Colors.purple,
          SizedBox(
            height: 300,
            child: TechnicianProductivityChart(
              productivity: viewModel.technicianProductivity,
              getTechnicianName: viewModel.getTechnicianName,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Location distribution chart
        _buildChartCard(
          'Répartition Géographique',
          Icons.location_on,
          Colors.orange,
          SizedBox(
            height: 300,
            child: LocationDistributionChart(
              distribution: viewModel.locationDistribution,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Duration statistics chart
        _buildChartCard(
          'Statistiques des Durées',
          Icons.hourglass_bottom,
          Colors.teal,
          SizedBox(
            height: 300,
            child: DurationStatisticsChart(
              statistics: viewModel.durationStatistics,
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildChartCard(
    String title,
    IconData icon,
    Color color,
    Widget chart,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          // Chart header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Chart content
          Padding(padding: const EdgeInsets.all(16), child: chart),
        ],
      ),
    );
  }
}
