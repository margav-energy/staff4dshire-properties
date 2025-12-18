import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';

class ProjectSelectionScreen extends StatefulWidget {
  const ProjectSelectionScreen({super.key});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load projects when screen opens (filtered by company_id)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      projectProvider.loadProjects(userId: userId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Reload projects when app comes back to foreground (filtered by company_id)
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      projectProvider.loadProjects(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Project'),
      ),
      body: Consumer2<ProjectProvider, AuthProvider>(
        builder: (context, projectProvider, authProvider, child) {
          final currentUser = authProvider.currentUser;
          final userRole = currentUser?.role;
          final currentUserId = currentUser?.id;
          
          // Filter projects based on user role
          final allProjects = projectProvider.projects;
          List<Project> projects;
          bool hasAssignedProjects = false;
          
          if (userRole == UserRole.admin || userRole == UserRole.supervisor) {
            // Admins and supervisors see all projects
            projects = allProjects;
            hasAssignedProjects = true;
          } else if (userRole == UserRole.staff && currentUserId != null) {
            // Staff see projects where:
            // 1. Project's assignedStaffIds is empty (available to all staff), OR
            // 2. Staff is in the project's assignedStaffIds list, OR
            // 3. Project ID is in user's assignedProjectIds (legacy support)
            final assignedProjectIds = currentUser?.assignedProjectIds ?? [];
            
            projects = allProjects.where((project) {
              // If project has no staff assigned, it's available to all staff
              if (project.assignedStaffIds.isEmpty) {
                return true;
              }
              // Check if staff is in the project's assignedStaffIds list
              final isAssignedViaProject = project.assignedStaffIds.contains(currentUserId);
              // Also check legacy assignedProjectIds for backward compatibility
              final isAssignedViaUser = assignedProjectIds.contains(project.id);
              return isAssignedViaProject || isAssignedViaUser;
            }).toList();
            
            // Check if staff has any assigned projects
            hasAssignedProjects = projects.isNotEmpty;
          } else {
            projects = [];
          }
          
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userRole == UserRole.staff && !hasAssignedProjects
                        ? 'No assigned projects available'
                        : 'No active projects available',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (userRole == UserRole.staff && !hasAssignedProjects) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Please contact your administrator to assign projects',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    project.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          project.address!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (project.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          project.description!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.secondary,
                  ),
                  onTap: () {
                    Navigator.pop(context, project);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

