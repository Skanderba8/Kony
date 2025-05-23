// lib/views/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_management_service.dart';
import '../../models/user_model.dart';

class AppSidebar extends StatefulWidget {
  final String? userRole;
  final VoidCallback onClose;

  const AppSidebar({super.key, required this.userRole, required this.onClose});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  UserModel? _userModel;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadUserData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userManagementService = Provider.of<UserManagementService>(
      context,
      listen: false,
    );

    final user = authService.currentUser;
    if (user != null) {
      try {
        final userModel = await userManagementService.getUserByAuthUid(
          user.uid,
        );
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    // Fallback to Auth user email if Firestore data not available
    final String userEmail = _userModel?.email ?? user?.email ?? '';
    final String userName = _userModel?.name ?? 'Utilisateur';
    final String userRoleText =
        widget.userRole == 'admin' ? 'Administrateur' : 'Technicien';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Header Section
                  _buildHeaderSection(userName, userEmail, userRoleText),

                  // Menu Items
                  Expanded(child: _buildMenuSection()),

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

  Widget _buildHeaderSection(
    String userName,
    String userEmail,
    String userRoleText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              widget.userRole == 'admin'
                  ? [Colors.indigo.shade600, Colors.indigo.shade500]
                  : [Colors.blue.shade600, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.userRole == 'admin' ? Colors.indigo : Colors.blue)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: widget.onClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // User avatar and info
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage:
                          _userModel?.profilePictureUrl != null
                              ? NetworkImage(_userModel!.profilePictureUrl!)
                                  as ImageProvider
                              : null,
                      child:
                          _userModel?.profilePictureUrl == null
                              ? Icon(
                                Icons.person,
                                size: 40,
                                color:
                                    widget.userRole == 'admin'
                                        ? Colors.indigo.shade600
                                        : Colors.blue.shade600,
                              )
                              : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User name
                  Text(
                    userName.split(' ').first, // Show first name only
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 4),

                  // User email
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 12),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.userRole == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.engineering,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          userRoleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Navigation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildMenuItem(
            icon: Icons.dashboard_outlined,
            title: 'Tableau de bord',
            onTap: () => _navigateToScreen(context, 'dashboard'),
            isHighlighted: true,
          ),

          _buildMenuItem(
            icon: Icons.assignment_outlined,
            title: 'Rapports',
            onTap: () => _navigateToScreen(context, 'reports'),
          ),

          if (widget.userRole == 'admin') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Administration',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            _buildMenuItem(
              icon: Icons.people_outline,
              title: 'Gestion des utilisateurs',
              onTap: () => _navigateToScreen(context, 'users'),
            ),

            _buildMenuItem(
              icon: Icons.analytics_outlined,
              title: 'Statistiques',
              onTap: () => _navigateToScreen(context, 'stats'),
            ),
          ],

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Compte',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Profil',
            onTap: () => _navigateToScreen(context, 'profile'),
          ),

          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Paramètres',
            onTap: () => _navigateToScreen(context, 'settings'),
          ),

          const Spacer(),

          // Logout section
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: _buildMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              onTap: () => _logout(context),
              textColor: Colors.red.shade700,
              iconColor: Colors.red.shade600,
              showBackground: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isHighlighted = false,
    Color? textColor,
    Color? iconColor,
    bool showBackground = true,
  }) {
    final Color defaultIconColor =
        widget.userRole == 'admin'
            ? Colors.indigo.shade600
            : Colors.blue.shade600;

    final Color defaultTextColor = Colors.grey.shade800;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  showBackground && isHighlighted
                      ? (widget.userRole == 'admin'
                          ? Colors.indigo.shade50
                          : Colors.blue.shade50)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isHighlighted && showBackground
                      ? Border.all(
                        color:
                            widget.userRole == 'admin'
                                ? Colors.indigo.shade200
                                : Colors.blue.shade200,
                        width: 1,
                      )
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        showBackground
                            ? (iconColor ?? defaultIconColor).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? defaultIconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isHighlighted ? FontWeight.w600 : FontWeight.w500,
                      color: textColor ?? defaultTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isHighlighted)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color:
                        widget.userRole == 'admin'
                            ? Colors.indigo.shade400
                            : Colors.blue.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kony Solutions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Version 1.0.3',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String screen) {
    Navigator.pop(context); // Close the drawer

    if (screen == 'dashboard') {
      // Navigate to respective home screen based on role
      if (widget.userRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/technician');
      }
      return;
    }

    if (screen == 'users' && widget.userRole == 'admin') {
      Navigator.pushNamed(context, '/user-management');
      return;
    }

    if (screen == 'stats' && widget.userRole == 'admin') {
      Navigator.pushNamed(context, '/statistics');
      return;
    }

    if (screen == 'reports') {
      // For technicians: go to the list of reports
      if (widget.userRole == 'technician') {
        Navigator.pushNamed(context, '/report-list');
      } else {
        // For admin: show a popup (feature under development)
        _showFeatureDialog(context, 'Rapports');
      }
      return;
    }

    if (screen == 'profile') {
      // Navigate to profile screen
      Navigator.pushNamed(context, '/profile');
      return;
    }

    // For other screens show "En cours de développement"
    _showFeatureDialog(context, 'Cette fonctionnalité');
  }

  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.construction, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('En développement'),
            ],
          ),
          content: Text('$feature est en cours de développement.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Compris',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Déconnexion'),
            ],
          ),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        print('Error signing out: $e');
      }
    }
  }
}
