import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/timesheet_provider.dart';

class TimesheetEntryDetailScreen extends StatelessWidget {
  final TimeEntry entry;

  const TimesheetEntryDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = entry.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: entry.approvalStatus == ApprovalStatus.approved
                  ? Colors.green.shade50
                  : entry.approvalStatus == ApprovalStatus.rejected
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      entry.approvalStatus == ApprovalStatus.approved
                          ? Icons.check_circle
                          : entry.approvalStatus == ApprovalStatus.rejected
                              ? Icons.cancel
                              : Icons.pending,
                      color: entry.approvalStatus == ApprovalStatus.approved
                          ? Colors.green
                          : entry.approvalStatus == ApprovalStatus.rejected
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.approvalStatus == ApprovalStatus.approved
                          ? 'Approved'
                          : entry.approvalStatus == ApprovalStatus.rejected
                              ? 'Rejected'
                              : 'Pending Approval',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: entry.approvalStatus == ApprovalStatus.approved
                            ? Colors.green
                            : entry.approvalStatus == ApprovalStatus.rejected
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Staff Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Name',
                      value: entry.staffName,
                      theme: theme,
                    ),
                    _DetailRow(
                      label: 'Staff ID',
                      value: entry.staffId,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Sign In',
                      value: DateFormat('MMM dd, yyyy HH:mm').format(entry.signInTime),
                      theme: theme,
                    ),
                    _DetailRow(
                      label: 'Sign Out',
                      value: entry.signOutTime != null
                          ? DateFormat('MMM dd, yyyy HH:mm').format(entry.signOutTime!)
                          : 'In Progress',
                      theme: theme,
                    ),
                    _DetailRow(
                      label: 'Duration',
                      value: '${hours}h ${minutes}m',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Project Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Project',
                      value: entry.projectName,
                      theme: theme,
                    ),
                    _DetailRow(
                      label: 'Location',
                      value: entry.location,
                      theme: theme,
                    ),
                    if (entry.latitude != null && entry.longitude != null)
                      _DetailRow(
                        label: 'Coordinates',
                        value: '${entry.latitude!.toStringAsFixed(6)}, ${entry.longitude!.toStringAsFixed(6)}',
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),

            // Photos Section
            if (entry.beforePhoto != null || entry.afterPhoto != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Before Photo
                      if (entry.beforePhoto != null) ...[
                        Text(
                          'Before Photo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PhotoWidget(photoPath: entry.beforePhoto!),
                        const SizedBox(height: 16),
                      ],
                      
                      // After Photo
                      if (entry.afterPhoto != null) ...[
                        Text(
                          'After Photo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PhotoWidget(photoPath: entry.afterPhoto!),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (entry.approvedBy != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Approved By',
                        value: entry.approvedBy!,
                        theme: theme,
                      ),
                      if (entry.approvedAt != null)
                        _DetailRow(
                          label: 'Approved At',
                          value: DateFormat('MMM dd, yyyy HH:mm').format(entry.approvedAt!),
                          theme: theme,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoWidget extends StatelessWidget {
  final String photoPath;

  const _PhotoWidget({required this.photoPath});

  Future<Widget> _buildPhotoWidget() async {
    if (photoPath.startsWith('pref:')) {
      // Load from SharedPreferences (base64)
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = photoPath.replaceFirst('pref:', '');
        final base64Image = prefs.getString(key);
        
        if (base64Image != null) {
          final bytes = base64Decode(base64Image);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 48),
              );
            },
          );
        }
      } catch (e) {
        debugPrint('Error loading photo from preferences: $e');
      }
    } else if (!kIsWeb) {
      // Load from file path (mobile only)
      try {
        final file = File(photoPath);
        final exists = await file.exists();
        if (exists) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 48),
              );
            },
          );
        }
      } catch (e) {
        debugPrint('Error loading photo from file: $e');
      }
    }
    
    // Error fallback
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.error, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show full screen photo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: FutureBuilder<Widget>(
                  future: _buildPhotoWidget(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(color: Colors.white);
                    }
                    if (snapshot.hasData) {
                      return InteractiveViewer(
                        child: snapshot.data!,
                      );
                    }
                    return const Icon(Icons.error, color: Colors.white, size: 48);
                  },
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey[300],
          child: FutureBuilder<Widget>(
            future: _buildPhotoWidget(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return snapshot.data!;
              }
              return const Icon(Icons.error, size: 48);
            },
          ),
        ),
      ),
    );
  }
}

