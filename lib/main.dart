// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'utils/firebase_options.dart';
import 'app/routes.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'services/technical_visit_report_service.dart';
import 'services/user_management_service.dart';
import 'services/firebase_initialization_service.dart';
import 'services/pdf_generation_service.dart';
import 'services/statistics_service.dart';
import 'view_models/login_view_model.dart';
import 'view_models/technician_view_model.dart';
import 'view_models/admin_view_model.dart';
import 'view_models/user_management_view_model.dart';
import 'view_models/technical_visit_report_view_model.dart';
import 'view_models/statistics_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firestore collections
  final firebaseInitService = FirebaseInitializationService();
  await firebaseInitService.initializeFirestoreCollections();

  runApp(const KonyApp());
}

class KonyApp extends StatelessWidget {
  const KonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ReportService>(create: (_) => ReportService()),
        Provider<TechnicalVisitReportService>(
          create: (_) => TechnicalVisitReportService(),
        ),
        Provider<UserManagementService>(create: (_) => UserManagementService()),
        Provider<PdfGenerationService>(create: (_) => PdfGenerationService()),
        Provider<StatisticsService>(create: (_) => StatisticsService()),

        // ViewModels
        ChangeNotifierProvider<LoginViewModel>(
          create:
              (context) =>
                  LoginViewModel(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider<TechnicianViewModel>(
          create:
              (context) => TechnicianViewModel(
                reportService: context.read<ReportService>(),
                authService: context.read<AuthService>(),
              ),
        ),
        ChangeNotifierProvider<AdminViewModel>(
          create:
              (context) => AdminViewModel(
                reportService: context.read<TechnicalVisitReportService>(),
                authService: context.read<AuthService>(),
                pdfService: context.read<PdfGenerationService>(),
              ),
        ),
        ChangeNotifierProvider<UserManagementViewModel>(
          create:
              (context) => UserManagementViewModel(
                userService: context.read<UserManagementService>(),
              ),
        ),
        ChangeNotifierProvider<TechnicalVisitReportViewModel>(
          create:
              (context) => TechnicalVisitReportViewModel(
                reportService: context.read<TechnicalVisitReportService>(),
                authService: context.read<AuthService>(),
                pdfService: context.read<PdfGenerationService>(),
              ),
        ),
        ChangeNotifierProvider<StatisticsViewModel>(
          create:
              (context) => StatisticsViewModel(
                statisticsService: context.read<StatisticsService>(),
                userService: context.read<UserManagementService>(),
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Kony',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
          indicatorColor: Colors.blue,
          tabBarTheme: TabBarTheme(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.blue, width: 3.0),
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.login,
        routes: AppRoutes.getRoutes(),
      ),
    );
  }
}
