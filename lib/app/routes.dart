// lib/app/routes.dart
import 'package:flutter/material.dart';
import '../views/screens/login_screen.dart';
import '../views/screens/admin_screen.dart';
import '../views/screens/technician_screen.dart';
import '../views/screens/user_management_screen.dart';
import '../views/screens/report_form/report_form_screen.dart';
import '../views/screens/pdf_viewer_screen.dart';
import '../views/screens/profile_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String admin = '/admin';
  static const String technician = '/technician';
  static const String userManagement = '/user-management';
  static const String reportForm = '/report-form';
  static const String pdfViewer = '/pdf-viewer';
  static const String profile = '/profile';

  // Define routes for navigator
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      admin: (context) => const AdminScreen(),
      technician: (context) => const TechnicianScreen(),
      userManagement: (context) => const UserManagementScreen(),
      reportForm: (context) => const ReportFormScreen(),
      profile: (context) => const ProfileScreen(),
      // PDF viewer route is handled dynamically since it requires file parameters
    };
  }

  // Navigation method based on user role
  static void navigateBasedOnRole(BuildContext context, String? role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, admin);
    } else if (role == 'technician') {
      Navigator.pushReplacementNamed(context, technician);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rôle utilisateur invalide ou manquant')),
      );
    }
  }
}
