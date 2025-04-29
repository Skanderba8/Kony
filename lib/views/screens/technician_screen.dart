// lib/views/screens/technician_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/technician_view_model.dart';
import 'report_list_screen.dart';
import '../../utils/notification_utils.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

  @override
  _TechnicianScreenState createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen> {
  @override
  void initState() {
    super.initState();
  }

  // Navigate to the technical visit reports list
  void _navigateToReportList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportListScreen()),
    );
  }

  // Navigate to the interventions section (placeholder for now)
  void _navigateToInterventions(BuildContext context) {
    // For now, just show an informational message as this section is under development
    NotificationUtils.showInfo(
      context,
      'La section "Interventions" est en cours de développement.',
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final viewModel = Provider.of<TechnicianViewModel>(context, listen: false);

    try {
      await viewModel.logout();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          "Error logging out: ${viewModel.errorMessage ?? e}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicianViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text(
              'Tableau de Bord',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.blue),
                onPressed: () => _logout(context),
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.handyman,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Technicien Kony',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Choisissez le type de documentation à gérer',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Main options
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Types de documentation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Option 1: Technical Visit Reports
                      _buildOptionCard(
                        title: 'Visite Technique',
                        description:
                            'Créer ou modifier un rapport de visite technique.',
                        icon: Icons.assignment_outlined,
                        color: Colors.green.shade500,
                        onTap: () => _navigateToReportList(context),
                      ),

                      const SizedBox(height: 16),

                      // Option 2: Interventions (Placeholder for now)
                      _buildOptionCard(
                        title: 'Intervention',
                        description:
                            'Enregistrer une intervention standard (à venir).',
                        icon: Icons.build_outlined,
                        color: Colors.orange.shade500,
                        onTap: () => _navigateToInterventions(context),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Version info at bottom
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Kony App v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build option cards
  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
