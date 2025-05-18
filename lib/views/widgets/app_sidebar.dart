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

class _AppSidebarState extends State<AppSidebar> {
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      width: MediaQuery.of(context).size.width * 0.85, // Responsive width
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              color: Colors.blue.shade700,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),

                  // User avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _userModel?.profilePictureUrl != null
                            ? NetworkImage(_userModel!.profilePictureUrl!)
                                as ImageProvider
                            : null,
                    child:
                        _userModel?.profilePictureUrl == null
                            ? Icon(Icons.person, size: 60, color: Colors.blue)
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // User info with loading state
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              userRoleText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Tableau de bord',
                    onTap: () => _navigateToScreen(context, 'dashboard'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.assignment,
                    title: 'Rapports',
                    onTap: () => _navigateToScreen(context, 'reports'),
                  ),
                  if (widget.userRole == 'admin') ...[
                    _buildMenuItem(
                      context,
                      icon: Icons.people,
                      title: 'Gestion des utilisateurs',
                      onTap: () => _navigateToScreen(context, 'users'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.bar_chart,
                      title: 'Statistiques',
                      onTap: () => _navigateToScreen(context, 'stats'),
                    ),
                  ],
                  _buildMenuItem(
                    context,
                    icon: Icons.person,
                    title: 'Profil',
                    onTap: () => _navigateToScreen(context, 'profile'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Paramètres',
                    onTap: () => _navigateToScreen(context, 'settings'),
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Kony v1.0.3',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }

  // In lib/views/widgets/app_sidebar.dart, update the _navigateToScreen method
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Information'),
              content: const Text(
                'Cette section est en cours de développement.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    if (screen == 'profile') {
      // Navigate to profile screen
      Navigator.pushNamed(context, '/profile');
      return;
    }

    // For other screens show "En cours de développement"
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Information'),
          content: const Text('Cette section est en cours de développement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
