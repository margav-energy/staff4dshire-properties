import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:staff4dshire_shared/shared.dart';
class LiveJobsSection extends StatelessWidget {
  const LiveJobsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer4<JobCompletionProvider, TimesheetProvider, ProjectProvider, UserProvider>(
      builder: (context, jobCompletionProvider, timesheetProvider, projectProvider, userProvider, child) {
        // Get all active time entries (signed in but not signed out)
        final activeEntries = timesheetProvider.entries.where((e) => e.signOutTime == null).toList();
        
        // Get pending completions
        final pendingCompletions = jobCompletionProvider.getPendingCompletions();
        
        // Combine for live jobs view
        final liveJobs = <Map<String, dynamic>>[];
        
        // Add active entries
        for (var entry in activeEntries) {
          final project = projectProvider.projects.firstWhere(
            (p) => p.id == entry.projectId,
            orElse: () => Project(id: entry.projectId, name: entry.projectName, isActive: true),
          );
          final staff = userProvider.getUserById(entry.staffId);
          
          liveJobs.add({
            'type': 'active',
            'entry': entry,
            'project': project,
            'staff': staff,
            'status': 'in_progress',
          });
        }
        
        // Add pending completions
        for (var completion in pendingCompletions) {
          final project = projectProvider.projects.firstWhere(
            (p) => p.id == completion.projectId,
            orElse: () => Project(id: completion.projectId, name: 'Unknown', isActive: true),
          );
          final staff = userProvider.getUserById(completion.userId);
          final entry = timesheetProvider.entries.firstWhere(
            (e) => e.id == completion.timeEntryId,
            orElse: () => timesheetProvider.entries.first,
          );
          
          liveJobs.add({
            'type': 'pending_approval',
            'entry': entry,
            'project': project,
            'staff': staff,
            'completion': completion,
            'status': 'pending_approval',
          });
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
                      'Live Jobs',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/jobs/approvals');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (liveJobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No live jobs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                else
                  ...liveJobs.take(5).map((job) {
                    final entry = job['entry'] as TimeEntry;
                    final project = job['project'] as Project;
                    final staff = job['staff'] as dynamic;
                    final status = job['status'] as String;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            status == 'in_progress' ? Icons.work : Icons.pending,
                            color: status == 'in_progress' ? Colors.green : Colors.orange,
                            size: 20,
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
                                Text(
                                  '${staff?.fullName ?? entry.staffName}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              status == 'in_progress' ? 'In Progress' : 'Pending Approval',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: status == 'in_progress'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}


