import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:intl/intl.dart';

import 'package:staff4dshire_shared/shared.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/live_jobs_section.dart';
import '../widgets/invoice_jobs_section.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load all data when screen opens with company filtering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        // Load with company filtering (loadUsers clears data immediately when userId is provided)
        userProvider.loadUsers(userId: userId);
        projectProvider.loadProjects(userId: userId);
        companyProvider.loadCompanies(userId: userId);
        notificationProvider.refreshNotifications(userId);
        
        // Initialize ChatProvider to show badges
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.initialize(userId);
        
        // Load job completions for pending approvals
        final jobCompletionProvider = Provider.of<JobCompletionProvider>(context, listen: false);
        jobCompletionProvider.loadCompletions();
        
        // Load invoices
        final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
        invoiceProvider.loadInvoices();
        
        // Load incidents - ensure they're loaded from API
        final incidentProvider = Provider.of<IncidentProvider>(context, listen: false);
        await incidentProvider.initialize();
      }
      documentProvider.loadDocuments();
      // Timesheet data is already loaded
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
                        decoration: const BoxDecoration(
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
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
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
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  await authProvider.logout(userProvider: userProvider);
                  
                  if (mounted) {
                    // Clear navigation stack and go to login page
                    context.go('/login');
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
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userId = authProvider.currentUser?.id;
          return RefreshIndicator(
            onRefresh: () async {
              // Reload all data with company filtering
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
              final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
              final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
              final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
              
              if (userId != null) {
                await Future.wait([
                  userProvider.loadUsers(userId: userId),
                  projectProvider.loadProjects(userId: userId),
                  companyProvider.loadCompanies(userId: userId),
                  notificationProvider.refreshNotifications(userId),
                ]);
              }
              documentProvider.loadDocuments();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner with Name, Date, and Time
                  const WelcomeBanner(),
                  
                  // Statistics Overview
                  Consumer4<UserProvider, ProjectProvider, TimesheetProvider, DocumentProvider>(
              builder: (context, userProvider, projectProvider, timesheetProvider, documentProvider, child) {
                // Calculate statistics from real data
                final totalStaff = userProvider.totalUsersCount;
                final activeProjects = projectProvider.projects.length;
                
                final weekHours = timesheetProvider.getTotalHoursForWeek();
                final hours = weekHours.inHours;
                final minutes = weekHours.inMinutes.remainder(60);
                final weekHoursFormatted = minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
                
                // Calculate compliance percentage (documents not expired)
                final totalDocs = documentProvider.documents.length;
                final expiredDocs = documentProvider.getExpiredDocuments().length;
                final compliancePercentage = totalDocs > 0 
                    ? ((totalDocs - expiredDocs) / totalDocs * 100).round()
                    : 100;
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Staff',
                            value: totalStaff.toString(),
                            icon: Icons.people,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Projects',
                            value: activeProjects.toString(),
                            icon: Icons.location_on,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'This Week',
                            value: weekHoursFormatted,
                            icon: Icons.access_time,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Compliance',
                            value: '$compliancePercentage%',
                            icon: Icons.verified_user,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _AdminActionCard(
                  icon: Icons.report,
                  label: 'Attendance Reports',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    context.push('/reports');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.file_download,
                  label: 'Export Timesheets',
                  color: Colors.green,
                  onTap: () {
                    context.push('/timesheet/export');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.school,
                  label: 'Induction Management',
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    context.push('/inductions');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.people,
                  label: 'User Management',
                  color: Colors.blue,
                  onTap: () {
                    context.push('/users');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.location_on,
                  label: 'Project Management',
                  color: Colors.orange,
                  onTap: () {
                    context.push('/projects/management');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.settings,
                  label: 'Settings',
                  color: Colors.grey,
                  onTap: () {
                    context.push('/settings');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.report_problem,
                  label: 'Report Incident',
                  color: Colors.red,
                  onTap: () {
                    context.push('/incidents/report');
                  },
                ),
                _AdminActionCard(
                  icon: Icons.manage_search,
                  label: 'Manage Incidents',
                  color: Colors.deepOrange,
                  onTap: () {
                    context.push('/incidents/management');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Jobs Section
            const LiveJobsSection(),

            const SizedBox(height: 24),

            // Invoice Jobs Section
            const InvoiceJobsSection(),

            const SizedBox(height: 24),

            // Recent Activity & Alerts
            Consumer4<DocumentProvider, TimesheetProvider, NotificationProvider, IncidentProvider>(
              builder: (context, documentProvider, timesheetProvider, notificationProvider, incidentProvider, child) {
                final expiringDocs = documentProvider.getExpiringDocuments();
                final expiredDocs = documentProvider.getExpiredDocuments();
                final pendingApprovals = timesheetProvider.getPendingApprovals();
                final pendingIncidents = incidentProvider.getPendingIncidents();
                
                // Combine recent notifications and incidents for activity
                final allActivities = <_CombinedActivity>[];
                
                // Add recent notifications
                for (var notification in notificationProvider.notifications.take(5)) {
                  allActivities.add(_CombinedActivity(
                    type: 'notification',
                    title: notification.title,
                    time: notification.timestamp,
                  ));
                }
                
                // Add recent incidents
                for (var incident in incidentProvider.incidents.take(5)) {
                  allActivities.add(_CombinedActivity(
                    type: 'incident',
                    title: 'Incident: ${incident.description.length > 30 ? incident.description.substring(0, 30) + "..." : incident.description}',
                    time: incident.reportedAt,
                  ));
                }
                
                // Sort by time and take most recent
                allActivities.sort((a, b) => b.time.compareTo(a.time));
                final recentActivities = allActivities.take(3).toList();
                
                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerts',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (expiringDocs.isNotEmpty)
                                _AlertItem(
                                  icon: Icons.warning,
                                  message: '${expiringDocs.length} Document${expiringDocs.length != 1 ? 's' : ''} Expiring',
                                  color: Colors.orange,
                                ),
                              if (expiringDocs.isNotEmpty && expiredDocs.isNotEmpty)
                                const SizedBox(height: 12),
                              if (expiredDocs.isNotEmpty)
                                _AlertItem(
                                  icon: Icons.error,
                                  message: '${expiredDocs.length} Document${expiredDocs.length != 1 ? 's' : ''} Expired',
                                  color: Colors.red,
                                ),
                              if (expiredDocs.isNotEmpty && pendingApprovals.isNotEmpty)
                                const SizedBox(height: 12),
                              if (pendingApprovals.isNotEmpty)
                                _AlertItem(
                                  icon: Icons.info,
                                  message: '${pendingApprovals.length} Pending Approval${pendingApprovals.length != 1 ? 's' : ''}',
                                  color: Colors.blue,
                                ),
                              if (pendingIncidents.isNotEmpty) ...[
                                if (expiringDocs.isNotEmpty || expiredDocs.isNotEmpty || pendingApprovals.isNotEmpty)
                                  const SizedBox(height: 12),
                                _AlertItem(
                                  icon: Icons.report_problem,
                                  message: '${pendingIncidents.length} Active Incident${pendingIncidents.length != 1 ? 's' : ''}',
                                  color: Colors.red,
                                ),
                              ],
                              if (expiringDocs.isEmpty && expiredDocs.isEmpty && pendingApprovals.isEmpty && pendingIncidents.isEmpty)
                                Text(
                                  'No alerts',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Activity',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (recentActivities.isNotEmpty)
                                ...recentActivities.map((activity) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ActivityItem(
                                      title: activity.title,
                                      time: _formatTimeAgo(activity.time),
                                    ),
                                  );
                                }).toList()
                              else
                                Text(
                                  'No recent activity',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Top Projects
            Consumer2<TimesheetProvider, ProjectProvider>(
              builder: (context, timesheetProvider, projectProvider, child) {
                // Get current week entries
                final weekEntries = timesheetProvider.getCurrentWeekEntries();
                
                // Group entries by project and calculate hours
                final projectStats = <String, Map<String, dynamic>>{};
                
                for (var entry in weekEntries) {
                  if (entry.signOutTime != null) {
                    final projectId = entry.projectId;
                    final projectName = entry.projectName;
                    final duration = entry.duration;
                    final hours = duration.inHours + (duration.inMinutes / 60.0);
                    
                    if (!projectStats.containsKey(projectId)) {
                      projectStats[projectId] = {
                        'name': projectName,
                        'hours': 0.0,
                        'staffCount': <String>{},
                      };
                    }
                    
                    projectStats[projectId]!['hours'] = 
                        (projectStats[projectId]!['hours'] as double) + hours;
                    (projectStats[projectId]!['staffCount'] as Set<String>).add(entry.staffId);
                  }
                }
                
                // Sort by hours and take top 5
                final sortedProjects = projectStats.entries.toList()
                  ..sort((a, b) => (b.value['hours'] as double).compareTo(a.value['hours'] as double));
                
                final topProjectsEntries = sortedProjects.take(5).toList();
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Projects This Week',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (topProjectsEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No project data for this week',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                        else
                          ...topProjectsEntries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final projectMapEntry = entry.value; // MapEntry<String, Map<String, dynamic>>
                            final projectData = projectMapEntry.value as Map<String, dynamic>; // Explicitly cast to Map
                            final projectName = projectData['name'] as String;
                            final hours = projectData['hours'] as double;
                            final staffCount = (projectData['staffCount'] as Set<String>).length;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          projectName,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        Text(
                                          '${hours.toStringAsFixed(1)}h this week',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$staffCount',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.people, size: 16, color: Colors.grey),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
            ),
          ),
        );
      },
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final currentPath = GoRouterState.of(context).uri.path;
          return BottomNavBar(currentPath: currentPath);
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}

class _CombinedActivity {
  final String type;
  final String title;
  final DateTime time;

  _CombinedActivity({
    required this.type,
    required this.title,
    required this.time,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _AlertItem({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;

  const _ActivityItem({
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

