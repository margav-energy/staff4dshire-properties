import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/project_model.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/providers/auth_provider.dart';

class ProjectTypeSelectionWidget extends StatelessWidget {
  final Function(Project) onProjectSelected;
  final Project? selectedProject;

  const ProjectTypeSelectionWidget({
    super.key,
    required this.onProjectSelected,
    this.selectedProject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // Get all projects
    final allProjects = projectProvider.projects;
    final currentUserId = user.id;
    
    // Separate regular and callout projects
    final regularProjects = allProjects.where((p) => p.type == ProjectType.regular).toList();
    final calloutProjects = allProjects.where((p) => p.type == ProjectType.callout).toList();
    
    // Filter regular projects by checking if staff is assigned to the project
    // Check both: project's assignedStaffIds contains user ID, OR user's assignedProjectIds contains project ID (legacy support)
    final assignedProjectIds = user.assignedProjectIds;
    List<Project> availableRegularProjects;
    
    if (user.role == UserRole.admin || user.role == UserRole.supervisor) {
      // Admins and supervisors see all regular projects
      availableRegularProjects = regularProjects;
    } else {
      // Staff see projects where:
      // 1. Project's assignedStaffIds is empty (available to all staff), OR
      // 2. Staff is in the project's assignedStaffIds list, OR
      // 3. Project ID is in user's assignedProjectIds (legacy support)
      availableRegularProjects = regularProjects.where((project) {
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
    }
    
    // Filter callout projects by checking if staff is assigned to the project
    // Check both: project's assignedStaffIds contains user ID, OR user's assignedCalloutProjectIds contains project ID (legacy support)
    final assignedCalloutProjectIds = user.assignedCalloutProjectIds;
    final availableCalloutProjects = calloutProjects.where((project) {
      if (user.role == UserRole.admin || user.role == UserRole.supervisor) {
        // Admins and supervisors see all callout projects
        return true;
      }
      // Staff see callout projects where they are assigned via assignedStaffIds OR assignedCalloutProjectIds
      final isAssignedViaProject = project.assignedStaffIds.contains(currentUserId);
      final isAssignedViaUser = assignedCalloutProjectIds.contains(project.id);
      return isAssignedViaProject || isAssignedViaUser;
    }).toList();
    
    // Group regular projects by category
    final Map<String, List<Project>> categorizedProjects = {};
    for (var project in availableRegularProjects) {
      final category = project.category ?? 'Uncategorized';
      if (!categorizedProjects.containsKey(category)) {
        categorizedProjects[category] = [];
      }
      categorizedProjects[category]!.add(project);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Regular Projects Section
        if (availableRegularProjects.isNotEmpty) ...[
          Text(
            'Regular Projects',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Show projects by category
          ...categorizedProjects.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categorizedProjects.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                ...entry.value.map((project) {
                  final isSelected = selectedProject?.id == project.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        project.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
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
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => onProjectSelected(project),
                    ),
                  );
                }),
              ],
            );
          }),
          
          const SizedBox(height: 24),
        ],
        
        // Callout Projects Section
        if (availableCalloutProjects.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.emergency,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Callout Projects',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These projects are assigned by your administrator',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          ...availableCalloutProjects.map((project) {
            final isSelected = selectedProject?.id == project.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected
                  ? Colors.orange.shade50
                  : null,
              elevation: isSelected ? 4 : 1,
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.shade700
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: isSelected
                        ? Colors.white
                        : Colors.orange.shade700,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'CALLOUT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
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
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.orange.shade700,
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => onProjectSelected(project),
              ),
            );
          }),
        ],
        
        // Empty state
        if (availableRegularProjects.isEmpty && availableCalloutProjects.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects available',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please contact your administrator to assign projects',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

