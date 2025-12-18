import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/timesheet_provider.dart';
import 'core/providers/document_provider.dart';
import 'core/providers/project_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/xero_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/incident_provider.dart';
import 'core/providers/job_completion_provider.dart';
import 'core/providers/invoice_provider.dart';
import 'core/providers/onboarding_provider.dart';
import 'core/providers/company_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const Staff4dshireApp());
}

class Staff4dshireApp extends StatelessWidget {
  const Staff4dshireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => TimesheetProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(
          create: (_) => ProjectProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => XeroProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => IncidentProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobCompletionProvider()..loadCompletions(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider()..loadInvoices(),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CompanyProvider(),
        ),
      ],
      child: _AppInitializer(
        child: MaterialApp.router(
          title: 'Staff4dshire Properties',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  final Widget child;
  
  const _AppInitializer({required this.child});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      // Ensure UserProvider is initialized first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initialize();
      
      // Wait a bit more for UserProvider to fully load users
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Now initialize AuthProvider with UserProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize(userProvider: userProvider);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized ? widget.child : const SizedBox.shrink();
  }
}

