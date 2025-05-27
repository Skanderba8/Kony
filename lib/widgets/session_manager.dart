// lib/widgets/session_manager.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../app/routes.dart';

/// Widget that manages user sessions and handles session warnings/timeouts
/// Wrap your main app content with this widget to enable session management
class SessionManager extends StatefulWidget {
  final Widget child;

  const SessionManager({super.key, required this.child});

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager>
    with WidgetsBindingObserver {
  AuthService? _authService;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSessionCallbacks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize session warning and expiry callbacks
  void _initializeSessionCallbacks() {
    _authService = Provider.of<AuthService>(context, listen: false);

    // Set up session warning callback
    _authService!.onSessionWarning = () {
      if (!_warningShown && mounted) {
        _showSessionWarningDialog();
      }
    };

    // Set up session expiry callback
    _authService!.onSessionExpired = () {
      if (mounted) {
        _handleSessionExpired();
      }
    };
  }

  /// Handle app lifecycle changes to update user activity
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // User returned to app, update activity
      _authService?.updateActivity();
      _warningShown = false; // Reset warning flag when app resumes
    }
  }

  /// Show session warning dialog (15 minutes before expiry)
  void _showSessionWarningDialog() {
    if (!mounted || _warningShown) return;

    _warningShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              const Text('Session bientôt expirée'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre session expirera dans 15 minutes en raison d\'inactivité.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voulez-vous prolonger votre session ?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Let session expire naturally
              },
              child: Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _authService?.extendSession();
                _warningShown = false;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session prolongée de 4 heures'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Prolonger la session'),
            ),
          ],
        );
      },
    );
  }

  /// Handle session expiry
  void _handleSessionExpired() {
    if (!mounted) return;

    // Show session expired message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              const Text('Session expirée'),
            ],
          ),
          content: const Text(
            'Votre session a expiré pour des raisons de sécurité. '
            'Veuillez vous reconnecter pour continuer.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Se reconnecter'),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  /// Update user activity on tap
  void _onUserInteraction() {
    _authService?.updateActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Wrap child with GestureDetector to track user activity
        return GestureDetector(
          onTap: _onUserInteraction,
          onPanStart: (_) => _onUserInteraction(),
          onScaleStart: (_) => _onUserInteraction(),
          behavior: HitTestBehavior.translucent,
          child: Listener(
            onPointerDown: (_) => _onUserInteraction(),
            onPointerMove: (_) => _onUserInteraction(),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Session info widget to display remaining session time (for debugging/admin)
class SessionInfoWidget extends StatefulWidget {
  const SessionInfoWidget({super.key});

  @override
  State<SessionInfoWidget> createState() => _SessionInfoWidgetState();
}

class _SessionInfoWidgetState extends State<SessionInfoWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isAuthenticated) {
          return const SizedBox.shrink();
        }

        final remainingTime = authService.getSessionRemainingTime();
        if (remainingTime == null) {
          return const Text(
            'Session permanente',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        final hours = remainingTime.inHours;
        final minutes = remainingTime.inMinutes.remainder(60);
        final isNearExpiry = authService.isSessionNearExpiry();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isNearExpiry ? Colors.orange.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isNearExpiry ? Colors.orange.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 14,
                color:
                    isNearExpiry
                        ? Colors.orange.shade600
                        : Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${hours}h ${minutes}m',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isNearExpiry
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
