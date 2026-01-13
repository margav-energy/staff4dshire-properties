import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:staff4dshire_shared/shared.dart';
import '../../timesheet/screens/timesheet_screen.dart';
import '../../documents/screens/document_hub_screen.dart';
import '../../auth/screens/sign_in_out_screen.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/available_jobs_section.dart';
import '../widgets/live_jobs_section.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Refresh user photo from UserProvider when dashboard loads
    // Also load projects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserPhoto();
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      // Load projects filtered by company_id
      projectProvider.loadProjects(userId: userId);
      if (userId != null) {
        companyProvider.loadCompanies(userId: userId);
        // Load notifications for the current user
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.refreshNotifications(userId);
        
        // Initialize ChatProvider to show badges
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.initialize(userId);
      }
    });
  }

  Future<void> _refreshUserPhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      // Load users first to ensure UserModel is available
      await userProvider.loadUsers(userId: userId);
      // Then refresh current user to get updated photo
      await authProvider.refreshCurrentUser(userProvider: userProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    final totalHours = timesheetProvider.getTotalHoursForWeek();
    final hours = totalHours.inHours;
    final minutes = totalHours.inMinutes.remainder(60);

    final expiringDocs = documentProvider.getExpiringDocuments();
    final expiredDocs = documentProvider.getExpiredDocuments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer2<NotificationProvider, AuthProvider>(
            builder: (context, notificationProvider, authProvider, child) {
              final currentUserId = authProvider.currentUser?.id;
              final unreadCount = notificationProvider.getUnreadCountForUser(currentUserId);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  
                  if (mounted) {
                    // Clear navigation stack and go to login
                    context.go('/login');
                  }
                }
              } catch (e) {
                debugPrint('Error during logout: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error during logout: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner with Name, Date, and Time (includes company badge)
                  const WelcomeBanner(),
                  
                  // Sign-In Status Card (if signed in)
                  if (timesheetProvider.hasActiveSignIn && timesheetProvider.activeEntry != null)
                    Card(
                      color: Colors.green.shade600,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'SIGNED IN',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          timesheetProvider.activeEntry!.projectName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  StreamBuilder<DateTime>(
                                    stream: Stream.periodic(
                                      const Duration(seconds: 1),
                                      (_) => DateTime.now(),
                                    ),
                                    builder: (context, snapshot) {
                                      final now = snapshot.data ?? DateTime.now();
                                      final duration = now.difference(timesheetProvider.activeEntry!.signInTime);
                                      final hours = duration.inHours;
                                      final minutes = duration.inMinutes.remainder(60);
                                      
                                      return Text(
                                        'Time on site: ${hours}h ${minutes}m',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.login,
                          label: 'Sign In/Out',
                          color: theme.colorScheme.primary,
                          onTap: () => context.push('/sign-in-out'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.description,
                          label: 'Timesheet',
                          color: theme.colorScheme.secondary,
                          onTap: () => context.push('/timesheet'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.folder,
                          label: 'Documents',
                          color: theme.colorScheme.secondary,
                          onTap: () => context.push('/documents'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.report_problem,
                          label: 'Report Incident',
                          color: Colors.red,
                          onTap: () => context.push('/incidents/report'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Weekly Hours Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'This Week',
                                style: theme.textTheme.titleLarge,
                              ),
                              Icon(
                                Icons.access_time,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${hours}h ${minutes}m',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total hours worked',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Jobs Available Section (assigned but not started)
                  const AvailableJobsSection(),

                  const SizedBox(height: 24),

                  // Live Jobs Section (jobs in progress)
                  const LiveJobsSection(),

                  const SizedBox(height: 24),

                  // Document Alerts
                  if (expiredDocs.isNotEmpty || expiringDocs.isNotEmpty) ...[
                    Card(
                      color: expiredDocs.isNotEmpty ? Colors.red.shade50 : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              expiredDocs.isNotEmpty
                                  ? Icons.error_outline
                                  : Icons.warning_amber_rounded,
                              color: expiredDocs.isNotEmpty ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expiredDocs.isNotEmpty
                                        ? '${expiredDocs.length} Document(s) Expired'
                                        : '${expiringDocs.length} Document(s) Expiring Soon',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: expiredDocs.isNotEmpty ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Review in Documents',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => context.push('/documents'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Consumer<IncidentProvider>(
                    builder: (context, incidentProvider, child) {
                      // Combine timesheet entries and incidents
                      final allActivities = <_ActivityItem>[];
                      
                      // Add timesheet entries
                      for (var entry in timesheetProvider.getCurrentWeekEntries()) {
                        allActivities.add(_ActivityItem(
                          type: _ActivityType.timesheet,
                          title: entry.projectName,
                          subtitle: '${DateFormat('MMM dd').format(entry.signInTime)} • ${entry.duration.inHours}h ${entry.duration.inMinutes.remainder(60)}m',
                          timestamp: entry.signInTime,
                          icon: Icons.location_on,
                          color: theme.colorScheme.primary,
                        ));
                      }
                      
                      // Add incidents reported by this user
                      final userIncidents = incidentProvider.getReportedByUser(
                        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? ''
                      );
                      for (var incident in userIncidents) {
                        allActivities.add(_ActivityItem(
                          type: _ActivityType.incident,
                          title: 'Incident reported: ${incident.description.length > 30 ? incident.description.substring(0, 30) + "..." : incident.description}',
                          subtitle: 'Severity: ${_getSeverityLabel(incident.severity)} • ${DateFormat('MMM dd, HH:mm').format(incident.reportedAt)}',
                          timestamp: incident.reportedAt,
                          icon: Icons.report_problem,
                          color: _getSeverityColor(incident.severity),
                        ));
                      }
                      
                      // Sort by timestamp (most recent first) and take 5
                      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      
                      if (allActivities.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No recent activity',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: allActivities.take(5).map((activity) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: activity.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  activity.icon,
                                  color: activity.color,
                                ),
                              ),
                              title: Text(activity.title),
                              subtitle: Text(activity.subtitle),
                              trailing: Icon(
                                activity.type == _ActivityType.timesheet
                                    ? Icons.check_circle
                                    : Icons.report_problem,
                                color: activity.color,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            )
          : _selectedIndex == 1
              ? const SignInOutScreen()
              : _selectedIndex == 2
                  ? const TimesheetScreen()
                  : const DocumentHubScreen(),
      bottomNavigationBar: Builder(
        builder: (context) {
          final currentPath = GoRouterState.of(context).uri.path;
          return BottomNavBar(currentPath: currentPath);
        },
      ),
    );
  }

  String _getSeverityLabel(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.green;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.red;
      case IncidentSeverity.critical:
        return Colors.deepPurple;
    }
  }

}

enum _ActivityType {
  timesheet,
  incident,
}

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

