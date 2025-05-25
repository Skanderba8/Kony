// lib/views/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kony/app/routes.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../view_models/user_management_view_model.dart';
import '../../services/user_management_service.dart';
import '../../utils/notification_utils.dart';
import '../widgets/app_sidebar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isSaving = false;

  File? _profileImage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

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
            if (userModel != null) {
              _nameController.text = userModel.name;
              _emailController.text = userModel.email;
              _phoneController.text = userModel.phoneNumber ?? '';
              _addressController.text = userModel.address ?? '';
              _departmentController.text = userModel.department ?? '';
            }
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

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 70,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifier la photo de profil',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Colors.blue.shade600,
                  ),
                  title: const Text('Galerie'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue.shade600),
                  title: const Text('Appareil photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_profileImage != null ||
                    _userModel?.profilePictureUrl != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red.shade600),
                    title: const Text('Supprimer'),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _profileImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _navigateBack() {
    final String currentRole = _userModel?.role ?? 'technician';

    if (currentRole == 'admin') {
      // Navigate to Admin Dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.admin,
        (route) => false,
      );
    } else {
      // Navigate to Technician Dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.technician,
        (route) => false,
      );
    }
  }

  void _handleEmailChange() async {
    final String oldEmail = _userModel?.email ?? '';
    final String newEmail = _emailController.text.trim();

    if (oldEmail == newEmail) return;

    final passwordController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mot de passe requis'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Entrez votre mot de passe pour changer l\'email:'),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      setState(() {
        _isSaving = true;
      });

      try {
        final viewModel = Provider.of<UserManagementViewModel>(
          context,
          listen: false,
        );
        final success = await viewModel.updateEmail(
          passwordController.text,
          newEmail,
        );

        if (success && mounted) {
          NotificationUtils.showSuccess(
            context,
            'Email mis à jour avec succès.',
          );
        } else if (mounted) {
          _emailController.text = oldEmail;
          NotificationUtils.showError(
            context,
            viewModel.errorMessage ?? 'Erreur lors de la mise à jour',
          );
        }
      } catch (e) {
        if (mounted) {
          _emailController.text = oldEmail;
          NotificationUtils.showError(context, 'Erreur: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final String oldEmail = _userModel?.email ?? '';
    final String newEmail = _emailController.text.trim();

    if (oldEmail != newEmail) {
      _handleEmailChange();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserManagementViewModel>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null && _userModel != null) {
      try {
        final success = await viewModel.updateUserProfile(
          authUid: user.uid,
          name: _nameController.text,
          profilePicture: _profileImage,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
          department: _departmentController.text,
        );

        if (success && mounted) {
          NotificationUtils.showSuccess(
            context,
            'Profil mis à jour avec succès',
          );
          _loadUserData();
        } else if (mounted && viewModel.errorMessage != null) {
          NotificationUtils.showError(context, viewModel.errorMessage!);
        }
      } catch (e) {
        if (mounted) {
          NotificationUtils.showError(context, 'Erreur: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = _userModel?.role ?? 'technician';

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppSidebar(
        userRole: userRole,
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade800,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage:
                                    _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : (_userModel?.profilePictureUrl != null
                                            ? NetworkImage(
                                              _userModel!.profilePictureUrl!,
                                            )
                                            : null),
                                child:
                                    _profileImage == null &&
                                            _userModel?.profilePictureUrl ==
                                                null
                                        ? Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.grey.shade600,
                                        )
                                        : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name Display
                        Text(
                          _userModel?.name ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          backgroundColor:
                              userRole == 'admin'
                                  ? Colors.purple.shade100
                                  : Colors.blue.shade100,
                          label: Text(
                            userRole == 'admin'
                                ? 'Administrateur'
                                : 'Technicien',
                            style: TextStyle(
                              color:
                                  userRole == 'admin'
                                      ? Colors.purple.shade700
                                      : Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informations personnelles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Name
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _buildInputDecoration(
                                    label: 'Nom complet',
                                    icon: Icons.person,
                                  ),
                                  validator:
                                      (value) =>
                                          value?.trim().isEmpty ?? true
                                              ? 'Veuillez entrer votre nom'
                                              : null,
                                ),

                                const SizedBox(height: 16),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _buildInputDecoration(
                                    label: 'Email',
                                    icon: Icons.email,
                                  ),
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Veuillez entrer un email';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );
                                    return !emailRegex.hasMatch(value!)
                                        ? 'Email invalide'
                                        : null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Phone
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    label: 'Téléphone',
                                    icon: Icons.phone,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Department
                                TextFormField(
                                  controller: _departmentController,
                                  decoration: _buildInputDecoration(
                                    label: 'Département',
                                    icon: Icons.business,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Address
                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  decoration: _buildInputDecoration(
                                    label: 'Adresse',
                                    icon: Icons.location_on,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Save Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isSaving ? null : _updateProfile,
                                    icon:
                                        _isSaving
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Icon(Icons.save),
                                    label:
                                        _isSaving
                                            ? const Text('Mise à jour...')
                                            : const Text(
                                              'Enregistrer les modifications',
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
