import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:staff4dshire_shared/shared.dart';
import '../../timesheet/screens/timesheet_entry_detail_screen.dart';
import '../../projects/screens/project_selection_screen.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/live_jobs_section.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _pendingApprovalsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      // Load projects filtered by company_id
      projectProvider.loadProjects(userId: userId);
      if (userId != null) {
        companyProvider.loadCompanies(userId: userId);
        // Load notifications for the current user
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.refreshNotifications(userId);
      }
    });
  }

  void _scrollToPendingApprovals() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingApprovalsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _pendingApprovalsKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _selectProject() async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(builder: (context) => const ProjectSelectionScreen()),
    );

    if (result != null && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Update user with assigned project
      authProvider.setAssignedProject(result.id, result.name);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${result.name}" selected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _clearProject() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setAssignedProject(null, null);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Returned to main dashboard'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _approveSingleEntry(
    BuildContext context,
    TimeEntry entry,
    TimesheetProvider timesheetProvider,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final approverName = authProvider.currentUser?.name ?? 'Supervisor';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Timesheet'),
        content: Text(
          'Approve timesheet entry for ${entry.staffName}?\n\n'
          'Date: ${DateFormat('MMM dd, yyyy').format(entry.signInTime)}\n'
          'Project: ${entry.projectName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await timesheetProvider.approveEntry(entry.id, approverName);

        // Create notification for the staff member
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.addNotification(
          title: 'Timesheet Approved',
          message: 'Your timesheet entry for ${entry.projectName} on ${DateFormat('MMM dd, yyyy').format(entry.signInTime)} has been approved.',
          type: NotificationType.success,
          relatedEntityId: entry.id,
          relatedEntityType: 'timesheet',
          targetUserId: entry.staffId, // Target the staff member who owns this timesheet
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timesheet entry approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error approving entry: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveAllEntries(
    BuildContext context,
    List<TimeEntry> entries,
    TimesheetProvider timesheetProvider,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final approverName = authProvider.currentUser?.name ?? 'Supervisor';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Timesheets'),
        content: Text(
          'Approve ${entries.length} timesheet entries for ${entries.first.staffName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        for (var entry in entries) {
          await timesheetProvider.approveEntry(entry.id, approverName);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Approved ${entries.length} timesheet entries'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error approving entries: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewStaffTimesheet(
    BuildContext context,
    List<TimeEntry> entries,
    String staffName,
  ) {
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final bottomSheetTheme = Theme.of(context);
          
          return Scaffold(
            appBar: AppBar(
              title: Text('Timesheets - $staffName'),
            ),
            body: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final duration = entry.duration;
                final hours = duration.inHours;
                final minutes = duration.inMinutes.remainder(60);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimesheetEntryDetailScreen(entry: entry),
                        ),
                      );
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bottomSheetTheme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(entry.signInTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: bottomSheetTheme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(entry.signInTime),
                            style: TextStyle(
                              fontSize: 10,
                              color: bottomSheetTheme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(entry.projectName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('HH:mm').format(entry.signInTime)} - ${entry.signOutTime != null ? DateFormat('HH:mm').format(entry.signOutTime!) : 'In Progress'}',
                        ),
                        Text(
                          '${hours}h ${minutes}m',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: bottomSheetTheme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: bottomSheetTheme.colorScheme.secondary,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    
    // Check if supervisor has assigned project
    final supervisorProjectId = authProvider.currentUser?.assignedProjectId;
    final supervisorProjectName = authProvider.currentUser?.assignedProjectName;
    
    // Filter pending approvals by assigned project (only if project is selected)
    final allPendingApprovals = timesheetProvider.getPendingApprovals();
    final pendingApprovals = supervisorProjectId != null
        ? allPendingApprovals
            .where((entry) => entry.projectId == supervisorProjectId)
            .toList()
        : <TimeEntry>[];
    
    // Sort by sign-in time (most recent first)
    final sortedApprovals = List<TimeEntry>.from(pendingApprovals)
      ..sort((a, b) => b.signInTime.compareTo(a.signInTime));
    
    // Count active staff on site - all projects on main dashboard, specific project when selected
    final activeStaffCount = supervisorProjectId != null
        ? timesheetProvider.entries
            .where((entry) => 
                entry.projectId == supervisorProjectId && 
                entry.signOutTime == null)
            .length
        : timesheetProvider.entries
            .where((entry) => entry.signOutTime == null)
            .length; // Show all active staff on main dashboard

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
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
                  await authProvider.logout();
                  
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
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner with Name, Date, and Time
            const WelcomeBanner(),
            // Main Dashboard Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  supervisorProjectId != null ? 'Project Dashboard' : 'Main Dashboard',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (supervisorProjectId != null)
                  TextButton.icon(
                    onPressed: () {
                      _clearProject();
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Main Dashboard'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Project Selection/Info Card
            if (supervisorProjectId == null || supervisorProjectName == null)
              Center(
                child: Card(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  child: InkWell(
                    onTap: _selectProject,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_location,
                            color: theme.colorScheme.primary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select Project',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Click to view project-specific dashboard',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Card(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Project',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  supervisorProjectName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Change Project',
                                onPressed: _selectProject,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Clear Project',
                                onPressed: _clearProject,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/projects/${supervisorProjectId}');
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Project Details & Progress'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Overview Cards - different for main dashboard vs project view
            if (supervisorProjectId == null) ...[
              // Main Dashboard Overview
              Card(
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Headcount',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$activeStaffCount',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Staff across all projects',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Project-Specific Live Headcount Card
              Card(
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Headcount',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$activeStaffCount',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Currently on site',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/compliance/fire-roll-call');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Fire Roll Call'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],

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
              childAspectRatio: 1.2,
              children: [
                _SupervisorActionCard(
                  icon: Icons.people_outline,
                  label: supervisorProjectId != null ? 'View Headcount' : 'View All Headcount',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(supervisorProjectId != null
                            ? 'Live Headcount: $activeStaffCount staff on site'
                            : 'Total Live Headcount: $activeStaffCount staff across all projects'),
                      ),
                    );
                  },
                ),
                _SupervisorActionCard(
                  icon: Icons.approval,
                  label: 'Approve Times',
                  color: Colors.green,
                  onTap: () {
                    if (supervisorProjectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a project to view pending approvals'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      _scrollToPendingApprovals();
                    }
                  },
                ),
                _SupervisorActionCard(
                  icon: Icons.edit,
                  label: 'Edit Times',
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    context.push('/timesheet/edit');
                  },
                ),
                _SupervisorActionCard(
                  icon: Icons.report,
                  label: 'Reports',
                  color: Colors.orange,
                  onTap: () {
                    context.push('/reports');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SupervisorActionCard(
                    icon: Icons.report_problem,
                    label: 'Report Incident',
                    color: Colors.red,
                    onTap: () {
                      context.push('/incidents/report');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SupervisorActionCard(
                    icon: Icons.manage_search,
                    label: 'Manage Incidents',
                    color: Colors.deepOrange,
                    onTap: () {
                      context.push('/incidents/management');
                    },
                  ),
                ),
              ],
            ),

            // Pending Approvals (only show when project is selected)
            if (supervisorProjectId != null) ...[
              const SizedBox(height: 24),
              Card(
                key: _pendingApprovalsKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending Approvals',
                            style: theme.textTheme.titleLarge,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${pendingApprovals.length}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (pendingApprovals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No pending approvals',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...sortedApprovals.take(10).map((entry) {
                        final duration = entry.duration;
                        final hours = duration.inHours;
                        final minutes = duration.inMinutes.remainder(60);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.orange.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              entry.staffName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.projectName),
                                Text(
                                  '${DateFormat('MMM dd, yyyy').format(entry.signInTime)} • ${DateFormat('HH:mm').format(entry.signInTime)} - ${entry.signOutTime != null ? DateFormat('HH:mm').format(entry.signOutTime!) : 'In Progress'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (entry.signOutTime != null)
                                  Text(
                                    '${hours}h ${minutes}m',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _approveSingleEntry(
                                    context,
                                    entry,
                                    timesheetProvider,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: const Text('Approve'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20),
                                  tooltip: 'View Details',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TimesheetEntryDetailScreen(entry: entry),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            ],

            const SizedBox(height: 24),

            // Live Jobs Section
            const LiveJobsSection(),

            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Consumer<IncidentProvider>(
              builder: (context, incidentProvider, child) {
                return Builder(
                  builder: (context) {
                    // Combine timesheet entries and incidents
                    final allActivities = <_SupervisorActivityItem>[];
                    
                    // Get recent entries - show all entries on main dashboard, filtered by project when project is selected
                    final recentEntries = supervisorProjectId != null
                        ? timesheetProvider.entries
                            .where((entry) => entry.projectId == supervisorProjectId)
                            .toList()
                        : timesheetProvider.entries.toList(); // Show all entries on main dashboard
                    
                    for (var entry in recentEntries) {
                      allActivities.add(_SupervisorActivityItem(
                        type: 'timesheet',
                        title: entry.signOutTime == null
                            ? '${entry.staffName} signed in'
                            : '${entry.staffName} signed out',
                        subtitle: '${entry.projectName} • ${DateFormat('MMM dd, HH:mm').format(
                          entry.signOutTime == null ? entry.signInTime : entry.signOutTime!,
                        )}',
                        timestamp: entry.signOutTime ?? entry.signInTime,
                        icon: entry.signOutTime == null ? Icons.login : Icons.logout,
                        color: entry.signOutTime == null ? Colors.green : Colors.blue,
                      ));
                    }
                    
                    // Add recent incidents - show all incidents on main dashboard, filtered by project when project is selected
                    for (var incident in incidentProvider.incidents) {
                      if (supervisorProjectId != null) {
                        // When project is selected, show only incidents for that project or unassigned incidents
                        final matchesProject = incident.projectId == supervisorProjectId;
                        final isUnassigned = incident.projectId == null || incident.projectId!.isEmpty;
                        
                        if (matchesProject || isUnassigned) {
                          allActivities.add(_SupervisorActivityItem(
                            type: 'incident',
                            title: 'Incident: ${incident.description.length > 25 ? incident.description.substring(0, 25) + "..." : incident.description}',
                            subtitle: '${incident.projectName ?? "Unassigned"} • ${_getSeverityLabel(incident.severity)} • ${DateFormat('MMM dd, HH:mm').format(incident.reportedAt)}',
                            timestamp: incident.reportedAt,
                            icon: Icons.report_problem,
                            color: _getSeverityColor(incident.severity),
                          ));
                        }
                      } else {
                        // On main dashboard, show all incidents
                        allActivities.add(_SupervisorActivityItem(
                          type: 'incident',
                          title: 'Incident: ${incident.description.length > 25 ? incident.description.substring(0, 25) + "..." : incident.description}',
                          subtitle: '${incident.projectName ?? "Unassigned"} • ${_getSeverityLabel(incident.severity)} • ${DateFormat('MMM dd, HH:mm').format(incident.reportedAt)}',
                          timestamp: incident.reportedAt,
                          icon: Icons.report_problem,
                          color: _getSeverityColor(incident.severity),
                        ));
                      }
                    }
                    
                    // Sort by timestamp and take 5
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
                    
                    final activitiesList = allActivities.take(5).toList();
                    return Card(
                      child: Column(
                        children: activitiesList.asMap().entries.map((entry) {
                          final activity = entry.value;
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  activity.icon,
                                  color: activity.color,
                                ),
                                title: Text(activity.title),
                                subtitle: Text(activity.subtitle),
                              ),
                              if (entry.key < activitiesList.length - 1) const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
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

class _SupervisorActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  _SupervisorActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

class _SupervisorActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SupervisorActionCard({
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
            mainAxisAlignment: MainAxisAlignment.center,
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

