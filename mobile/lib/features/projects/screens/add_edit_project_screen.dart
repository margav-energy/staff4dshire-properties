import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/models/project_model.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/auth_provider.dart' show UserRole;
import '../../../core/providers/project_provider.dart' show ProjectType;
import '../../../core/providers/location_provider.dart';
import '../widgets/project_location_picker.dart';

class AddEditProjectScreen extends StatefulWidget {
  final Project? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late DateTime? _startDate;
  
  ProjectType _projectType = ProjectType.regular;
  String? _category;
  List<String> _selectedStaffIds = [];
  List<String> _selectedSupervisorIds = [];
  List<String> _photos = [];
  List<ProjectDrawing> _drawings = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  // Project location
  double? _projectLatitude;
  double? _projectLongitude;
  LocationData? _projectLocationData;
  
  // Available categories for regular projects
  static const List<String> _availableCategories = [
    'Construction',
    'Maintenance',
    'Renovation',
    'Repair',
    'Inspection',
    'Other',
  ];
  
  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    // Initialize address - show full address, not coordinates
    String? addressText = widget.project?.address;
    // If address looks like coordinates (contains comma and numbers), treat it as missing
    if (addressText != null && addressText.isNotEmpty) {
      // Check if it's coordinates format (e.g., "52.692920, -2.026500")
      final coordPattern = RegExp(r'^-?\d+\.?\d*\s*,\s*-?\d+\.?\d*$');
      if (coordPattern.hasMatch(addressText.trim())) {
        addressText = null; // Treat coordinates as missing address
      }
    }
    _addressController = TextEditingController(text: addressText ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    _startDate = widget.project?.startDate;
    _projectType = widget.project?.type ?? ProjectType.regular;
    _category = widget.project?.category;
    _selectedStaffIds = List<String>.from(widget.project?.assignedStaffIds ?? []);
    _selectedSupervisorIds = List<String>.from(widget.project?.assignedSupervisorIds ?? []);
    _photos = List<String>.from(widget.project?.photos ?? []);
    _drawings = List<ProjectDrawing>.from(widget.project?.drawings ?? []);
    
    // Load project location if available
    if (widget.project?.latitude != null && widget.project?.longitude != null) {
      _projectLatitude = widget.project!.latitude;
      _projectLongitude = widget.project!.longitude;
      // Use the address we determined above (without coordinates if detected)
      _projectLocationData = LocationData(
        latitude: widget.project!.latitude!,
        longitude: widget.project!.longitude!,
        address: addressText, // Use cleaned address
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canBeActive {
    if (_startDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    return startDay.isBefore(today) || startDay.isAtSameMomentAs(today);
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate minimum 3 photos
    if (_photos.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload at least 3 photos (currently ${_photos.length})'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Project becomes active if start date is set and in past/today
    final isActive = _canBeActive;
    
    // Validate address - don't save coordinates as address
    String? addressToSave = _addressController.text.trim();
    if (addressToSave.isNotEmpty) {
      // Check if it's coordinates format (e.g., "52.692920, -2.026500")
      final coordPattern = RegExp(r'^-?\d+\.?\d*\s*,\s*-?\d+\.?\d*$');
      if (coordPattern.hasMatch(addressToSave)) {
        // Don't save coordinates as address - only save if we have a proper address
        addressToSave = null;
      }
    }
    if (addressToSave?.isEmpty ?? true) {
      addressToSave = null;
    }

    final project = widget.project?.copyWith(
          name: _nameController.text.trim(),
          address: addressToSave,
          latitude: _projectLatitude,
          longitude: _projectLongitude,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: isActive,
          startDate: _startDate,
          type: _projectType,
          category: _category,
          assignedStaffIds: _selectedStaffIds,
          assignedSupervisorIds: _selectedSupervisorIds,
          photos: _photos,
          drawings: _drawings,
        ) ??
        Project(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _projectLatitude,
          longitude: _projectLongitude,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: isActive,
          startDate: _startDate,
          type: _projectType,
          category: _category,
          assignedStaffIds: _selectedStaffIds,
          assignedSupervisorIds: _selectedSupervisorIds,
          photos: _photos,
          drawings: _drawings,
        );

    Navigator.pop(context, project);
  }

  Future<void> _pickPhotos() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
        final List<String> newPhotos = [];
        
        for (var file in pickedFiles) {
          if (kIsWeb) {
            final bytes = await file.readAsBytes();
            final base64Image = base64Encode(bytes);
            newPhotos.add('data:image/jpeg;base64,$base64Image');
          } else {
            newPhotos.add(file.path);
          }
        }
        
        if (mounted) {
          setState(() {
            _photos.addAll(newPhotos);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking photos: $e')),
        );
      }
    }
  }

  Future<void> _pickDrawings() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'png', 'jpeg', 'jpg'],
        allowMultiple: true,
        withData: kIsWeb, // On web, we need bytes, not path
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            final fileName = file.name;
            final fileExtension = fileName.split('.').last.toLowerCase();
            
            String filePath;
            int fileSize;
            
            // Handle web and mobile differently - never access file.path on web
            if (kIsWeb) {
              // On web, use bytes property
              if (file.bytes != null) {
                filePath = 'data:application/octet-stream;base64,${base64Encode(file.bytes!)}';
                fileSize = file.bytes!.length;
              } else {
                continue; // Skip files without bytes on web
              }
            } else {
              // On mobile, use path property
              if (file.path != null) {
                filePath = file.path!;
                fileSize = File(file.path!).lengthSync();
              } else {
                continue; // Skip files without path on mobile
              }
            }

            _drawings.add(ProjectDrawing(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${_drawings.length}',
              fileName: fileName,
              filePath: filePath,
              fileType: fileExtension,
              fileSize: fileSize,
            ));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  Future<void> _selectStaff() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final staff = userProvider.getUsersByRole(UserRole.staff);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        title: 'Select Staff',
        users: staff,
        selectedIds: _selectedStaffIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStaffIds = result;
      });
    }
  }

  Future<void> _selectSupervisors() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final supervisors = userProvider.getUsersByRole(UserRole.supervisor);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        title: 'Select Supervisors',
        users: supervisors,
        selectedIds: _selectedSupervisorIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSupervisorIds = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : 'Add New Project'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'Enter project name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 24),

              // Address - Map Location Picker
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Project Address'),
                  subtitle: Text(() {
                    final addressText = _addressController.text;
                    // Check if address looks like coordinates
                    if (addressText.isEmpty) {
                      return 'Tap to select location on map';
                    }
                    // Check if it's coordinates format (e.g., "52.692920, -2.026500")
                    final coordPattern = RegExp(r'^-?\d+\.?\d*\s*,\s*-?\d+\.?\d*$');
                    if (coordPattern.hasMatch(addressText.trim())) {
                      // If it's coordinates, show placeholder instead
                      return 'Tap to select location on map';
                    }
                    // Otherwise show the full address
                    return addressText;
                  }()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selectedLocation = await Navigator.push<LocationData>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectLocationPicker(
                          initialLocation: _projectLocationData,
                          onLocationSelected: (location) {
                            setState(() {
                              _projectLocationData = location;
                              _projectLatitude = location.latitude;
                              _projectLongitude = location.longitude;
                              _addressController.text = location.address ?? '';
                            });
                          },
                        ),
                      ),
                    );
                    
                    if (selectedLocation != null) {
                      setState(() {
                        _projectLocationData = selectedLocation;
                        _projectLatitude = selectedLocation.latitude;
                        _projectLongitude = selectedLocation.longitude;
                        _addressController.text = selectedLocation.address ?? '';
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter project description',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Project Type
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Type *',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<ProjectType>(
                              title: const Text('Regular Project'),
                              subtitle: const Text('Categorized project'),
                              value: ProjectType.regular,
                              groupValue: _projectType,
                              onChanged: (value) {
                                setState(() {
                                  _projectType = value!;
                                  if (_projectType == ProjectType.callout) {
                                    _category = null;
                                  }
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<ProjectType>(
                              title: const Text('Callout Project'),
                              subtitle: const Text('Admin assigned'),
                              value: ProjectType.callout,
                              groupValue: _projectType,
                              onChanged: (value) {
                                setState(() {
                                  _projectType = value!;
                                  if (_projectType == ProjectType.callout) {
                                    _category = null;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Category (only for regular projects)
              if (_projectType == ProjectType.regular) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Category'),
                    subtitle: Text(_category ?? 'Select category (optional)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selectedCategory = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Category'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _availableCategories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return ListTile(
                                    title: const Text('None'),
                                    leading: _category == null
                                        ? const Icon(Icons.check, color: Colors.green)
                                        : null,
                                    onTap: () => Navigator.pop(context, null),
                                  );
                                }
                                final category = _availableCategories[index - 1];
                                return ListTile(
                                  title: Text(category),
                                  leading: _category == category
                                      ? const Icon(Icons.check, color: Colors.green)
                                      : null,
                                  onTap: () => Navigator.pop(context, category),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );

                      if (selectedCategory != null) {
                        setState(() {
                          _category = selectedCategory;
                        });
                      }
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Start Date
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Start Date'),
                  subtitle: Text(_startDate != null
                      ? DateFormat('MMM dd, yyyy').format(_startDate!)
                      : 'Not set - Project will remain inactive'),
                  trailing: _startDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                            });
                          },
                        )
                      : null,
                  onTap: _selectStartDate,
                ),
              ),

              // Status info based on start date
              if (_startDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _canBeActive ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _canBeActive ? Colors.green.shade300 : Colors.orange.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _canBeActive ? Icons.check_circle : Icons.info,
                          color: _canBeActive ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _canBeActive
                                ? 'Project will be active (start date is today or in the past)'
                                : 'Project will remain inactive until start date arrives',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _canBeActive ? Colors.green.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Staff Assignment
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Assign Staff'),
                  subtitle: Text(_selectedStaffIds.isEmpty
                      ? 'No staff assigned'
                      : '${_selectedStaffIds.length} staff assigned'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectStaff,
                ),
              ),

              const SizedBox(height: 16),

              // Supervisor Assignment
              Card(
                child: ListTile(
                  leading: const Icon(Icons.supervisor_account),
                  title: const Text('Assign Supervisors'),
                  subtitle: Text(_selectedSupervisorIds.isEmpty
                      ? 'No supervisors assigned'
                      : '${_selectedSupervisorIds.length} supervisors assigned'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectSupervisors,
                ),
              ),

              const SizedBox(height: 24),

              // Photos Section (Minimum 3)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_library),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Photos * (Minimum 3 required)',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${_photos.length}/3+',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _photos.length >= 3 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_photos.length < 3)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please upload at least ${3 - _photos.length} more photo(s)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickPhotos,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photos'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      if (_photos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _photos.asMap().entries.map((entry) {
                            final index = entry.key;
                            final photoPath = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
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
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _photos.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Drawings Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drawings (PDF, DOCX, PNG, JPEG)',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${_drawings.length}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload project drawings and documents',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDrawings,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Files'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      if (_drawings.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ..._drawings.asMap().entries.map((entry) {
                          final index = entry.key;
                          final drawing = entry.value;
                          return ListTile(
                            leading: Icon(_getFileIcon(drawing.fileType)),
                            title: Text(drawing.fileName),
                            subtitle: Text('${_formatFileSize(drawing.fileSize)} • ${drawing.fileType.toUpperCase()}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _drawings.removeAt(index);
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveProject,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update Project' : 'Create Project'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
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
}

class _UserSelectionDialog extends StatefulWidget {
  final String title;
  final List<dynamic> users;
  final List<String> selectedIds;

  const _UserSelectionDialog({
    required this.title,
    required this.users,
    required this.selectedIds,
  });

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.users.length,
          itemBuilder: (context, index) {
            final user = widget.users[index];
            final userId = user.id;
            final isSelected = _selectedIds.contains(userId);

            return CheckboxListTile(
              title: Text(user.fullName ?? '${user.firstName} ${user.lastName}'),
              subtitle: Text(user.email),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(userId);
                  } else {
                    _selectedIds.remove(userId);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
