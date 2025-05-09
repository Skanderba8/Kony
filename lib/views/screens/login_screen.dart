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

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String dMessage = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Function to sign in the user with improved error handling
  Future<void> signInWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);

    if (email.isEmpty || password.isEmpty) {
      NotificationUtils.showWarning(
        context,
        "Veuillez remplir tous les champs",
      );
      return;
    }

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

  // Navigation basée sur le rôle utilisateur avec une meilleure journalisation
  void navigateBasedOnRole(BuildContext context, String? role) {
    debugPrint('LoginScreen: Navigation basée sur le rôle: $role');
    try {
      AppRoutes.navigateBasedOnRole(context, role);
    } catch (e) {
      debugPrint('LoginScreen: Erreur de navigation: $e');
      NotificationUtils.showError(
        context,
        "Erreur lors de la navigation vers l'écran d'accueil. Veuillez réessayer.",
      );
    }
  }

  // Fonction pour envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(
    BuildContext context,
    String email,
  ) async {
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);

    if (email.isEmpty) {
      NotificationUtils.showWarning(
        context,
        "Veuillez entrer votre adresse e-mail",
      );
      return;
    }

    try {
      final success = await viewModel.sendPasswordResetEmail(email);
      if (success && mounted) {
        NotificationUtils.showSuccess(
          context,
          "E-mail de réinitialisation envoyé !",
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
      appBar: AppBar(
        title: const Text(
          'Kony',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Bienvenue !',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adresse e-mail',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color:
                                _emailFocusNode.hasFocus
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Entrez votre e-mail',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
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
                  ),
                  const SizedBox(height: 20),
                  Column(
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
                                _passwordFocusNode.hasFocus
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: !viewModel.isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 15.0,
                            ),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewModel.isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.blue,
                                size: 22,
                              ),
                              onPressed: viewModel.togglePasswordVisibility,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        final email = _emailController.text.trim();
                        sendPasswordResetEmail(context, email);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '"Mot de passe oublié ?',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed:
                        viewModel.isLoading
                            ? null
                            : () {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              signInWithEmailAndPassword(
                                context,
                                email,
                                password,
                              );
                            },
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
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                            : const Text(
                              'Connexion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
