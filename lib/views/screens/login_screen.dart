// lib/views/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/login_view_model.dart';
import '../../utils/notification_utils.dart';
import '../../app/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  String dMessage = "";
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Start animations
    _animationController.forward();

    // Add focus listeners for better UX
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Function to sign in the user with improved error handling
  Future<void> signInWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = Provider.of<LoginViewModel>(context, listen: false);

    // Unfocus text fields to dismiss keyboard
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    try {
      debugPrint('LoginScreen: Tentative de connexion avec email: $email');
      final userCredential = await viewModel.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential != null && mounted) {
        debugPrint(
          'LoginScreen: Authentification réussie. Récupération du rôle utilisateur...',
        );
        // Obtenir le rôle utilisateur et naviguer
        final role = await viewModel.getUserRole();
        debugPrint('LoginScreen: Rôle utilisateur: $role');

        if (role == null && mounted) {
          NotificationUtils.showError(
            context,
            "Authentification réussie mais impossible de déterminer le rôle utilisateur. Veuillez contacter le support.",
          );
          return;
        }

        if (mounted) {
          debugPrint('LoginScreen: Navigation basée sur le rôle: $role');
          navigateBasedOnRole(context, role);
        }
      } else if (mounted) {
        dMessage = viewModel.lastErrorMessage;
        NotificationUtils.showError(context, dMessage);
      }
    } catch (e) {
      debugPrint("LoginScreen: Erreur inattendue lors de la connexion: $e");
      dMessage = "Une erreur inattendue s'est produite. Veuillez réessayer.";
      if (mounted) {
        NotificationUtils.showError(context, dMessage);
      }
    }
  }

  void navigateBasedOnRole(BuildContext context, String? role) async {
    debugPrint('LoginScreen: Navigation basée sur le rôle: $role');
    try {
      // Navigate to the right screen
      AppRoutes.navigateBasedOnRole(context, role);

      // Check if phone number is missing and show notification if needed
      final viewModel = Provider.of<LoginViewModel>(context, listen: false);
      final isPhoneMissing = await viewModel.isPhoneNumberMissing();

      if (isPhoneMissing && mounted) {
        // Wait a bit to ensure the new screen is loaded
        Future.delayed(const Duration(seconds: 1), () {
          NotificationUtils.showInfo(
            context,
            'Veuillez compléter votre profil en ajoutant votre numéro de téléphone.',
            duration: const Duration(seconds: 5),
          );
        });
      }
    } catch (e) {
      debugPrint('LoginScreen: Erreur de navigation: $e');
      NotificationUtils.showError(
        context,
        "Erreur lors de la navigation vers l'écran d'accueil. Veuillez réessayer.",
      );
    }
  }

  // Function to send password reset email
  Future<void> sendPasswordResetEmail(
    BuildContext context,
    String email,
  ) async {
    if (email.isEmpty) {
      NotificationUtils.showWarning(
        context,
        "Veuillez entrer votre adresse e-mail dans le champ ci-dessus",
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      NotificationUtils.showWarning(
        context,
        "Veuillez entrer une adresse e-mail valide",
      );
      return;
    }

    final viewModel = Provider.of<LoginViewModel>(context, listen: false);

    try {
      final success = await viewModel.sendPasswordResetEmail(email);
      if (success && mounted) {
        NotificationUtils.showSuccess(
          context,
          "Instructions de réinitialisation envoyées à $email",
        );
      } else if (mounted && viewModel.errorMessage != null) {
        NotificationUtils.showError(
          context,
          "Erreur: ${viewModel.errorMessage}",
        );
      }
    } catch (e) {
      debugPrint("Erreur inattendue: $e");
      if (mounted) {
        NotificationUtils.showError(
          context,
          "Une erreur inattendue s'est produite",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white, Colors.indigo.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Consumer<LoginViewModel>(
                  builder: (context, viewModel, child) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // Logo and App Name Section
                          _buildLogoSection(),

                          const SizedBox(height: 50),

                          // Welcome Text Section
                          _buildWelcomeSection(),

                          const SizedBox(height: 40),

                          // Login Form
                          _buildLoginForm(viewModel),

                          const SizedBox(height: 30),

                          // Login Button
                          _buildLoginButton(viewModel),

                          const SizedBox(height: 20),

                          // Forgot Password
                          _buildForgotPasswordSection(),

                          const SizedBox(height: 40),

                          // Footer
                          _buildFooterSection(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo Container
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.business_center,
            size: 35,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // App Name
        const Text(
          'KONY',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 4),

        // Tagline
        Text(
          'Solutions Réseaux Professionnelles',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        const Text(
          'Connexion',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Accédez à votre espace de travail',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(LoginViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email Field
            _buildEmailField(),

            const SizedBox(height: 20),

            // Password Field
            _buildPasswordField(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresse e-mail',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer votre adresse e-mail';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Adresse e-mail invalide';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'nom@exemple.com',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(
              Icons.email_outlined,
              color:
                  _emailFocusNode.hasFocus ? Colors.blue : Colors.grey.shade400,
              size: 22,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(LoginViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre mot de passe';
            }
            if (value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Entrez votre mot de passe',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(
              Icons.lock_outline,
              color:
                  _passwordFocusNode.hasFocus
                      ? Colors.blue
                      : Colors.grey.shade400,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade500,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(LoginViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              viewModel.isLoading
                  ? [Colors.grey.shade300, Colors.grey.shade400]
                  : [Colors.blue.shade600, Colors.indigo.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            viewModel.isLoading
                ? null
                : [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              viewModel.isLoading
                  ? null
                  : () {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
                    signInWithEmailAndPassword(context, email, password);
                  },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child:
                viewModel.isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordSection() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            final email = _emailController.text.trim();
            sendPasswordResetEmail(context, email);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, size: 18, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                'Mot de passe oublié ?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Un lien de réinitialisation sera envoyé à votre adresse e-mail',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.security,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connexion sécurisée',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Vos données sont protégées par un chiffrement de niveau entreprise',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          '© 2024 Kony Solutions. Tous droits réservés.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Version 1.0.3',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
