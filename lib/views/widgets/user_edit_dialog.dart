// lib/widgets/user_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/user_management_view_model.dart';

class UserEditDialog extends StatefulWidget {
  final UserModel user;
  final Function(String name, String email, String role) onSave;

  const UserEditDialog({super.key, required this.user, required this.onSave});

  @override
  _UserEditDialogState createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _departmentController;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _departmentController = TextEditingController(
      text: widget.user.department ?? '',
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              maxLines: maxLines,
              enabled: enabled,
              style: TextStyle(
                fontSize: 16,
                color: enabled ? Colors.black87 : Colors.grey.shade600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: Colors.indigo.shade600,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: enabled ? Colors.white : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.indigo.shade400,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> get _steps => [
    // Step 1: Basic Information
    Column(
      children: [
        _buildModernTextField(
          controller: _nameController,
          label: 'Nom Complet *',
          hintText: 'Entrez le nom complet',
          prefixIcon: Icons.person_outline,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Le nom est requis'
                      : null,
        ),
        _buildModernTextField(
          controller: _emailController,
          label: 'Adresse E-mail *',
          hintText: 'exemple@email.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'e-mail est requis';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            return !emailRegex.hasMatch(value)
                ? 'Entrez une adresse e-mail valide'
                : null;
          },
        ),
      ],
    ),
    // Step 2: Contact & Department
    Column(
      children: [
        _buildModernTextField(
          controller: _phoneController,
          label: 'Numéro de Téléphone',
          hintText: '+216 XX XXX XXX',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 8) {
              return 'Numéro de téléphone invalide';
            }
            return null;
          },
        ),
        _buildModernTextField(
          controller: _departmentController,
          label: 'Département',
          hintText: 'Service ou département',
          prefixIcon: Icons.business_outlined,
        ),
        _buildModernTextField(
          controller: _addressController,
          label: 'Adresse Complète',
          hintText: 'Adresse de résidence ou travail',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Progress Indicator
                _buildProgressIndicator(),
                const SizedBox(height: 30),

                // Form Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _steps[_currentStep],
                      ),
                    ),
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier le Profil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                widget.user.name,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index <= _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Colors.indigo.shade400
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        setState(() {
                          _currentStep--;
                        });
                      },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleNext,
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
                    : Icon(
                      _currentStep == 1 ? Icons.save : Icons.arrow_forward,
                    ),
            label: Text(_currentStep == 1 ? 'Enregistrer' : 'Suivant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      // Validate first step
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format d\'email invalide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _currentStep++;
      });
    } else {
      // Final save
      await _handleSave();
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<UserManagementViewModel>(
        context,
        listen: false,
      );

      final success = await viewModel.updateUserProfile(
        authUid: widget.user.authUid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        department:
            _departmentController.text.trim().isEmpty
                ? null
                : _departmentController.text.trim(),
      );

      if (success && mounted) {
        widget.onSave(
          _nameController.text.trim(),
          _emailController.text.trim(),
          widget.user.role,
        );
        Navigator.of(context).pop();

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
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewModel.errorMessage ?? 'Erreur lors de la mise à jour',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
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
                Expanded(child: Text('Erreur inattendue: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
