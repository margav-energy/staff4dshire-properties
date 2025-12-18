import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/job_completion_provider.dart';
import '../../../core/providers/invoice_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/providers/timesheet_provider.dart';
import '../../../core/models/job_completion_model.dart';
import '../../../core/models/project_model.dart';

class JobApprovalScreen extends StatefulWidget {
  const JobApprovalScreen({super.key});

  @override
  State<JobApprovalScreen> createState() => _JobApprovalScreenState();
}

class _JobApprovalScreenState extends State<JobApprovalScreen> {
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobCompletionProvider = Provider.of<JobCompletionProvider>(context);
    final pendingCompletions = jobCompletionProvider.getPendingCompletions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Approvals'),
      ),
      body: pendingCompletions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending approvals',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingCompletions.length,
              itemBuilder: (context, index) {
                final completion = pendingCompletions[index];
                return _JobApprovalCard(
                  completion: completion,
                  onApprove: () => _handleApprove(completion),
                  onReject: () => _handleReject(completion),
                );
              },
            ),
    );
  }

  Future<void> _handleApprove(JobCompletion completion) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobCompletionProvider = Provider.of<JobCompletionProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final supervisor = authProvider.currentUser;

    if (supervisor == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Job Completion'),
        content: const Text('Are you sure you want to approve this job completion? An invoice will be generated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Approve the completion
      await jobCompletionProvider.approveCompletion(completion.id, supervisor.id);

      // Get time entry to calculate hours
      final timeEntry = timesheetProvider.entries.firstWhere(
        (e) => e.id == completion.timeEntryId,
        orElse: () => timesheetProvider.entries.first,
      );

      // Calculate hours worked
      final hoursWorked = timeEntry.duration.inMinutes / 60.0;
      const defaultHourlyRate = 25.0; // Can be configured per project/user
      final amount = hoursWorked * defaultHourlyRate;

      // Get project for description
      final project = projectProvider.projects.firstWhere(
        (p) => p.id == completion.projectId,
        orElse: () => Project(
          id: completion.projectId,
          name: 'Unknown Project',
          isActive: true,
        ),
      );

      // Generate invoice
      await invoiceProvider.generateInvoice(
        projectId: completion.projectId,
        staffId: completion.userId,
        timeEntryId: completion.timeEntryId,
        jobCompletionId: completion.id,
        supervisorId: supervisor.id,
        amount: amount,
        hoursWorked: hoursWorked,
        hourlyRate: defaultHourlyRate,
        description: 'Job completion - ${project.name}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job approved and invoice generated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(JobCompletion completion) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobCompletionProvider = Provider.of<JobCompletionProvider>(context, listen: false);
    final supervisor = authProvider.currentUser;

    if (supervisor == null) return;

    // Show rejection dialog with reason
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job Completion'),
        content: TextField(
          controller: _rejectionReasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason *',
            hintText: 'Please provide a reason for rejection...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _rejectionReasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _rejectionReasonController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, _rejectionReasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    _rejectionReasonController.clear();

    if (reason == null || reason.isEmpty || !mounted) return;

    try {
      await jobCompletionProvider.rejectCompletion(completion.id, supervisor.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completion rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _JobApprovalCard extends StatelessWidget {
  final JobCompletion completion;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JobApprovalCard({
    required this.completion,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);

    final staff = userProvider.getUserById(completion.userId);
    final project = projectProvider.projects.firstWhere(
      (p) => p.id == completion.projectId,
      orElse: () => Project(
        id: completion.projectId,
        name: 'Unknown Project',
        isActive: true,
      ),
    );
    final timeEntry = timesheetProvider.entries.firstWhere(
      (e) => e.id == completion.timeEntryId,
      orElse: () => timesheetProvider.entries.first,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Staff: ${staff?.fullName ?? completion.userId}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(completion.isCompleted ? 'Completed' : 'Not Completed'),
                  backgroundColor: completion.isCompleted
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!completion.isCompleted && completion.completionReason != null) ...[
              Text(
                'Reason:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                completion.completionReason!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            if (completion.completionImageUrl != null) ...[
              Text(
                'Completion Image:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              // Image preview would go here
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 48),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(timeEntry.signInTime)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


