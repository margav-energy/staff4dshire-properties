import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'file_io_stub.dart' show File;
import 'package:staff4dshire_shared/shared.dart';
class JobCompletionResult {
  final bool isCompleted;
  final String? completionReason;
  final String? completionImagePath; // For callout jobs

  JobCompletionResult({
    required this.isCompleted,
    this.completionReason,
    this.completionImagePath,
  });
}

class JobCompletionDialog extends StatefulWidget {
  final Project project;
  final TimeEntry? timeEntry;

  const JobCompletionDialog({
    super.key,
    required this.project,
    this.timeEntry,
  });

  static Future<JobCompletionResult?> show(
    BuildContext context,
    Project project,
    TimeEntry? timeEntry,
  ) async {
    return await showDialog<JobCompletionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => JobCompletionDialog(
        project: project,
        timeEntry: timeEntry,
      ),
    );
  }

  @override
  State<JobCompletionDialog> createState() => _JobCompletionDialogState();
}

class _JobCompletionDialogState extends State<JobCompletionDialog> {
  bool? _isCompleted;
  final TextEditingController _reasonController = TextEditingController();
  String? _completionImagePath;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isCalloutJob => widget.project.type == ProjectType.callout;
  bool get _canSubmit {
    if (_isCompleted == null) return false;
    if (_isCompleted == true) {
      // For callout jobs, image is required when completed
      if (_isCalloutJob && _completionImagePath == null) return false;
      return true;
    } else {
      // If not completed, reason is required
      return _reasonController.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickCompletionImage() async {
    try {
      setState(() => _isUploadingImage = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, convert to base64 and store in SharedPreferences
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          final prefs = await SharedPreferences.getInstance();
          final key = 'completion_image_${DateTime.now().millisecondsSinceEpoch}';
          await prefs.setString(key, base64Image);
          setState(() {
            _completionImagePath = 'pref:$key';
          });
        } else {
          setState(() {
            _completionImagePath = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<Widget> _buildImagePreview() async {
    if (_completionImagePath == null) return const SizedBox.shrink();

    if (_completionImagePath!.startsWith('pref:')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = _completionImagePath!.replaceFirst('pref:', '');
        final base64Image = prefs.getString(key);
        if (base64Image != null) {
          final bytes = base64Decode(base64Image);
          return Image.memory(
            bytes,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        }
      } catch (e) {
        debugPrint('Error loading image: $e');
      }
      return const SizedBox.shrink();
    } else if (!kIsWeb) {
      try {
        // Use dynamic to avoid type issues with conditional imports
        // On mobile, File will be from dart:io
        // ignore: avoid_web_libraries_in_flutter
        final file = File(_completionImagePath!);
        final exists = await file.exists() as bool;
        if (exists) {
          // Cast to dynamic to avoid type mismatch with conditional imports
          return Image.file(
            file as dynamic,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 48),
              );
            },
          );
        }
      } catch (e) {
        debugPrint('Error loading image: $e');
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        _isCalloutJob ? 'Job Completion - Callout' : 'Job Completion',
        style: theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project: ${widget.project.name}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Completion Status
              Text(
                'Is the job completed?',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Completed'),
                      selected: _isCompleted == true,
                      onSelected: (selected) {
                        setState(() {
                          _isCompleted = selected ? true : null;
                          if (!selected) {
                            _reasonController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Not Completed'),
                      selected: _isCompleted == false,
                      onSelected: (selected) {
                        setState(() {
                          _isCompleted = selected ? false : null;
                          if (!selected) {
                            _reasonController.clear();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Conditional fields based on completion status
              if (_isCompleted == false) ...[
                // Reason required if not completed
                Text(
                  'Reason for not completing: *',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Please provide a reason...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else if (_isCompleted == true && _isCalloutJob) ...[
                // Image required for callout jobs when completed
                Text(
                  'Completion Image: *',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (_completionImagePath == null)
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickCompletionImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Take Photo'),
                  )
                else
                  FutureBuilder<Widget>(
                    future: _buildImagePreview(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [
                            snapshot.data!,
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _pickCompletionImage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retake'),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _completionImagePath = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Remove'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () {
                  Navigator.of(context).pop(
                    JobCompletionResult(
                      isCompleted: _isCompleted!,
                      completionReason: _isCompleted == false
                          ? _reasonController.text.trim()
                          : null,
                      completionImagePath: _completionImagePath,
                    ),
                  );
                }
              : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

