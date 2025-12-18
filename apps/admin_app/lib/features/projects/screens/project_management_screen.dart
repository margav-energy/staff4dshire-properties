import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'add_edit_project_screen.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load projects when screen opens with company filtering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      projectProvider.loadProjects(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('===========================================');
    print('[ProjectManagementScreen] BUILD METHOD CALLED');
    print('===========================================');
    
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check if user is admin or superadmin (both can manage projects)
    // In the admin app, authenticated users should be able to manage projects
    final currentUser = authProvider.currentUser;
    final isAuthenticated = authProvider.isAuthenticated;
    
    // Debug logging to diagnose the issue
    debugPrint('[ProjectManagementScreen] Build called');
    debugPrint('  - isAuthenticated: $isAuthenticated');
    debugPrint('  - currentUser: ${currentUser != null ? "exists" : "null"}');
    if (currentUser != null) {
      debugPrint('  - email: ${currentUser.email}');
      debugPrint('  - role: ${currentUser.role}');
      debugPrint('  - role.toString(): ${currentUser.role.toString()}');
      debugPrint('  - isSuperadmin: ${currentUser.isSuperadmin}');
      debugPrint('  - role == UserRole.admin: ${currentUser.role == UserRole.admin}');
      debugPrint('  - role == UserRole.superadmin: ${currentUser.role == UserRole.superadmin}');
    }
    
    // Check if user is admin or superadmin (both can manage projects)
    // Since this is the admin app, authenticated users should have admin privileges
    bool isAdmin = false;
    
    if (isAuthenticated && currentUser != null) {
      // Check enum values directly
      if (currentUser.role == UserRole.admin || 
          currentUser.role == UserRole.superadmin || 
          currentUser.isSuperadmin == true) {
        isAdmin = true;
        debugPrint('  - Admin check: PASSED (enum match)');
      } else {
        // Fallback: check string representation
        final roleStr = currentUser.role.toString().toLowerCase();
        if (roleStr == 'userrole.admin' || 
            roleStr == 'userrole.superadmin' ||
            (roleStr.contains('admin') && !roleStr.contains('supervisor'))) {
          isAdmin = true;
          debugPrint('  - Admin check: PASSED (string match: $roleStr)');
        } else {
          debugPrint('  - Admin check: FAILED (role: $roleStr)');
        }
      }
    } else {
      debugPrint('  - Admin check: FAILED (not authenticated or user is null)');
    }
    
    debugPrint('  - isAdmin final result: $isAdmin');
    print('[ProjectManagementScreen] ===== FLOATING ACTION BUTTON CHECK =====');
    print('[ProjectManagementScreen] isAuthenticated: $isAuthenticated');
    print('[ProjectManagementScreen] currentUser exists: ${currentUser != null}');
    if (currentUser != null) {
      print('[ProjectManagementScreen] currentUser.role: ${currentUser.role}');
      print('[ProjectManagementScreen] currentUser.role == UserRole.admin: ${currentUser.role == UserRole.admin}');
    }
    print('[ProjectManagementScreen] FINAL isAdmin: $isAdmin');
    print('[ProjectManagementScreen] Will show FloatingActionButton: $isAdmin');
    print('[ProjectManagementScreen] ===========================================');
    
    // TEMPORARY: Force show button for testing - remove after debugging
    // Uncomment the line below to always show the button regardless of isAdmin
    // final forceShowButton = true;
    final forceShowButton = false;
    final shouldShowButton = forceShowButton || isAdmin;
    print('[ProjectManagementScreen] forceShowButton: $forceShowButton, shouldShowButton: $shouldShowButton');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
      ),
      body: Column(
        children: [
          // Info Banner for non-admins
          if (!isAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only administrators can manage projects.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Projects List
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                // Show loader while loading
                if (projectProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                // Show empty state only after loading is complete
                if (projectProvider.allProjects.isEmpty) {
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
                          'No projects found',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a new project to get started',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projectProvider.allProjects.length,
                  itemBuilder: (context, index) {
                    final project = projectProvider.allProjects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: project.isActive ? null : Colors.grey.shade100,
                      child: InkWell(
                        onTap: () {
                          context.push('/projects/${project.id}');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: project.isCompleted
                                  ? Colors.green.shade100
                                  : project.isActive
                                      ? theme.colorScheme.primary.withOpacity(0.1)
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              project.isCompleted
                                  ? Icons.check_circle
                                  : Icons.location_on,
                              color: project.isCompleted
                                  ? Colors.green.shade700
                                  : project.isActive
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: project.isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              if (project.isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Completed',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else if (!project.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Inactive',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    _handleMenuAction(
                                      context,
                                      value,
                                      project,
                                      projectProvider,
                                    );
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 20),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    if (!project.isCompleted)
                                      PopupMenuItem(
                                        value: project.isActive ? 'deactivate' : 'activate',
                                        child: Row(
                                          children: [
                                            Icon(
                                              project.isActive
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              project.isActive ? 'Deactivate' : 'Activate',
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (!project.isCompleted)
                                      const PopupMenuItem(
                                        value: 'complete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, size: 20, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text(
                                              'Mark as Completed',
                                              style: TextStyle(color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: shouldShowButton
          ? FloatingActionButton.extended(
              onPressed: () {
                debugPrint('[ProjectManagementScreen] Add Project button clicked!');
                print('[ProjectManagementScreen] Add Project button clicked!');
                
                Navigator.push<Project>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditProjectScreen(),
                  ),
                ).then((result) async {
                  if (result != null && mounted) {
                    debugPrint('[ProjectManagementScreen] Project created: ${result.name}');
                    print('[ProjectManagementScreen] Project created: ${result.name}');
                    
                    final projectProvider =
                        Provider.of<ProjectProvider>(context, listen: false);
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final notificationProvider =
                        Provider.of<NotificationProvider>(context, listen: false);
                    final userId = authProvider.currentUser?.id;
                    await projectProvider.addProject(result, userId: userId);
                    
                    // Immediately refresh notifications to show new project assignment notifications
                    if (userId != null) {
                      await notificationProvider.refreshNotifications(userId);
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Project added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    debugPrint('[ProjectManagementScreen] Project creation cancelled or result is null');
                    print('[ProjectManagementScreen] Project creation cancelled or result is null');
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Project'),
            )
          : Builder(
              builder: (context) {
                debugPrint('[ProjectManagementScreen] FloatingActionButton is NULL - isAdmin = $isAdmin');
                print('[ProjectManagementScreen] FloatingActionButton is NULL - isAdmin = $isAdmin');
                return const SizedBox.shrink(); // Return empty widget instead of null
              },
            ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    Project project,
    ProjectProvider projectProvider,
  ) async {
    switch (action) {
      case 'view':
        context.push('/projects/${project.id}');
        break;

      case 'complete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mark Project as Completed'),
            content: const Text(
              'Are you sure you want to mark this project as completed?',
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
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark as Completed'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await projectProvider.markProjectAsCompleted(project.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Project marked as completed'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        break;

      case 'edit':
        final result = await Navigator.push<Project>(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditProjectScreen(project: project),
          ),
        );

        if (result != null && mounted) {
          // Check for newly assigned staff before updating
          final oldStaffIds = project.assignedStaffIds.toSet();
          final newStaffIds = result.assignedStaffIds.toSet();
          final newlyAssignedStaffIds = newStaffIds.difference(oldStaffIds);
          
          final authProviderUpdate = Provider.of<AuthProvider>(context, listen: false);
          final userIdUpdate = authProviderUpdate.currentUser?.id;
          await projectProvider.updateProject(project.id, result, userId: userIdUpdate);
          
          // Note: Notifications are now handled by the backend
          if (newlyAssignedStaffIds.isNotEmpty && mounted) {
            final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            
            for (final staffId in newlyAssignedStaffIds) {
              final staff = userProvider.getUserById(staffId);
              if (staff != null) {
                await notificationProvider.addNotification(
                  title: 'Project Assignment',
                  message: 'You have been assigned to project: ${result.name}',
                  type: NotificationType.info,
                  relatedEntityId: result.id,
                  relatedEntityType: 'project',
                  targetUserId: staffId,
                );
              }
            }
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Project updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        break;

      case 'activate':
      case 'deactivate':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              action == 'activate' ? 'Activate Project' : 'Deactivate Project',
            ),
            content: Text(
              action == 'activate'
                  ? 'Are you sure you want to activate this project?'
                  : 'Are you sure you want to deactivate this project?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await projectProvider.toggleProjectStatus(project.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  action == 'activate'
                      ? 'Project activated successfully'
                      : 'Project deactivated successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: const Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await projectProvider.deleteProject(project.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Project deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        break;
    }
  }
}


