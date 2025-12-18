import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/project_model.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/providers/timesheet_provider.dart';
import '../../../core/providers/auth_provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoadingPhotos = false;

  Future<void> _pickPhoto(bool isBefore) async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Photo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      setState(() => _isLoadingPhotos = true);

      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        setState(() => _isLoadingPhotos = false);
        return;
      }

      String? photoPath;
      if (kIsWeb) {
        // For web, convert to base64
        final bytes = await pickedFile.readAsBytes();
        photoPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else {
        photoPath = pickedFile.path;
      }

      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      
      if (isBefore) {
        await projectProvider.updateProjectPhotos(
          widget.projectId,
          beforePhoto: photoPath,
        );
      } else {
        await projectProvider.updateProjectPhotos(
          widget.projectId,
          afterPhoto: photoPath,
        );
      }

      if (mounted) {
        setState(() => _isLoadingPhotos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isBefore ? "Before" : "After"} photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPhoto(String? photoPath, String label, bool isBefore) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: photoPath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No ${label.toLowerCase()} photo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _pickPhoto(isBefore),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text('Add ${label.toLowerCase()} photo'),
                      ),
                    ],
                  ],
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.memory(
                              base64Decode(photoPath.split(',')[1]),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(photoPath),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (isAdmin)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _pickPhoto(isBefore),
                            tooltip: 'Edit photo',
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _PhotoViewScreen(
                                  photoPath: photoPath,
                                  label: label,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.role == UserRole.admin;

    final project = projectProvider.getProjectById(widget.projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: const Center(child: Text('Project not found')),
      );
    }

    // Get all timesheet entries for this project
    final projectEntries = timesheetProvider.entries
        .where((entry) => entry.projectId == project.id)
        .toList();

    // Get unique staff who worked on this project
    final staffSet = <String, String>{};
    for (var entry in projectEntries) {
      if (!staffSet.containsKey(entry.staffId)) {
        staffSet[entry.staffId] = entry.staffName;
      }
    }
    final staffList = staffSet.entries.toList();

    // Calculate total hours worked on this project
    final totalHours = projectEntries
        .where((e) => e.signOutTime != null)
        .fold<double>(
          0.0,
          (sum, entry) => sum + entry.duration.inMinutes / 60.0,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          if (isAdmin && !project.isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Mark as Completed',
              onPressed: () => _showMarkCompletedDialog(project, projectProvider),
            ),
        ],
      ),
      body: _isLoadingPhotos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Status
                  if (project.isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Project Completed',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (project.completedAt != null)
                                  Text(
                                    'Completed on: ${DateFormat('MMM dd, yyyy').format(project.completedAt!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.work, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Text(
                            'Project In Progress',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Project Details
                  Text(
                    'Project Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.location_on,
                            'Address',
                            project.address ?? 'Not specified',
                          ),
                          if (project.description != null) ...[
                            const Divider(height: 24),
                            _buildDetailRow(
                              Icons.description,
                              'Description',
                              project.description!,
                            ),
                          ],
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Created',
                            DateFormat('MMM dd, yyyy').format(
                              DateTime.now(), // In real app, use project.createdAt
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Photos (from photos list)
                  if (project.photos.isNotEmpty) ...[
                    Text(
                      'Project Photos',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.photos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final photoPath = entry.value;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _PhotoViewScreen(
                                  photoPath: photoPath,
                                  label: 'Photo ${index + 1}',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? photoPath.startsWith('data:image')
                                      ? Image.memory(
                                          base64Decode(photoPath.split(',')[1]),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          photoPath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.broken_image);
                                          },
                                        )
                                  : Image.file(
                                      File(photoPath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image);
                                      },
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Before and After Photos (for completed projects)
                  if (project.isCompleted) ...[
                    Text(
                      'Before & After Photos',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildPhoto(project.beforePhoto, 'Before Photo', true),
                    const SizedBox(height: 16),
                    _buildPhoto(project.afterPhoto, 'After Photo', false),
                    const SizedBox(height: 24),
                  ],

                  // Drawings Section
                  if (project.drawings.isNotEmpty) ...[
                    Text(
                      'Project Drawings',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: project.drawings.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final drawing = project.drawings[index];
                          return ListTile(
                            leading: Icon(_getFileIcon(drawing.fileType)),
                            title: Text(drawing.fileName),
                            subtitle: Text(
                              '${_formatFileSize(drawing.fileSize)} • ${drawing.fileType.toUpperCase()}',
                            ),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () {
                              // TODO: Open file viewer
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Assigned Staff and Supervisors
                  if (project.assignedStaffIds.isNotEmpty || project.assignedSupervisorIds.isNotEmpty) ...[
                    Text(
                      'Assigned Team',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          if (project.assignedStaffIds.isNotEmpty) ...[
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: const Text('Assigned Staff'),
                              subtitle: Text('${project.assignedStaffIds.length} staff member(s)'),
                            ),
                            const Divider(height: 1),
                          ],
                          if (project.assignedSupervisorIds.isNotEmpty) ...[
                            ListTile(
                              leading: const Icon(Icons.supervisor_account),
                              title: const Text('Assigned Supervisors'),
                              subtitle: Text('${project.assignedSupervisorIds.length} supervisor(s)'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 24),

                  // Project Statistics
                  Text(
                    'Project Statistics',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatRow(
                            'Total Hours',
                            '${totalHours.toStringAsFixed(1)}h',
                            Icons.access_time,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Staff Members',
                            '${staffList.length}',
                            Icons.people,
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Timesheet Entries',
                            '${projectEntries.length}',
                            Icons.description,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Staff Who Worked
                  Text(
                    'Staff Who Worked on This Project',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (staffList.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No staff entries yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: staffList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final staffEntry = staffList[index];
                          final staffEntries = projectEntries
                              .where((e) => e.staffId == staffEntry.key)
                              .toList();
                          final staffHours = staffEntries
                              .where((e) => e.signOutTime != null)
                              .fold<double>(
                                0.0,
                                (sum, entry) => sum + entry.duration.inMinutes / 60.0,
                              );

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                staffEntry.value[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(staffEntry.value),
                            subtitle: Text('${staffHours.toStringAsFixed(1)}h total'),
                            trailing: Text(
                              '${staffEntries.length} entries',
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'png':
      case 'jpeg':
      case 'jpg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showMarkCompletedDialog(
    Project project,
    ProjectProvider projectProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Project as Completed'),
        content: const Text(
          'Are you sure you want to mark this project as completed? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
  }
}

class _PhotoViewScreen extends StatelessWidget {
  final String photoPath;
  final String label;

  const _PhotoViewScreen({
    required this.photoPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: InteractiveViewer(
          child: kIsWeb
              ? Image.memory(
                  base64Decode(photoPath.split(',')[1]),
                  fit: BoxFit.contain,
                )
              : Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

