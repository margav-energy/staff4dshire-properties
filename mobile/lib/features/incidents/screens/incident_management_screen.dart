import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/models/incident_model.dart';
import '../../../core/providers/incident_provider.dart';
import '../../../core/providers/auth_provider.dart' show AuthProvider, UserRole;
import '../../../core/providers/notification_provider.dart';

class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({super.key});

  @override
  State<IncidentManagementScreen> createState() => _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncidentProvider>(context, listen: false).loadIncidents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusLabel(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.reported:
        return 'Reported';
      case IncidentStatus.attending:
        return 'Attending';
      case IncidentStatus.fixing:
        return 'Fixing';
      case IncidentStatus.tracking:
        return 'Tracking Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.reported:
        return Colors.orange;
      case IncidentStatus.attending:
        return Colors.blue;
      case IncidentStatus.fixing:
        return Colors.purple;
      case IncidentStatus.tracking:
        return Colors.teal;
      case IncidentStatus.resolved:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.reported:
        return Icons.report_problem;
      case IncidentStatus.attending:
        return Icons.person_outline;
      case IncidentStatus.fixing:
        return Icons.build;
      case IncidentStatus.tracking:
        return Icons.track_changes;
      case IncidentStatus.resolved:
        return Icons.check_circle;
    }
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

  Future<void> _updateIncidentStatus(Incident incident, IncidentStatus newStatus) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final incidentProvider = Provider.of<IncidentProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      String? notes;
      if (newStatus == IncidentStatus.resolved) {
        notes = await _showNotesDialog('Resolve Incident');
      } else if (newStatus == IncidentStatus.fixing) {
        notes = await _showNotesDialog('Add Fix Notes (Optional)');
      }

      await incidentProvider.updateIncidentStatus(
        incidentId: incident.id,
        newStatus: newStatus,
        updatedBy: currentUser.id,
        updatedByName: currentUser.name,
        notes: notes,
      );

      // Notify the reporter about the status update
      if (mounted && incident.reporterId != currentUser.id) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.addNotification(
          title: 'Incident Status Updated',
          message: 'Your incident has been updated to: ${_getStatusLabel(newStatus)}${notes != null && notes.isNotEmpty ? "\n\nNotes: $notes" : ""}',
          type: NotificationType.info,
          relatedEntityId: incident.id,
          relatedEntityType: 'incident',
          targetUserId: incident.reporterId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident status updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating incident: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showNotesDialog(String title) async {
    final notesController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Enter notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notesController.text.trim().isEmpty ? null : notesController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusUpdateDialog(Incident incident) async {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    final availableStatuses = <IncidentStatus>[];
    
    // Show different statuses based on current status
    switch (incident.status) {
      case IncidentStatus.reported:
        availableStatuses.addAll([
          IncidentStatus.attending,
          IncidentStatus.fixing,
          IncidentStatus.resolved,
        ]);
        break;
      case IncidentStatus.attending:
        availableStatuses.addAll([
          IncidentStatus.fixing,
          IncidentStatus.tracking,
          IncidentStatus.resolved,
        ]);
        break;
      case IncidentStatus.fixing:
        availableStatuses.addAll([
          IncidentStatus.tracking,
          IncidentStatus.resolved,
        ]);
        break;
      case IncidentStatus.tracking:
        availableStatuses.add(IncidentStatus.resolved);
        break;
      case IncidentStatus.resolved:
        // Already resolved, can reopen
        availableStatuses.add(IncidentStatus.reported);
        break;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Incident Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) {
            return ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(_getStatusLabel(status)),
              onTap: () {
                Navigator.pop(context);
                _updateIncidentStatus(incident, status);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Active',
              icon: Icon(Icons.warning, color: Colors.white),
            ),
            Tab(
              text: 'Resolved',
              icon: Icon(Icons.check_circle, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Consumer<IncidentProvider>(
        builder: (context, incidentProvider, child) {
          final pendingIncidents = incidentProvider.getPendingIncidents()
            ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
          final resolvedIncidents = incidentProvider.getResolvedIncidents()
            ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

          return TabBarView(
            controller: _tabController,
            children: [
              // Active Incidents Tab
              pendingIncidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No active incidents',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingIncidents.length,
                      itemBuilder: (context, index) {
                        final incident = pendingIncidents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showIncidentDetails(incident),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              incident.description,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Reported by ${incident.reporterName}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(incident.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusLabel(incident.status),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _getStatusColor(incident.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getSeverityColor(incident.severity).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getSeverityLabel(incident.severity),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _getSeverityColor(incident.severity),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy HH:mm').format(incident.reportedAt),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (incident.location != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            incident.location!,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showStatusUpdateDialog(incident),
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Update Status'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              
              // Resolved Incidents Tab
              resolvedIncidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No resolved incidents',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: resolvedIncidents.length,
                      itemBuilder: (context, index) {
                        final incident = resolvedIncidents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.green.shade50,
                          child: InkWell(
                            onTap: () => _showIncidentDetails(incident),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          incident.description,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.check_circle, color: Colors.green),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Resolved by ${incident.assignedToName ?? "N/A"}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (incident.statusUpdatedAt != null)
                                    Text(
                                      DateFormat('MMM dd, yyyy HH:mm').format(incident.statusUpdatedAt!),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }

  void _showIncidentDetails(Incident incident) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

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
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Incident Details',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(incident.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(incident.status), color: _getStatusColor(incident.status), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusLabel(incident.status),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _getStatusColor(incident.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Photo
              if (incident.photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          incident.photoPath!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(incident.photoPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              
              const SizedBox(height: 24),
              
              // Description
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(incident.description),
              
              const SizedBox(height: 24),
              
              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.person,
                      label: 'Reported By',
                      value: incident.reporterName,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.flag,
                      label: 'Severity',
                      value: _getSeverityLabel(incident.severity),
                      valueColor: _getSeverityColor(incident.severity),
                    ),
                  ),
                ],
              ),
              
              if (incident.location != null) ...[
                const SizedBox(height: 16),
                _DetailItem(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: incident.location!,
                ),
              ],
              
              const SizedBox(height: 16),
              _DetailItem(
                icon: Icons.access_time,
                label: 'Reported At',
                value: DateFormat('MMM dd, yyyy HH:mm').format(incident.reportedAt),
              ),
              
              if (incident.assignedToName != null) ...[
                const SizedBox(height: 16),
                _DetailItem(
                  icon: Icons.person_outline,
                  label: 'Assigned To',
                  value: incident.assignedToName!,
                ),
              ],
              
              if (incident.notes != null && incident.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(incident.notes!),
                ),
              ],
              
              // Action Buttons (only for active incidents and admin/supervisor)
              if (incident.status != IncidentStatus.resolved && 
                  currentUser != null && 
                  (currentUser.role == UserRole.admin || currentUser.role == UserRole.supervisor)) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showStatusUpdateDialog(incident);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

