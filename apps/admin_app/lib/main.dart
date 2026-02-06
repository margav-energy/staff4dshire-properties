import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// Shared package
import 'package:staff4dshire_shared/shared.dart';

// Admin router
import 'core/router/admin_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use hash-based routing for static hosting compatibility
  usePathUrlStrategy();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = UserProvider()..initialize();
    final authProvider = AuthProvider()..initialize(userProvider: userProvider);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => JobCompletionProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TimesheetProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => XeroProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: _AdminAppInitializer(
        child: Listener(
          onPointerDown: (_) {
            // Prime audio on first user interaction (especially needed on web).
            NotificationSoundPlayer.prime();
          },
          child: MaterialApp.router(
            title: 'Staff4dshire Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            routerConfig: AdminRouter.createRouter(authProvider),
          ),
        ),
      ),
    );
  }
}

class _AdminAppInitializer extends StatefulWidget {
  final Widget child;
  const _AdminAppInitializer({required this.child});

  @override
  State<_AdminAppInitializer> createState() => _AdminAppInitializerState();
}

class _AdminAppInitializerState extends State<_AdminAppInitializer> {
  String? _initializedForUserId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    final userId = authProvider.currentUser?.id;
    if (userId != null && userId.isNotEmpty && _initializedForUserId != userId) {
      _initializedForUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatProvider.initialize(userId);
        notificationProvider.refreshNotifications(userId);
      });
    }

    return widget.child;
  }
}

