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

class _AppSidebarState extends State<AppSidebar> with TickerProviderStateMixin {
  UserModel? _userModel;
  bool _isLoading = true;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _itemController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _itemFadeAnimation;

  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _itemController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _itemFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _itemController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideController.forward();
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _itemController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _itemController.dispose();
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

  bool get isAdmin => widget.userRole == 'admin';

  LinearGradient get _roleGradient =>
      isAdmin
          ? LinearGradient(
            colors: [Colors.indigo.shade600, Colors.purple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
          : LinearGradient(
            colors: [Colors.blue.shade600, Colors.cyan.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

  Color get _roleColor =>
      isAdmin ? Colors.indigo.shade600 : Colors.blue.shade600;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    final String userEmail = _userModel?.email ?? user?.email ?? '';
    final String userName = _userModel?.name ?? 'Utilisateur';
    final String userRoleText = isAdmin ? 'Administrateur' : 'Technicien';

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernHeader(userName, userEmail, userRoleText),
                Expanded(
                  child: FadeTransition(
                    opacity: _itemFadeAnimation,
                    child: _buildMenuContent(),
                  ),
                ),
                FadeTransition(
                  opacity: _itemFadeAnimation,
                  child: _buildModernFooter(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(
    String userName,
    String userEmail,
    String userRoleText,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        gradient: _roleGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: widget.onClose,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // User avatar and info
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                children: [
                  // Avatar with glassmorphism effect
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
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
                                : null,
                        child:
                            _userModel?.profilePictureUrl == null
                                ? Icon(
                                  Icons.person,
                                  size: 36,
                                  color: _roleColor,
                                )
                                : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User name with animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Text(
                            userName.length > 22
                                ? '${userName.substring(0, 22)}...'
                                : userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // User email
                  Text(
                    userEmail.length > 28
                        ? '${userEmail.substring(0, 28)}...'
                        : userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Role badge with modern design
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.engineering,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userRoleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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

  Widget _buildMenuContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuSection('Navigation', [
            _MenuItemData(
              icon: Icons.dashboard_rounded,
              title: 'Tableau de bord',
              action: () => _navigateToScreen(context, 'dashboard'),
              isHighlighted: true,
            ),
            _MenuItemData(
              icon: Icons.assignment_rounded,
              title: 'Rapports',
              action: () => _navigateToScreen(context, 'reports'),
            ),
          ]),

          if (isAdmin) ...[
            const SizedBox(height: 8),
            _buildMenuSection('Administration', [
              _MenuItemData(
                icon: Icons.people_rounded,
                title: 'Gestion des utilisateurs',
                action: () => _navigateToScreen(context, 'users'),
              ),
              _MenuItemData(
                icon: Icons.analytics_rounded,
                title: 'Statistiques',
                action: () => _navigateToScreen(context, 'stats'),
              ),
            ]),
          ],

          const SizedBox(height: 8),
          _buildMenuSection('Compte', [
            _MenuItemData(
              icon: Icons.person_rounded,
              title: 'Profil',
              action: () => _navigateToScreen(context, 'profile'),
            ),
            _MenuItemData(
              icon: Icons.settings_rounded,
              title: 'Paramètres',
              action: () => _navigateToScreen(context, 'settings'),
            ),
          ]),

          const SizedBox(height: 24),

          // Logout section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildModernLogoutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: _buildModernMenuItem(item),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildModernMenuItem(_MenuItemData item) {
    final isSelected = _selectedItem == item.title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedItem = item.title;
            });
            Future.delayed(const Duration(milliseconds: 150), () {
              item.action();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? _roleColor.withOpacity(0.1)
                      : (item.isHighlighted
                          ? _roleColor.withOpacity(0.05)
                          : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected
                        ? _roleColor.withOpacity(0.3)
                        : (item.isHighlighted
                            ? _roleColor.withOpacity(0.1)
                            : Colors.transparent),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon container with modern design
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? _roleColor.withOpacity(0.15)
                            : (item.isHighlighted
                                ? _roleColor.withOpacity(0.1)
                                : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color:
                        isSelected
                            ? _roleColor
                            : (item.isHighlighted
                                ? _roleColor
                                : Colors.grey.shade600),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected
                              ? FontWeight.w600
                              : (item.isHighlighted
                                  ? FontWeight.w600
                                  : FontWeight.w500),
                      color:
                          isSelected
                              ? _roleColor
                              : (item.isHighlighted
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade700),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Arrow indicator for highlighted items
                if (item.isHighlighted || isSelected)
                  AnimatedRotation(
                    turns: isSelected ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _roleColor.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _logout(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: _roleGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kony Solutions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Version 1.1.0',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String screen) {
    Navigator.pop(context);

    if (screen == 'dashboard') {
      if (isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/technician');
      }
      return;
    }

    if (screen == 'users' && isAdmin) {
      Navigator.pushNamed(context, '/user-management');
      return;
    }

    if (screen == 'stats' && isAdmin) {
      Navigator.pushNamed(context, '/statistics');
      return;
    }

    if (screen == 'reports') {
      if (isAdmin) {
        Navigator.pushNamed(context, '/admin-reports');
      } else {
        Navigator.pushNamed(context, '/report-list');
      }
      return;
    }

    if (screen == 'profile') {
      Navigator.pushNamed(context, '/profile');
      return;
    }

    _showFeatureDialog(context, 'Cette fonctionnalité');
  }

  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('En développement', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text('$feature est en cours de développement.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.exit_to_app_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Déconnexion'),
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Déconnexion'),
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

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback action;
  final bool isHighlighted;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.action,
    this.isHighlighted = false,
  });
}
