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
  final _formKey = GlobalKey<FormState>();

  late TabController _tabController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserManagementViewModel>(context, listen: false).loadUsers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Create a new user
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );

    final success = await viewModel.createUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      _clearForm();
      _tabController.animateTo(1); // Switch to user list tab
      NotificationUtils.showSuccess(
        context,
        'Compte technicien créé avec succès',
      );
    } else if (mounted && viewModel.errorMessage != null) {
      NotificationUtils.showError(context, viewModel.errorMessage!);
    }
  }

  // Clear the form
  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  // Delete a user
  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Supprimer l\'Utilisateur'),
            content: Text('Êtes-vous sûr de vouloir supprimer ${user.name} ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteUser(user);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  // Execute user deletion
  Future<void> _deleteUser(UserModel user) async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );

    final success = await viewModel.deleteUserCompletely(user.authUid);

    if (success && mounted) {
      NotificationUtils.showSuccess(
        context,
        'Utilisateur ${user.name} supprimé avec succès',
      );
    } else if (mounted) {
      NotificationUtils.showError(
        context,
        viewModel.errorMessage ?? 'Erreur lors de la suppression',
      );
    }
  }

  // Edit a user
  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Modifier l\'utilisateur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateUser(
                    user.authUid,
                    nameController.text,
                    emailController.text,
                  );
                  Navigator.of(context).pop();
                },
                child: Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  // Update a user
  Future<void> _updateUser(String authUid, String name, String email) async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );

    final success = await viewModel.updateUserProfile(
      authUid: authUid,
      name: name,
      email: email,
    );

    if (success && mounted) {
      NotificationUtils.showSuccess(context, 'Utilisateur mis à jour');
    } else if (mounted && viewModel.errorMessage != null) {
      NotificationUtils.showError(context, viewModel.errorMessage!);
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
        title: Text(
          'Gestion des Utilisateurs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Créer un Technicien'),
            Tab(text: 'Liste des Techniciens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCreateUserForm(), _buildUserList()],
      ),
    );
  }

  // Create user form
  Widget _buildCreateUserForm() {
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom Complet',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer le nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer l\'e-mail';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    return !emailRegex.hasMatch(value)
                        ? 'Veuillez entrer un e-mail valide'
                        : null;
                  },
                ),
                SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit comporter au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        viewModel.isLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                            : Text('Créer un Technicien'),
                  ),
                ),

                // Error message
                if (viewModel.errorMessage != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.red.shade50,
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // User list
  Widget _buildUserList() {
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(viewModel.errorMessage!),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadUsers(),
                  child: Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (viewModel.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun utilisateur trouvé'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadUsers(),
                  child: Text('Actualiser'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.loadUsers(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: viewModel.users.length,
            itemBuilder: (context, index) {
              final user = viewModel.users[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditUserDialog(user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteUser(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
