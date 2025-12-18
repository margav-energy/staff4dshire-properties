import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:staff4dshire_shared/shared.dart';
class AvailableJobsSection extends StatelessWidget {
  const AvailableJobsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer3<ProjectProvider, AuthProvider, TimesheetProvider>(
      builder: (context, projectProvider, authProvider, timesheetProvider, child) {
        final currentUser = authProvider.currentUser;
        final currentUserId = currentUser?.id;
        final userRole = currentUser?.role;
        
        if (currentUserId == null) {
          return const SizedBox.shrink();
        }
        
        // Get all projects
        final allProjects = projectProvider.projects;
        
        // Filter for available projects (assigned to staff but not yet started)
        List<Project> availableProjects = [];
        
        if (userRole == UserRole.admin || userRole == UserRole.supervisor) {
          // Admins and supervisors see all active projects
          availableProjects = allProjects.where((p) => p.isActive && !p.isCompleted).toList();
        } else if (userRole == UserRole.staff) {
          // Staff see projects assigned to them
          final assignedProjectIds = currentUser?.assignedProjectIds ?? [];
          
          availableProjects = allProjects.where((project) {
            // Must be active and not completed
            if (!project.isActive || project.isCompleted) {
              return false;
            }
            
            // Check if already signed in to this project
            final hasActiveEntry = timesheetProvider.entries.any(
              (entry) => entry.projectId == project.id && entry.signOutTime == null
            );
            if (hasActiveEntry) {
              return false; // Already working on this project
            }
            
            // Regular projects: check if assigned
            if (project.type == ProjectType.regular) {
              // If project has no staff assigned, it's available to all staff
              if (project.assignedStaffIds.isEmpty) {
                return true;
              }
              // Check if staff is in the project's assignedStaffIds list
              final isAssignedViaProject = project.assignedStaffIds.contains(currentUserId);
              // Also check legacy assignedProjectIds for backward compatibility
              final isAssignedViaUser = assignedProjectIds.contains(project.id);
              return isAssignedViaProject || isAssignedViaUser;
            }
            
            // Callout projects: check if assigned
            if (project.type == ProjectType.callout) {
              final assignedCalloutProjectIds = currentUser?.assignedCalloutProjectIds ?? [];
              // Check if staff is in the project's assignedStaffIds list
              final isAssignedViaProject = project.assignedStaffIds.contains(currentUserId);
              // Also check legacy assignedCalloutProjectIds for backward compatibility
              final isAssignedViaUser = assignedCalloutProjectIds.contains(project.id);
              return isAssignedViaProject || isAssignedViaUser;
            }
            
            return false;
          }).toList();
        }
        
        if (availableProjects.isEmpty) {
          return const SizedBox.shrink();
        }
        
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
                      'Jobs Available',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/sign-in-out');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...availableProjects.take(3).map((project) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        context.push('/sign-in-out');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: project.type == ProjectType.callout
                                  ? Colors.orange.withOpacity(0.1)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              project.type == ProjectType.callout
                                  ? Icons.emergency
                                  : Icons.work,
                              color: project.type == ProjectType.callout
                                  ? Colors.orange
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (project.address != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    project.address!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    project.type == ProjectType.callout ? 'Callout' : 'Regular',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: project.type == ProjectType.callout
                                      ? Colors.orange.withOpacity(0.1)
                                      : theme.colorScheme.primary.withOpacity(0.1),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                if (availableProjects.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          context.push('/sign-in-out');
                        },
                        child: Text(
                          'View ${availableProjects.length - 3} more job(s)',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

