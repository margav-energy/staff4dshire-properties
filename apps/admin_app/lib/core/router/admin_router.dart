import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart' show AuthProvider, UserRole, UserProvider, ProjectProvider;

// Auth
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/invitation_register_screen.dart';
import '../../features/auth/screens/welcome_landing_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';

// Dashboard
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/superadmin_dashboard_screen.dart';

// Users
import '../../features/users/screens/user_management_screen.dart';
import '../../features/users/screens/add_edit_user_screen.dart';
import '../../features/users/screens/user_detail_screen.dart';
import '../../features/users/screens/user_onboarding_view_screen.dart';

// Companies
import '../../features/companies/screens/companies_list_screen.dart';

// Projects
import '../../features/projects/screens/project_management_screen.dart';
import '../../features/projects/screens/add_edit_project_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';

// Invoices
import '../../features/invoices/screens/invoice_list_screen.dart';

// Jobs
import '../../features/jobs/screens/job_approval_screen.dart';

// Reports
import '../../features/reports/screens/reports_screen.dart';

// Settings
import '../../features/settings/screens/settings_screen.dart';

// Notifications
import '../../features/notifications/screens/notifications_screen.dart';

// Inductions
import '../../features/inductions/screens/induction_management_screen.dart';

// Incidents
import '../../features/incidents/screens/report_incident_screen.dart';
import '../../features/incidents/screens/incident_management_screen.dart';

// Onboarding (for viewing/managing)
import '../../features/onboarding/screens/onboarding_form_screen.dart';
import '../../features/onboarding/screens/cis_onboarding_form_screen.dart';

class AdminRouter {
  static GoRouter createRouter(AuthProvider? authProvider) {
    return GoRouter(
      // Don't set initialLocation - let GoRouter use the browser URL
      // This allows email links to work properly
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        // Get the current path and URI details
        final currentPath = state.uri.path;
        final matchedLocation = state.matchedLocation;
        final fullUri = state.uri.toString();
        final hasResetCode = state.uri.queryParameters.containsKey('code');
        
        // Check if this is the reset password route using multiple checks
        // Priority: matchedLocation > currentPath > fullUri > query params
        final isResetPasswordRoute = 
            matchedLocation == '/reset-password' ||
            matchedLocation.startsWith('/reset-password') ||
            currentPath == '/reset-password' ||
            currentPath.startsWith('/reset-password') ||
            (hasResetCode && fullUri.contains('reset-password')) ||
            (hasResetCode && matchedLocation.isEmpty && currentPath.isEmpty);
        
        // ALWAYS allow reset password route - check this FIRST before ANY other logic
        // This must be checked OUTSIDE the try-catch to ensure it always works
        if (isResetPasswordRoute) {
          return null; // Allow access to reset password without any redirects
        }
        
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final isAuthenticated = authProvider.isAuthenticated;
          final currentUser = authProvider.currentUser;
          
          final isLoginRoute = currentPath == '/login';
          final isRegisterRoute = currentPath.startsWith('/register');
          final isWelcomeRoute = currentPath == '/welcome';
          final isChangePasswordRoute = currentPath == '/change-password';
          
          // Public routes that don't require authentication
          final publicRoutes = [isLoginRoute, isRegisterRoute, isWelcomeRoute];
          
          // If not authenticated and trying to access protected routes
          if (!isAuthenticated && !publicRoutes.contains(true)) {
            // Don't redirect if path is empty or root - let it default
            if (currentPath.isEmpty || currentPath == '/') {
              return '/welcome';
            }
            return '/welcome';
          }
          
          // If authenticated, check if password change is required
          if (isAuthenticated && currentUser != null) {
            // If password change is mandatory, redirect to change password screen
            if (currentUser.mustChangePassword && !isChangePasswordRoute) {
              return '/change-password?mandatory=true';
            }
            
            // If on change password route but password change is not required, redirect to dashboard
            if (isChangePasswordRoute && !currentUser.mustChangePassword) {
              if (currentUser.isSuperadmin || currentUser.role == UserRole.superadmin) {
                return '/dashboard?role=superadmin';
              } else if (currentUser.role == UserRole.admin) {
                return '/dashboard?role=admin';
              }
            }
            
            // If authenticated and on login or welcome, redirect to dashboard
            if (isLoginRoute || isWelcomeRoute) {
              if (currentUser.isSuperadmin || currentUser.role == UserRole.superadmin) {
                return '/dashboard?role=superadmin';
              } else if (currentUser.role == UserRole.admin) {
                return '/dashboard?role=admin';
              }
              return '/dashboard?role=admin';
            }
          }
        } catch (e) {
          // Provider might not be available yet, allow navigation to proceed
          // This can happen during initial app load
        }
        
        return null; // No redirect needed
      },
      routes: [
        // Welcome/Landing Route
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeLandingScreen(),
        ),
        
        // Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final code = state.uri.queryParameters['code'];
            return ResetPasswordScreen(code: code);
          },
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) {
            final mandatory = state.uri.queryParameters['mandatory'] == 'true';
            return ChangePasswordScreen(isMandatory: mandatory);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final invitationToken = state.uri.queryParameters['token'];
            if (invitationToken != null && invitationToken.isNotEmpty) {
              return InvitationRegisterScreen(invitationToken: invitationToken);
            }
            // Admin registration is invitation-only - redirect to login with message
            return Scaffold(
              appBar: AppBar(title: const Text('Registration')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Admin Registration',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Admin accounts are created by invitation only. Please check your email for an invitation link, or contact your organization\'s superadmin.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Dashboard Routes
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final userRole = state.uri.queryParameters['role'] ?? 'admin';
            if (userRole == 'superadmin') {
              return const SuperAdminDashboardScreen();
            }
            return const AdminDashboardScreen();
          },
        ),
        
        // User Management Routes
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: '/users/add',
          builder: (context, state) => const AddEditUserScreen(),
        ),
        GoRoute(
          path: '/users/:id',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final user = userProvider.getUserById(userId);
            if (user == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('User Not Found')),
                body: const Center(child: Text('User not found')),
              );
            }
            return UserDetailScreen(user: user);
          },
        ),
        GoRoute(
          path: '/users/:id/edit',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final user = userProvider.getUserById(userId);
            return AddEditUserScreen(user: user);
          },
        ),
        GoRoute(
          path: '/users/:id/onboarding',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final user = userProvider.getUserById(userId);
            if (user == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('User Not Found')),
                body: const Center(child: Text('User not found')),
              );
            }
            return UserOnboardingViewScreen(user: user);
          },
        ),
        
        // Company Management Routes
        GoRoute(
          path: '/companies',
          builder: (context, state) => const CompaniesListScreen(),
        ),
        GoRoute(
          path: '/companies/:companyId',
          builder: (context, state) {
            final companyId = state.pathParameters['companyId']!;
            // TODO: Create CompanyDetailScreen if needed
            return const CompaniesListScreen();
          },
        ),
        
        // Project Management Routes
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectManagementScreen(),
        ),
        GoRoute(
          path: '/projects/management',
          builder: (context, state) => const ProjectManagementScreen(),
        ),
        GoRoute(
          path: '/projects/add',
          builder: (context, state) => const AddEditProjectScreen(),
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) {
            final projectId = state.pathParameters['id']!;
            return ProjectDetailScreen(projectId: projectId);
          },
        ),
        GoRoute(
          path: '/projects/:id/edit',
          builder: (context, state) {
            final projectId = state.pathParameters['id']!;
            final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
            final project = projectProvider.getProjectById(projectId);
            return AddEditProjectScreen(project: project);
          },
        ),
        
        // Invoice Routes
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoiceListScreen(),
        ),
        
        // Job Approval Routes
        GoRoute(
          path: '/jobs/approvals',
          builder: (context, state) => const JobApprovalScreen(),
        ),
        
        // Reports Routes
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        
        // Settings Routes
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        
        // Notifications Routes
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        
        // Inductions Routes
        GoRoute(
          path: '/inductions',
          builder: (context, state) => const InductionManagementScreen(),
        ),
        
        // Incident Routes
        GoRoute(
          path: '/incidents/report',
          builder: (context, state) => const ReportIncidentScreen(),
        ),
        GoRoute(
          path: '/incidents/management',
          builder: (context, state) => const IncidentManagementScreen(),
        ),
        
        // Onboarding Routes (for viewing/managing)
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingFormScreen(),
        ),
        GoRoute(
          path: '/onboarding/cis',
          builder: (context, state) => const CisOnboardingFormScreen(),
        ),
      ],
    );
  }
}

