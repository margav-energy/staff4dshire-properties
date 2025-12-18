import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/xero_provider.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/sign_in_out_screen.dart';
import '../../features/auth/screens/supervisor_project_selection_screen.dart';
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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // No redirect needed at router level - handled by individual screens
      return null;
    },
    routes: [
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

