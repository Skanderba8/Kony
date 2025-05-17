// lib/views/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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

  // Load user data
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

  // Pick image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          'Erreur lors de la sélection de l\'image',
        );
      }
    }
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.blue),
                  title: Text('Galerie'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue),
                  title: Text('Appareil photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_profileImage != null ||
                    _userModel?.profilePictureUrl != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer'),
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

  // Handle email change
  // In lib/views/screens/profile_screen.dart - modify the _handleEmailChange method
  void _handleEmailChange() async {
    final String oldEmail = _userModel?.email ?? '';
    final String newEmail = _emailController.text.trim();

    if (oldEmail == newEmail) return;

    final passwordController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Mot de passe requis'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Entrez votre mot de passe pour changer l\'email:'),
                SizedBox(height: 10),
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
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirmer'),
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
            'Email mis à jour dans notre système. Si une vérification est requise, veuillez vérifier votre boîte de réception pour confirmer le changement.',
          );
        } else if (mounted) {
          _emailController.text = oldEmail;
          NotificationUtils.showError(
            context,
            viewModel.errorMessage ?? 'Erreur de mise à jour',
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

  // Update profile
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
          NotificationUtils.showError(
            context,
            'Erreur lors de la mise à jour: $e',
          );
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

  // Exit profile screen
  void _exitProfileScreen() {
    Navigator.of(context).pop();
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
        title: Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            tooltip: 'Quitter',
            onPressed: _exitProfileScreen,
          ),
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.blue))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (_userModel?.profilePictureUrl != null
                                        ? NetworkImage(
                                              _userModel!.profilePictureUrl!,
                                            )
                                            as ImageProvider
                                        : null),
                            child:
                                _profileImage == null &&
                                        _userModel?.profilePictureUrl == null
                                    ? Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.blue,
                                    )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Name and role
                    Text(
                      _userModel?.name ?? 'Utilisateur',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        userRole == 'admin' ? 'Administrateur' : 'Technicien',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Profile form
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations personnelles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Name field
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                return !emailRegex.hasMatch(value)
                                    ? 'Email invalide'
                                    : null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Téléphone',
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 16),

                            // Department field
                            TextFormField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                labelText: 'Département',
                                prefixIcon: Icon(
                                  Icons.business,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Address field
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Adresse',
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              maxLines: 2,
                            ),
                            SizedBox(height: 24),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isSaving
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                        : Text(
                                          'Mettre à jour le profil',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
    );
  }
}
