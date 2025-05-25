// lib/app/routes.dart
import 'package:flutter/material.dart';
import 'package:kony/views/screens/report_form/report_form_screen.dart';
import 'package:kony/views/screens/report_list_screen.dart';
import 'package:kony/views/screens/statistics_screen.dart';
import 'package:kony/views/screens/admin_reports_screen.dart';
import '../views/screens/login_screen.dart';
import '../views/screens/admin_screen.dart';
import '../views/screens/technician_screen.dart';
import '../views/screens/user_management_screen.dart';
import '../views/screens/profile_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String admin = '/admin';
  static const String technician = '/technician';
  static const String userManagement = '/user-management';
  static const String pdfViewer = '/pdf-viewer';
  static const String profile = '/profile';
  static const String reportList = '/report-list';
  static const String statistics = '/statistics';
  static const String adminReports = '/admin-reports'; // Add this line
  static const String reportForm = '/report-form'; // ← Add this line

  // Define routes for navigator
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      admin: (context) => const AdminScreen(),
      technician: (context) => const TechnicianScreen(),
      userManagement: (context) => const UserManagementScreen(),
      statistics: (context) => const StatisticsScreen(),
      adminReports: (context) => const AdminReportsScreen(), // Add this line
      reportList: (context) => const ReportListScreen(),
      profile: (context) => const ProfileScreen(),
      reportForm: (context) => const ReportFormScreen(), // ← Add this line
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

  // Helper method to navigate to admin reports with optional filter
  static void navigateToAdminReports(BuildContext context, {String? filter}) {
    Navigator.pushNamed(context, adminReports, arguments: {'filter': filter});
  }
}
