import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/user_management_view_model.dart';
import '../../models/user_model.dart';
import '../../utils/notification_utils.dart';
import '../widgets/user_edit_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _showPassword = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
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
      setState(() => _selectedTabIndex = 1);
      NotificationUtils.showInfo(
        context,
        'Technician account created successfully',
      );
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
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildSegmentedControlButton(
                    context,
                    index: 0,
                    label: 'Create Technician',
                    icon: Icons.person_add_outlined,
                  ),
                  _buildSegmentedControlButton(
                    context,
                    index: 1,
                    label: 'Technician List',
                    icon: Icons.list_outlined,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                _selectedTabIndex == 0
                    ? _buildCreateUserForm()
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControlButton(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
                  label: 'Full Name',
                  hintText: 'Enter full name',
                  prefixIcon: Icons.person,
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter full name'
                              : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  label: 'Email',
                  hintText: 'Enter email address',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    return !emailRegex.hasMatch(value)
                        ? 'Please enter a valid email'
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
                              'Create Technician',
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
          'Password',
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
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter password',
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
                Text(viewModel.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadUsers(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                  child: const Text('Retry'),
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
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No users found'),
                const SizedBox(height: 8),
                Text(
                  'Try refreshing or checking Firebase console',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => viewModel.loadUsers(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                      ),
                      child: const Text('Refresh List'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedTabIndex = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                      ),
                      child: const Text('Create New User'),
                    ),
                  ],
                ),
              ],
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
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Text(
                        'ID: ${user.id}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (user.authUid.isNotEmpty)
                        Text(
                          'Auth UID: ${user.authUid}',
                          style: const TextStyle(fontSize: 12),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditUserDialog(user),
                        tooltip: 'Edit User',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade400),
                        onPressed: () => _confirmDeleteUser(user),
                        tooltip: 'Delete User',
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

                if (success) {
                  NotificationUtils.showInfo(
                    context,
                    'User ${user.name} updated successfully',
                  );
                } else {
                  NotificationUtils.showError(
                    context,
                    'Failed to update user ${user.name}',
                  );
                }
              } catch (e) {
                NotificationUtils.showError(
                  context,
                  'An error occurred while updating user: ${e.toString()}',
                );
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
              'Delete User',
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
                    text: 'Are you sure you want to delete the user ',
                  ),
                  TextSpan(
                    text: user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '? This action cannot be undone.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
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
                child: const Text('Delete'),
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

      if (success) {
        NotificationUtils.showInfo(
          context,
          'User ${user.name} deleted successfully',
        );
      } else {
        NotificationUtils.showError(
          context,
          'Failed to delete user ${user.name}',
        );
      }
    } catch (e) {
      NotificationUtils.showError(
        context,
        'An error occurred while deleting user: ${e.toString()}',
      );
    }
  }
}
