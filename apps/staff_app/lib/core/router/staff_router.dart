import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/sign_in_out_screen.dart';
import '../../features/auth/screens/supervisor_project_selection_screen.dart';
import '../../features/auth/screens/welcome_landing_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/dashboard/screens/staff_dashboard_screen.dart';
import '../../features/dashboard/screens/supervisor_dashboard_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/superadmin_dashboard_screen.dart';
import '../../features/timesheet/screens/timesheet_screen.dart';
import '../../features/timesheet/screens/timesheet_export_screen.dart';
import '../../features/timesheet/screens/timesheet_edit_screen.dart';
import '../../features/documents/screens/document_hub_screen.dart';
import '../../features/compliance/screens/fit_to_work_screen.dart';
import '../../features/compliance/screens/rams_screen.dart';
import '../../features/compliance/screens/toolbox_talk_screen.dart';
import '../../features/compliance/screens/fire_roll_call_screen.dart';
import '../../features/projects/screens/project_selection_screen.dart';
import '../../features/projects/screens/project_management_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/inductions/screens/induction_management_screen.dart';
import '../../features/users/screens/user_management_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/integrations/screens/xero_integration_screen.dart';
import '../../features/incidents/screens/report_incident_screen.dart';
import '../../features/incidents/screens/incident_management_screen.dart';
import '../../features/jobs/screens/job_approval_screen.dart';
import '../../features/invoices/screens/invoice_list_screen.dart';
import '../../features/onboarding/screens/onboarding_form_screen.dart';
import '../../features/onboarding/screens/cis_onboarding_form_screen.dart';
import '../../features/companies/screens/companies_list_screen.dart';
import '../../features/auth/screens/invitation_register_screen.dart';

class StaffRouter {
  static GoRouter createRouter(AuthProvider? authProvider) {
    return GoRouter(
      useHash: true, // Use hash-based routing for static hosting compatibility
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
          final isOnboardingRoute = currentPath == '/onboarding' || currentPath.startsWith('/onboarding/');
          
          // Public routes that don't require authentication
          final publicRoutes = [isLoginRoute, isRegisterRoute, isWelcomeRoute, isResetPasswordRoute];
          
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
            // Allow onboarding routes - don't redirect them (users need to complete onboarding)
            if (isOnboardingRoute) {
              return null; // Allow access to onboarding
            }
            
            // If password change is mandatory, redirect to change password screen
            if (currentUser.mustChangePassword && !isChangePasswordRoute) {
              return '/change-password?mandatory=true';
            }
            
            // If authenticated and on login, redirect to dashboard
            // NOTE: Don't redirect from /register - let registration screen handle navigation to onboarding
            if (isLoginRoute) {
              // Redirect to appropriate dashboard based on role
              if (currentUser.isSuperadmin || currentUser.role == UserRole.superadmin) {
                return '/dashboard?role=superadmin';
              } else if (currentUser.role == UserRole.admin) {
                return '/dashboard?role=admin';
              } else if (currentUser.role == UserRole.supervisor) {
                return '/dashboard?role=supervisor';
              } else {
                return '/dashboard?role=staff';
              }
            }
          }
        } catch (e) {
          // Provider might not be available yet, allow navigation to proceed
        }
        
        return null; // No redirect needed
      },
      // Don't set initialLocation - let GoRouter use the browser URL
      // This allows email links to work properly
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeLandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          // Check if there's an invitation token in query params
          final invitationToken = state.uri.queryParameters['token'];
          if (invitationToken != null && invitationToken.isNotEmpty) {
            return InvitationRegisterScreen(invitationToken: invitationToken);
          }
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) {
          final isMandatory = state.uri.queryParameters['mandatory'] == 'true';
          return ChangePasswordScreen(isMandatory: isMandatory);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return ResetPasswordScreen(code: code);
        },
      ),
      GoRoute(
        path: '/sign-in-out',
        builder: (context, state) => const SignInOutScreen(),
      ),
      GoRoute(
        path: '/supervisor/project-selection',
        builder: (context, state) => const SupervisorProjectSelectionScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          // Get actual user role from AuthProvider instead of query parameter
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final currentUser = authProvider.currentUser;
            if (currentUser != null) {
              if (currentUser.isSuperadmin || currentUser.role == UserRole.superadmin) {
                return const SuperAdminDashboardScreen();
              } else if (currentUser.role == UserRole.admin) {
                return const AdminDashboardScreen();
              } else if (currentUser.role == UserRole.supervisor) {
                return const SupervisorDashboardScreen();
              } else {
                return const StaffDashboardScreen();
              }
            }
          } catch (e) {
            // Fallback to query parameter if provider not available
          }
          // Fallback to query parameter
          final userRole = state.uri.queryParameters['role'] ?? 'staff';
          switch (userRole) {
            case 'superadmin':
              return const SuperAdminDashboardScreen();
            case 'admin':
              return const AdminDashboardScreen();
            case 'supervisor':
              return const SupervisorDashboardScreen();
            default:
              return const StaffDashboardScreen();
          }
        },
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectSelectionScreen(),
      ),
      GoRoute(
        path: '/projects/management',
        builder: (context, state) => const ProjectManagementScreen(),
      ),
      GoRoute(
        path: '/projects/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/timesheet',
        builder: (context, state) => const TimesheetScreen(),
      ),
      GoRoute(
        path: '/timesheet/export',
        builder: (context, state) => const TimesheetExportScreen(),
      ),
      GoRoute(
        path: '/timesheet/edit',
        builder: (context, state) => const TimesheetEditScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentHubScreen(),
      ),
      GoRoute(
        path: '/compliance/fit-to-work',
        builder: (context, state) => const FitToWorkScreen(),
      ),
      GoRoute(
        path: '/compliance/rams',
        builder: (context, state) => const RamsScreen(),
      ),
      GoRoute(
        path: '/compliance/toolbox-talk',
        builder: (context, state) => const ToolboxTalkScreen(),
      ),
      GoRoute(
        path: '/compliance/fire-roll-call',
        builder: (context, state) => const FireRollCallScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/inductions',
        builder: (context, state) => const InductionManagementScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/integrations/xero',
        builder: (context, state) => const XeroIntegrationScreen(),
      ),
      GoRoute(
        path: '/incidents/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/incidents/management',
        builder: (context, state) => const IncidentManagementScreen(),
      ),
      GoRoute(
        path: '/jobs/approvals',
        builder: (context, state) => const JobApprovalScreen(),
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFormScreen(),
      ),
      GoRoute(
        path: '/onboarding/cis',
        builder: (context, state) => const CisOnboardingFormScreen(),
      ),
      GoRoute(
        path: '/companies',
        builder: (context, state) => const CompaniesListScreen(),
      ),
      GoRoute(
        path: '/xero/callback',
        builder: (context, state) {
          // Handle OAuth callback
          final code = state.uri.queryParameters['code'];
          final stateParam = state.uri.queryParameters['state'];
          
          if (code != null && stateParam != null) {
            // Handle callback asynchronously
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final xeroProvider = Provider.of<XeroProvider>(
                context,
                listen: false,
              );
              await xeroProvider.handleOAuthCallback(code, stateParam);
              
              // Navigate back to Xero integration screen after successful connection
              if (context.mounted && xeroProvider.isConnected) {
                context.go('/integrations/xero');
              } else if (context.mounted) {
                context.go('/settings');
              }
            });
          } else {
            // No code received, go back to settings
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/settings');
              }
            });
          }
          
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Connecting to Xero...'),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/settings'),
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

