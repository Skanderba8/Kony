// lib/views/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_management_view_model.dart';
import '../../models/user_model.dart';
import '../../utils/notification_utils.dart';
import '../widgets/app_sidebar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserManagementViewModel>(context, listen: false).loadUsers();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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
          'Gestion des Utilisateurs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<UserManagementViewModel>(
                context,
                listen: false,
              ).loadUsers();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header Section
                _buildHeaderSection(),

                // Search and Filter Section
                _buildSearchAndFilterSection(),

                // Users List
                Expanded(child: _buildUsersList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
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
                child: const Icon(Icons.people, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Utilisateurs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gérez les comptes utilisateurs',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Consumer<UserManagementViewModel>(
            builder: (context, viewModel, child) {
              final totalUsers = viewModel.users.length;
              final activeCount =
                  viewModel.users.where((u) => u.isActive).length;
              final inactiveCount = totalUsers - activeCount;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        totalUsers.toString(),
                        Icons.people_outline,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Actifs',
                        activeCount.toString(),
                        Icons.check_circle_outline,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Inactifs',
                        inactiveCount.toString(),
                        Icons.block,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: Icon(Icons.search, color: Colors.indigo.shade600),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              filled: true,
              fillColor: Colors.indigo.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tous', Icons.people),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Actifs', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('inactive', 'Inactifs', Icons.block),
                const SizedBox(width: 8),
                _buildFilterChip('admin', 'Admins', Icons.admin_panel_settings),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'technician',
                  'Techniciens',
                  Icons.engineering,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : Colors.indigo.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.indigo.shade600,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.indigo.shade50,
      selectedColor: Colors.indigo.shade600,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.indigo.shade600 : Colors.indigo.shade200,
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement...'),
              ],
            ),
          );
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => viewModel.loadUsers(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final filteredUsers = _getFilteredUsers(viewModel.users);

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun utilisateur trouvé'
                      : 'Aucun utilisateur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Créer un utilisateur'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _buildUserCard(user, viewModel);
          },
        );
      },
    );
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    List<UserModel> filtered = users;

    // Apply role and status filter
    if (_selectedFilter != 'all') {
      if (_selectedFilter == 'active') {
        filtered = filtered.where((user) => user.isActive).toList();
      } else if (_selectedFilter == 'inactive') {
        filtered = filtered.where((user) => !user.isActive).toList();
      } else {
        // Filter by role - FIXED TO SHOW ADMINS
        filtered =
            filtered
                .where(
                  (user) =>
                      user.role.toLowerCase() == _selectedFilter.toLowerCase(),
                )
                .toList();
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((user) {
            return user.name.toLowerCase().contains(_searchQuery) ||
                user.email.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    return filtered;
  }

  Widget _buildUserCard(UserModel user, UserManagementViewModel viewModel) {
    final isAdmin = user.role.toLowerCase() == 'admin';
    final roleColor = isAdmin ? Colors.purple : Colors.blue;
    final isActive = user.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            !isActive ? Border.all(color: Colors.red.shade200, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: roleColor.shade100,
                      backgroundImage:
                          user.profilePictureUrl != null
                              ? NetworkImage(user.profilePictureUrl!)
                              : null,
                      child:
                          user.profilePictureUrl == null
                              ? Icon(
                                Icons.person,
                                size: 24,
                                color: roleColor.shade600,
                              )
                              : null,
                    ),
                    // Status indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    isActive
                                        ? Colors.black
                                        : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAdmin ? 'Admin' : 'Tech',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Actif' : 'Inactif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isActive
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isActive
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phoneNumber?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons - NO EDIT FOR ADMINS
            if (isAdmin) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.purple.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Compte Administrateur',
                      style: TextStyle(
                        color: Colors.purple.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditUserDialog(user),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(
                        'Modifier',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade600,
                        side: BorderSide(color: Colors.indigo.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showToggleStatusDialog(user, viewModel),
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                      ),
                      label: Text(
                        isActive ? 'Désactiver' : 'Activer',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive
                                ? Colors.orange.shade600
                                : Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Nouvel Utilisateur',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'L\'email est requis';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() => isLoading = true);

                                  final viewModel =
                                      Provider.of<UserManagementViewModel>(
                                        context,
                                        listen: false,
                                      );

                                  final success = await viewModel.createUser(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text,
                                  );

                                  // In user_management_screen.dart, in the _showCreateUserDialog method
                                  // Replace the success handling with this simple version:

                                  if (success && mounted) {
                                    Navigator.pop(context);

                                    // Simple success message - no logout required
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Utilisateur ${nameController.text} créé avec succès!',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green.shade600,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  } else if (mounted) {
                                    setState(() => isLoading = false);
                                    NotificationUtils.showError(
                                      context,
                                      viewModel.errorMessage ??
                                          'Erreur lors de la création',
                                    );
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Créer'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final departmentController = TextEditingController(
      text: user.department ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Modifier Utilisateur',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value?.isEmpty == true ? 'Requis' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Requis';
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value!)) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: phoneController,
                              decoration: InputDecoration(
                                labelText: 'Téléphone',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: departmentController,
                              decoration: InputDecoration(
                                labelText: 'Département',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() => isLoading = true);

                                  final viewModel =
                                      Provider.of<UserManagementViewModel>(
                                        context,
                                        listen: false,
                                      );

                                  final success = await viewModel
                                      .updateUserProfile(
                                        authUid: user.authUid,
                                        name: nameController.text.trim(),
                                        email: emailController.text.trim(),
                                        phoneNumber:
                                            phoneController.text.trim().isEmpty
                                                ? null
                                                : phoneController.text.trim(),
                                        department:
                                            departmentController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : departmentController.text
                                                    .trim(),
                                      );

                                  if (success && mounted) {
                                    Navigator.pop(context);
                                    NotificationUtils.showSuccess(
                                      context,
                                      'Utilisateur modifié avec succès!',
                                    );
                                  } else if (mounted) {
                                    setState(() => isLoading = false);
                                    NotificationUtils.showError(
                                      context,
                                      viewModel.errorMessage ??
                                          'Erreur lors de la modification',
                                    );
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Enregistrer'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showToggleStatusDialog(
    UserModel user,
    UserManagementViewModel viewModel,
  ) {
    final isActive = user.isActive;
    final action = isActive ? 'désactiver' : 'activer';
    final actionTitle = isActive ? 'Désactiver' : 'Activer';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  isActive ? Icons.block : Icons.check_circle,
                  color: isActive ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$actionTitle l\'utilisateur',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Êtes-vous sûr de vouloir $action cet utilisateur ?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isActive
                              ? Colors.orange.shade200
                              : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color:
                            isActive
                                ? Colors.orange.shade600
                                : Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isActive
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isActive
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isActive
                      ? 'L\'utilisateur ne pourra plus se connecter.'
                      : 'L\'utilisateur pourra se connecter.',
                  style: TextStyle(
                    color:
                        isActive
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final success = await viewModel.toggleUserActiveStatus(
                    user.authUid,
                    !isActive,
                  );

                  if (success && mounted) {
                    NotificationUtils.showSuccess(
                      context,
                      'Utilisateur ${!isActive ? "activé" : "désactivé"} avec succès!',
                    );
                  } else if (mounted) {
                    NotificationUtils.showError(
                      context,
                      viewModel.errorMessage ??
                          'Erreur lors du changement de statut',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isActive ? Colors.orange.shade600 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionTitle),
              ),
            ],
          ),
    );
  }
}
