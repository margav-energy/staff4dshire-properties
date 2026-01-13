import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Shared package
import 'package:staff4dshire_shared/shared.dart';

// Staff router
import 'core/router/staff_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const StaffApp());
}

class StaffApp extends StatelessWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize providers outside MultiProvider to ensure consistent instances
    final authProvider = AuthProvider();
    final userProvider = UserProvider();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => TimesheetProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => XeroProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => JobCompletionProvider()..loadCompletions()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()..loadInvoices()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: _AppInitializer(
        authProvider: authProvider,
        userProvider: userProvider,
        child: Listener(
          onPointerDown: (_) {
            // Prime audio on first user interaction (especially needed on web).
            NotificationSoundPlayer.prime();
          },
          child: MaterialApp.router(
            title: 'Staff4dshire Properties',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            routerConfig: StaffRouter.createRouter(authProvider),
          ),
        ),
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  final Widget child;
  final AuthProvider authProvider;
  final UserProvider userProvider;
  
  const _AppInitializer({
    required this.child,
    required this.authProvider,
    required this.userProvider,
  });

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isInitialized = false;
  String? _initializedForUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      // Wait a bit more for UserProvider to fully load users
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Initialize AuthProvider with UserProvider
      await widget.authProvider.initialize(userProvider: widget.userProvider);

      // Initialize chat + notifications globally once we know the user
      final userId = widget.authProvider.currentUser?.id;
      if (userId != null && userId.isNotEmpty && _initializedForUserId != userId && mounted) {
        _initializedForUserId = userId;
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await chatProvider.initialize(userId);
        await notificationProvider.initialize(userId: userId);
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return widget.child;
    }
    
    // Show loading screen wrapped in MaterialApp to provide Directionality
    return MaterialApp(
      title: 'Staff4dshire Properties',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
