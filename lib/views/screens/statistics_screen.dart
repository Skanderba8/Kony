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

class _StatisticsScreenState extends State<StatisticsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFirstLoad = true;

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
      appBar: AppBar(
        title: const Text(
          'Statistiques',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
      body: Consumer<StatisticsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement des statistiques',
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
                  ),
                ],
              ),
            );
          }

          // Check if there are any reports
          if (viewModel.reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                _buildSummaryCards(viewModel),

                const SizedBox(height: 24),

                // Report trend chart
                _buildSectionHeader(
                  'Tendances des Rapports',
                  Icons.trending_up,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: ReportTrendChart(monthlyStats: viewModel.monthlyStats),
                ),

                const SizedBox(height: 32),

                // Component distribution chart
                _buildSectionHeader(
                  'Distribution des Composants',
                  Icons.pie_chart,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: ComponentDistributionChart(
                    distribution: viewModel.componentDistribution,
                  ),
                ),

                const SizedBox(height: 32),

                // Technician productivity chart
                _buildSectionHeader(
                  'Productivité des Techniciens',
                  Icons.person,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: TechnicianProductivityChart(
                    productivity: viewModel.technicianProductivity,
                    getTechnicianName: viewModel.getTechnicianName,
                  ),
                ),

                const SizedBox(height: 32),

                // Location distribution chart
                _buildSectionHeader(
                  'Distribution Géographique',
                  Icons.location_on,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LocationDistributionChart(
                    distribution: viewModel.locationDistribution,
                  ),
                ),

                const SizedBox(height: 32),

                // Duration statistics chart
                _buildSectionHeader(
                  'Statistiques des Durées Estimées',
                  Icons.hourglass_bottom,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: DurationStatisticsChart(
                    statistics: viewModel.durationStatistics,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(StatisticsViewModel viewModel) {
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

    // Use screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 3;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio:
          screenWidth < 600
              ? 1.5
              : 1.3, // Adjust aspect ratio for different sizes
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatsSummaryCard(
          title: 'R', // Shorter titles to prevent overflow
          value: totalReports.toString(),
          icon: Icons.assignment,
          color: Colors.blue,
        ),
        StatsSummaryCard(
          title: 'T',
          value: '$completionRate%',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        StatsSummaryCard(
          title: 'C',
          value: formatter.format(averageComponents),
          icon: Icons.category,
          color: Colors.orange,
        ),
        StatsSummaryCard(
          title: 'D',
          value: '${formatter.format(avgDays)} jours',
          subtitle: '(${formatter.format(avgHours)} h)', // Shorter subtitle
          icon: Icons.timer,
          color: Colors.purple,
        ),
        StatsSummaryCard(
          title: 'D',
          value:
              '${formatter.format(viewModel.durationStatistics['average'] ?? 0)} jours',
          icon: Icons.calendar_today,
          color: Colors.teal,
        ),
        StatsSummaryCard(
          title: 'T',
          value: viewModel.technicianProductivity.length.toString(),
          icon: Icons.people,
          color: Colors.indigo,
        ),
      ],
    );
  }
}
