// lib/views/screens/technician_screen.dart
import 'package:flutter/material.dart';
import 'package:kony/models/user_model.dart';
import 'package:kony/services/auth_service.dart';
import 'package:kony/services/user_management_service.dart';
import 'package:kony/views/widgets/app_sidebar.dart';
import 'package:provider/provider.dart';
import '../../view_models/technician_view_model.dart';
import 'report_list_screen.dart';
import '../../utils/notification_utils.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

  @override
  _TechnicianScreenState createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIncompleteProfile();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  Future<void> _checkIncompleteProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      final userManagementService = Provider.of<UserManagementService>(
        context,
        listen: false,
      );
      final userModel = await userManagementService.getUserByAuthUid(user.uid);

      if ((userModel?.phoneNumber == null || userModel!.phoneNumber!.isEmpty) &&
          mounted) {
        NotificationUtils.showInfo(
          context,
          'Veuillez compléter votre profil en ajoutant votre numéro de téléphone.',
          duration: const Duration(seconds: 5),
        );
      }
    }
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
          "Erreur lors de la déconnexion: ${viewModel.errorMessage ?? e}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicianViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: AppSidebar(
            userRole: 'technician',
            onClose: () => _scaffoldKey.currentState?.closeDrawer(),
          ),
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Accueil Technicien',
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
                      // Welcome Section with improved design
                      _buildWelcomeSection(),

                      const SizedBox(height: 32),

                      // Quick Actions Section
                      _buildQuickActionsSection(),

                      const SizedBox(height: 32),

                      // Main Navigation Cards
                      _buildMainNavigationSection(context),

                      const SizedBox(height: 40),

                      // Help Section
                      _buildHelpSection(),

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
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text and User Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<UserModel?>(
                  future: Provider.of<UserManagementService>(
                    context,
                    listen: false,
                  ).getUserByAuthUid(
                    Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).currentUser?.uid ??
                        '',
                  ),
                  builder: (context, snapshot) {
                    String userName = "Technicien";
                    if (snapshot.hasData && snapshot.data != null) {
                      userName = snapshot.data!.name;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bonjour,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName.split(' ').first, // Show first name only
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Welcome message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.yellow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Créez et gérez vos rapports de visite technique en quelques clics',
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

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
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
              child: _buildQuickActionButton(
                icon: Icons.add_circle_outline,
                title: 'Nouveau\nRapport',
                color: Colors.green,
                onTap: () => _navigateToReportList(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.list_alt,
                title: 'Mes\nRapports',
                color: Colors.blue,
                onTap: () => _navigateToReportList(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.person,
                title: 'Mon\nProfil',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildMainNavigationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types de Documentation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez le type de rapport que vous souhaitez créer ou consulter',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // Technical Visit Card
        _buildMainNavigationCard(
          title: 'Rapports de Visite Technique',
          subtitle: 'Documentez vos visites clients et installations',
          description:
              'Créez des rapports détaillés de vos interventions techniques avec photos, mesures et recommandations.',
          icon: Icons.engineering,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToReportList(context),
          features: [
            'Documentation complète',
            'Photos et mesures',
            'Export PDF automatique',
          ],
        ),

        const SizedBox(height: 20),

        // Intervention Card (placeholder)
        _buildMainNavigationCard(
          title: 'Rapports d\'Intervention',
          subtitle: 'Enregistrez vos interventions de maintenance',
          description:
              'Documentez vos actions de maintenance, réparations et mises à jour d\'équipements.',
          icon: Icons.build_circle,
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToInterventions(context),
          features: [
            'Suivi des interventions',
            'Pièces utilisées',
            'Temps d\'intervention',
          ],
          isComingSoon: true,
        ),
      ],
    );
  }

  Widget _buildMainNavigationCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    required List<String> features,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isComingSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Bientôt',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Features
            Column(
              children:
                  features
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color:
                                      isComingSoon
                                          ? Colors.orange
                                          : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(height: 16),

            // Action button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient:
                    isComingSoon
                        ? LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        )
                        : gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isComingSoon ? Icons.schedule : Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComingSoon ? 'Prochainement disponible' : 'Accéder',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cette application vous permet de créer et gérer vos rapports techniques facilement. '
            'Commencez par créer un nouveau rapport de visite technique pour documenter vos interventions.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
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
            'Kony - Solutions Techniques Professionnelles',
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
}
