// lib/views/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_management_view_model.dart';
import '../../models/user_model.dart';
import '../../utils/notification_utils.dart';
import '../widgets/user_edit_dialog.dart';
import '../widgets/app_sidebar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showPassword = false;
  late TabController _tabController;

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
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

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
      NotificationUtils.showInfo(context, 'Compte technicien créé avec succès');
    } else if (mounted && viewModel.errorMessage != null) {
      NotificationUtils.showError(context, viewModel.errorMessage!);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
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
          'Gestion des Utilisateurs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          tabs: const [
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

  Widget _buildCreateUserForm() {
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: 'Nom Complet',
                  hintText: 'Entrez le nom complet',
                  prefixIcon: Icons.person,
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Veuillez entrer le nom complet'
                              : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  label: 'E-mail',
                  hintText: 'Entrez l\'adresse e-mail',
                  prefixIcon: Icons.email,
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
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  isPasswordVisible: _showPassword,
                  onToggleVisibility: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      elevation: 0,
                    ),
                    child:
                        viewModel.isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Créer un Technicien',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    bool enabled = true,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color:
                  focusNode.hasFocus && enabled
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              prefixIcon: Icon(
                prefixIcon,
                color: enabled ? Colors.grey : Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color:
                  focusNode.hasFocus
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le mot de passe';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit comporter au moins 6 caractères';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Entrez le mot de passe',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              prefixIcon: const Icon(Icons.lock, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.blue,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    return Consumer<UserManagementViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadUsers(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (viewModel.users.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucun utilisateur trouvé'),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez d\'actualiser ou vérifiez la console Firebase',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => viewModel.loadUsers(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: const Text('Actualiser la Liste'),
                      ),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: const Text('Créer un Nouvel Utilisateur'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.loadUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.users.length,
            itemBuilder: (context, index) {
              final user = viewModel.users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ListTile(
                    title: Text(user.name, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email, overflow: TextOverflow.ellipsis),
                        Text(
                          'ID: ${user.id}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.authUid.isNotEmpty)
                          Text(
                            'Auth UID: ${user.authUid.substring(0, min(10, user.authUid.length))}...',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditUserDialog(user),
                          tooltip: 'Modifier l\'Utilisateur',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade400),
                          onPressed: () => _confirmDeleteUser(user),
                          tooltip: 'Supprimer l\'Utilisateur',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => UserEditDialog(
            user: user,
            onSave: (name, email, _) async {
              final viewModel = Provider.of<UserManagementViewModel>(
                context,
                listen: false,
              );

              try {
                final success = await viewModel.updateUser(
                  authUid: user.authUid,
                  name: name,
                  email: email,
                  role: user.role,
                );

                if (success && mounted) {
                  NotificationUtils.showInfo(
                    context,
                    'Utilisateur ${user.name} mis à jour avec succès',
                  );
                } else if (mounted) {
                  NotificationUtils.showError(
                    context,
                    'Échec de la mise à jour de l\'utilisateur ${user.name}',
                  );
                }
              } catch (e) {
                if (mounted) {
                  NotificationUtils.showError(
                    context,
                    'Une erreur s\'est produite lors de la mise à jour de l\'utilisateur: ${e.toString()}',
                  );
                }
              }
            },
          ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Supprimer l\'Utilisateur',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                    text: 'Êtes-vous sûr de vouloir supprimer l\'utilisateur ',
                  ),
                  TextSpan(
                    text: user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: ' ? Cette action ne peut pas être annulée.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteUser(user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );

    try {
      final success = await viewModel.deleteUserCompletely(user.authUid);

      if (success && mounted) {
        NotificationUtils.showInfo(
          context,
          'Utilisateur ${user.name} supprimé avec succès',
        );
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          'Échec de la suppression de l\'utilisateur ${user.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Une erreur s\'est produite lors de la suppression de l\'utilisateur: ${e.toString()}',
        );
      }
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}
