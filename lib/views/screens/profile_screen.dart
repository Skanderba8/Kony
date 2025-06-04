// lib/views/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/user_management_service.dart';
import '../../models/user_model.dart';
import '../../utils/notification_utils.dart';
import '../../app/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _fabAnimationController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _departmentController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isEditing = false;
  UserModel? _userModel;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    // Header animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Content animation
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start animations
    _headerAnimationController.forward();
    _contentAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _fabAnimationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        _userRole = authService.getUserRole();

        final userService = UserManagementService();
        _userModel = await userService.getUserByAuthUid(user.uid);

        if (_userModel != null) {
          _nameController.text = _userModel!.name;
          _phoneController.text = _userModel!.phoneNumber ?? '';
          _addressController.text = _userModel!.address ?? '';
          _departmentController.text = _userModel!.department ?? '';
        }
      }
    } catch (e) {
      NotificationUtils.showError(
        context,
        'Erreur lors du chargement du profil: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        final userService = UserManagementService();

        final success = await userService.updateUserProfile(
          authUid: user.uid,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          department: _departmentController.text.trim(),
        );

        if (success) {
          setState(() => _isEditing = false);
          await _loadUserData();
          NotificationUtils.showSuccess(
            context,
            'Profil mis à jour avec succès',
          );
        } else {
          NotificationUtils.showError(
            context,
            'Erreur lors de la mise à jour du profil',
          );
        }
      }
    } catch (e) {
      NotificationUtils.showError(context, 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      NotificationUtils.showError(context, 'Le nom est obligatoire');
      return false;
    }
    return true;
  }

  void _navigateBackToDashboard() {
    if (_userRole == 'admin') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.admin,
        (route) => false,
      );
    } else if (_userRole == 'technician') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.technician,
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du profil...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAnimatedAppBar(),
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _contentSlideAnimation,
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Column(
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildInfoCards(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: SlideTransition(
        position: _headerSlideAnimation,
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _navigateBackToDashboard,
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.indigo.shade600,
              ),
              tooltip: 'Retour au tableau de bord',
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        title: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: const Text(
              'Mon Profil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade600,
                Colors.blue.shade500,
                Colors.cyan.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile icon/avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.blue.shade400],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),

          const SizedBox(height: 24),

          // Name and role
          Text(
            _userModel?.name ?? 'Utilisateur',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    _userRole == 'admin'
                        ? [Colors.purple.shade400, Colors.indigo.shade500]
                        : [Colors.blue.shade400, Colors.cyan.shade500],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userRole == 'admin' ? 'Administrateur' : 'Technicien',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userModel?.email ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Replace the _buildInfoCards method in your profile_screen.dart with this updated version:

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            'Informations personnelles',
            Icons.person_outline,
            Colors.blue,
            [
              _buildInfoField(
                'Nom complet',
                _nameController,
                Icons.badge_outlined,
                required: true,
              ),
              _buildInfoField(
                'Téléphone',
                _phoneController,
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildInfoField(
                'Adresse',
                _addressController,
                Icons.location_on_outlined,
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            'Informations professionnelles',
            Icons.work_outline,
            Colors.green,
            [
              _buildInfoField(
                'Département',
                _departmentController,
                Icons.business_outlined,
              ),
              _buildReadOnlyField(
                'Rôle',
                _userRole == 'admin' ? 'Administrateur' : 'Technicien',
                Icons.admin_panel_settings_outlined,
              ),
              _buildReadOnlyField(
                'Email',
                _userModel?.email ?? '',
                Icons.email_outlined,
              ),
              // ADD PASSWORD CHANGE BUTTON HERE
              _buildPasswordChangeButton(),
            ],
          ),
        ],
      ),
    );
  }

  // Add this new method to create the password change button:
  Widget _buildPasswordChangeButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showChangePasswordDialog,
          icon: const Icon(Icons.lock_reset, size: 20),
          label: const Text(
            'Changer le mot de passe',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
              hintText: 'Entrez votre $label',
              filled: true,
              fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Non renseigné' : value,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          value.isEmpty ? Colors.grey.shade500 : Colors.black87,
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

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed:
            _isLoading
                ? null
                : _isEditing
                ? _saveProfile
                : () => setState(() => _isEditing = true),
        backgroundColor:
            _isEditing ? Colors.green.shade600 : Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(_isEditing ? Icons.save : Icons.edit),
        label: Text(
          _isLoading
              ? 'Sauvegarde...'
              : _isEditing
              ? 'Sauvegarder'
              : 'Modifier',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Add these methods to your profile_screen.dart

  Widget _buildEditableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onEdit,
    bool showEditButton = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.indigo.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (showEditButton)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Non renseigné',
              style: TextStyle(
                fontSize: 14,
                color: value != null ? Colors.black87 : Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Replace your existing profile sections with these clickable ones:

  Widget _buildPersonalInfoSection() {
    final user = context.watch<AuthService>().currentUserModel;

    return _buildEditableSection(
      title: 'Informations Personnelles',
      icon: Icons.person_outline,
      onEdit: () => _showEditPersonalInfoDialog(user),
      children: [
        _buildInfoRow('Nom complet', user?.name, icon: Icons.badge_outlined),
        _buildInfoRow('Email', user?.email, icon: Icons.email_outlined),
        _buildInfoRow(
          'Téléphone',
          user?.phoneNumber,
          icon: Icons.phone_outlined,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    final user = context.watch<AuthService>().currentUserModel;

    return _buildEditableSection(
      title: 'Informations Professionnelles',
      icon: Icons.work_outline,
      onEdit: () => _showEditProfessionalInfoDialog(user),
      children: [
        _buildInfoRow(
          'Rôle',
          user?.roleDisplayText,
          icon: Icons.admin_panel_settings_outlined,
        ),
        _buildInfoRow(
          'Département',
          user?.department,
          icon: Icons.business_outlined,
        ),
        _buildInfoRow(
          'Adresse',
          user?.address,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildEditableSection(
      title: 'Sécurité',
      icon: Icons.security_outlined,
      onEdit: () => _showChangePasswordDialog(),
      children: [
        _buildInfoRow('Mot de passe', '••••••••', icon: Icons.lock_outlined),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cliquez pour changer votre mot de passe en toute sécurité',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // Dialog methods for editing profile sections:

  void _showEditPersonalInfoDialog(UserModel? user) {
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Informations Personnelles'),
                    ],
                  ),
                  content: Form(
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
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty == true ? 'Nom requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Email requis';
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
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
                                  await _updateProfile(
                                    name: nameController.text,
                                    email: emailController.text,
                                    phoneNumber: phoneController.text,
                                  );
                                  if (mounted) Navigator.pop(context);
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
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

  void _showEditProfessionalInfoDialog(UserModel? user) {
    if (user == null) return;

    final departmentController = TextEditingController(
      text: user.department ?? '',
    );
    final addressController = TextEditingController(text: user.address ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.work_outline,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Informations Professionnelles'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: departmentController,
                        decoration: InputDecoration(
                          labelText: 'Département',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
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
                                setState(() => isLoading = true);
                                await _updateProfile(
                                  department: departmentController.text,
                                  address: addressController.text,
                                );
                                if (mounted) Navigator.pop(context);
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Changer le Mot de Passe',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pour votre sécurité, veuillez d\'abord confirmer votre mot de passe actuel.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe actuel',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe actuel est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Un email de réinitialisation sera envoyé à votre adresse email.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

                                  try {
                                    final authService =
                                        context.read<AuthService>();

                                    // Initiate password change (verify current password + send reset email)
                                    await authService.initiatePasswordChange(
                                      currentPasswordController.text,
                                    );

                                    if (mounted) {
                                      Navigator.pop(context);

                                      // Show success dialog
                                      _showPasswordResetSuccessDialog();
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (mounted) {
                                      setState(() => isLoading = false);

                                      String message;
                                      switch (e.code) {
                                        case 'wrong-password':
                                          message =
                                              'Le mot de passe actuel est incorrect.';
                                          break;
                                        case 'too-many-requests':
                                          message =
                                              'Trop de tentatives. Réessayez plus tard.';
                                          break;
                                        default:
                                          message = 'Erreur: ${e.message}';
                                          break;
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(message)),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => isLoading = false);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Erreur inattendue: $e',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Envoyer l\'email'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Add this new method to show success dialog
  void _showPasswordResetSuccessDialog() {
    final userEmail = context.read<AuthService>().currentUserModel?.email ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green.shade600),
                ),
                const SizedBox(width: 12),
                const Text('Email Envoyé'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.email, size: 48, color: Colors.green.shade600),
                      const SizedBox(height: 12),
                      Text(
                        'Email de Réinitialisation Envoyé',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Un email de réinitialisation a été envoyé à:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vérifiez votre boîte de réception et suivez les instructions pour changer votre mot de passe.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Compris'),
              ),
            ],
          ),
    );
  }

  // Update profile method
  Future<void> _updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? department,
    String? address,
  }) async {
    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUserModel;

      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        email: email ?? currentUser.email,
        phoneNumber: phoneNumber ?? currentUser.phoneNumber,
        department: department ?? currentUser.department,
        address: address ?? currentUser.address,
      );

      await authService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil mis à jour avec succès!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
