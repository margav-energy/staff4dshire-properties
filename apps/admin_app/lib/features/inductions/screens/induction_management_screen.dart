import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Induction {
  final String id;
  final String userId;
  final String userName;
  final String projectId;
  final String projectName;
  final String title;
  final String description;
  final DateTime? completedAt;
  final DateTime? expiryDate;
  final bool isRequired;

  Induction({
    required this.id,
    required this.userId,
    required this.userName,
    this.projectId = '',
    this.projectName = '',
    required this.title,
    this.description = '',
    this.completedAt,
    this.expiryDate,
    this.isRequired = true,
  });

  bool get isCompleted => completedAt != null;
  bool get isExpired {
    if (expiryDate == null || !isCompleted) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}

class InductionManagementScreen extends StatefulWidget {
  const InductionManagementScreen({super.key});

  @override
  State<InductionManagementScreen> createState() => _InductionManagementScreenState();
}

class _InductionManagementScreenState extends State<InductionManagementScreen> {
  int _selectedTab = 0;
  final List<Induction> _inductions = [
    Induction(
      id: '1',
      userId: '1',
      userName: 'John Doe',
      projectName: 'City Center Development',
      title: 'Site Safety Induction',
      description: 'Mandatory safety induction for all site workers',
      completedAt: DateTime.now().subtract(const Duration(days: 30)),
      expiryDate: DateTime.now().add(const Duration(days: 335)),
      isRequired: true,
    ),
    Induction(
      id: '2',
      userId: '2',
      userName: 'Jane Smith',
      projectName: 'Riverside Complex',
      title: 'Site Safety Induction',
      description: 'Mandatory safety induction for all site workers',
      completedAt: null,
      isRequired: true,
    ),
    Induction(
      id: '3',
      userId: '3',
      userName: 'Mike Johnson',
      projectName: 'City Center Development',
      title: 'Working at Height Training',
      description: 'Specialized training for elevated work',
      completedAt: DateTime.now().subtract(const Duration(days: 60)),
      expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      isRequired: true,
    ),
    Induction(
      id: '4',
      userId: '4',
      userName: 'Sarah Williams',
      projectName: 'Park View Apartments',
      title: 'Site Safety Induction',
      description: 'Mandatory safety induction for all site workers',
      completedAt: DateTime.now().subtract(const Duration(days: 10)),
      expiryDate: DateTime.now().add(const Duration(days: 355)),
      isRequired: true,
    ),
  ];

  List<Induction> get pendingInductions => _inductions.where((i) => !i.isCompleted).toList();
  List<Induction> get completedInductions => _inductions.where((i) => i.isCompleted).toList();
  List<Induction> get expiredInductions => _inductions.where((i) => i.isExpired).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Induction Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Schedule Induction',
            onPressed: () => _showScheduleDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Pending (${pendingInductions.length})',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Completed (${completedInductions.length})',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Expired (${expiredInductions.length})',
                    isSelected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildInductionList(pendingInductions, theme, 'Pending')
                : _selectedTab == 1
                    ? _buildInductionList(completedInductions, theme, 'Completed')
                    : _buildInductionList(expiredInductions, theme, 'Expired'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInductionList(List<Induction> inductions, ThemeData theme, String title) {
    if (inductions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No $title inductions',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inductions.length,
      itemBuilder: (context, index) {
        final induction = inductions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: induction.isExpired ? Colors.red.shade50 : null,
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: induction.isCompleted
                    ? (induction.isExpired ? Colors.red.shade100 : Colors.green.shade100)
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                induction.isCompleted
                    ? (induction.isExpired ? Icons.error : Icons.check_circle)
                    : Icons.pending,
                color: induction.isCompleted
                    ? (induction.isExpired ? Colors.red : Colors.green)
                    : Colors.orange,
              ),
            ),
            title: Text(induction.userName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(induction.title),
                if (induction.projectName.isNotEmpty)
                  Text(induction.projectName, style: theme.textTheme.bodySmall),
                if (induction.completedAt != null)
                  Text(
                    'Completed: ${DateFormat('MMM dd, yyyy').format(induction.completedAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (induction.expiryDate != null)
                  Text(
                    'Expires: ${DateFormat('MMM dd, yyyy').format(induction.expiryDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: induction.isExpired ? Colors.red : null,
                      fontWeight: induction.isExpired ? FontWeight.bold : null,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
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
                const PopupMenuItem(
                  value: 'remind',
                  child: Row(
                    children: [
                      Icon(Icons.notifications, size: 20),
                      SizedBox(width: 8),
                      Text('Send Reminder'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showInductionDetails(context, induction),
          ),
        );
      },
    );
  }

  void _showInductionDetails(BuildContext context, Induction induction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(induction.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Staff', induction.userName),
              if (induction.projectName.isNotEmpty)
                _DetailRow('Project', induction.projectName),
              if (induction.description.isNotEmpty)
                _DetailRow('Description', induction.description),
              if (induction.completedAt != null)
                _DetailRow(
                  'Completed',
                  DateFormat('MMM dd, yyyy HH:mm').format(induction.completedAt!),
                ),
              if (induction.expiryDate != null)
                _DetailRow(
                  'Expires',
                  DateFormat('MMM dd, yyyy').format(induction.expiryDate!),
                ),
              _DetailRow('Required', induction.isRequired ? 'Yes' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!induction.isCompleted)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder sent')),
                );
              },
              child: const Text('Send Reminder'),
            ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule New Induction'),
        content: const Text('Induction scheduling form would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Induction scheduled')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}


