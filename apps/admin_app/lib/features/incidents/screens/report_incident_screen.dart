import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:staff4dshire_shared/shared.dart';
import '../../projects/widgets/project_location_picker.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  XFile? _selectedImage;
  IncidentSeverity _selectedSeverity = IncidentSeverity.medium;
  bool _isSubmitting = false;
  String? _selectedProjectId;
  String? _selectedProjectName;
  
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getLocationDisplayText(LocationData? location) {
    if (location == null) {
      return 'Tap to select location on map';
    }
    
    final address = location.address;
    if (address == null || address.isEmpty) {
      return 'Location selected (no address)';
    }
    
    // Check if address looks like coordinates (e.g., "51.5074, -0.1278")
    final coordinatesPattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    if (coordinatesPattern.hasMatch(address.trim())) {
      return 'Tap to select location on map';
    }
    
    // Return the full address
    return address;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
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
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (kIsWeb) {
      // Web only supports gallery
      await _pickImage(ImageSource.gallery);
      return;
    }

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo of the incident'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final incidentProvider = Provider.of<IncidentProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current location if available
      String? location;
      double? latitude;
      double? longitude;
      
      if (locationProvider.currentLocation != null) {
        final address = locationProvider.currentLocation!.address;
        // Only use address if it's not coordinates (check if it looks like coordinates)
        if (address != null && 
            !RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$').hasMatch(address.trim())) {
          location = address;
        }
        latitude = locationProvider.currentLocation!.latitude;
        longitude = locationProvider.currentLocation!.longitude;
      }

      // Save the incident
      debugPrint('Reporting incident with: description=${_descriptionController.text.trim()}, photoPath=${_selectedImage!.path}, severity=$_selectedSeverity, projectId=$_selectedProjectId, location=$location');
      
      await incidentProvider.reportIncident(
        reporterId: currentUser.id,
        reporterName: currentUser.name,
        description: _descriptionController.text.trim(),
        photoPath: _selectedImage!.path,
        severity: _selectedSeverity,
        projectId: _selectedProjectId,
        projectName: _selectedProjectName,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      debugPrint('Incident reported successfully. Total incidents: ${incidentProvider.incidents.length}');

      // Notify admin and supervisor users about the new incident
      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Get all admin and supervisor users
        final admins = userProvider.getUsersByRole(UserRole.admin);
        final supervisors = userProvider.getUsersByRole(UserRole.supervisor);
        
        // Notify all admins and supervisors
        for (final admin in admins) {
          await notificationProvider.addNotification(
            title: 'New Incident Reported',
            message: '${currentUser.name} reported an incident: ${_descriptionController.text.trim().length > 50 ? _descriptionController.text.trim().substring(0, 50) + "..." : _descriptionController.text.trim()}',
            type: NotificationType.warning,
            relatedEntityId: incidentProvider.incidents.isNotEmpty ? incidentProvider.incidents.last.id : null,
            relatedEntityType: 'incident',
            targetUserId: admin.id,
          );
        }
        
        for (final supervisor in supervisors) {
          await notificationProvider.addNotification(
            title: 'New Incident Reported',
            message: '${currentUser.name} reported an incident: ${_descriptionController.text.trim().length > 50 ? _descriptionController.text.trim().substring(0, 50) + "..." : _descriptionController.text.trim()}',
            type: NotificationType.warning,
            relatedEntityId: incidentProvider.incidents.isNotEmpty ? incidentProvider.incidents.last.id : null,
            relatedEntityType: 'incident',
            targetUserId: supervisor.id,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident reported successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting incident: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please provide a clear description and photo of the incident.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Incident Photo
              Text(
                'Incident Photo *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        )
                      : kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change Photo'),
                ),
              ],

              const SizedBox(height: 24),

              // Severity Selection
              Text(
                'Severity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              SegmentedButton<IncidentSeverity>(
                segments: const [
                  ButtonSegment(
                    value: IncidentSeverity.low,
                    label: Text('Low'),
                  ),
                  ButtonSegment(
                    value: IncidentSeverity.medium,
                    label: Text('Medium'),
                  ),
                  ButtonSegment(
                    value: IncidentSeverity.high,
                    label: Text('High'),
                  ),
                  ButtonSegment(
                    value: IncidentSeverity.critical,
                    label: Text('Critical'),
                  ),
                ],
                selected: {_selectedSeverity},
                onSelectionChanged: (Set<IncidentSeverity> selection) {
                  setState(() {
                    _selectedSeverity = selection.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'Description *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Describe what happened, when, where, and any relevant details...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Location (optional)
              Text(
                'Location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                child: InkWell(
                  onTap: () async {
                    try {
                      // Use full-screen route instead of dialog (ProjectLocationPicker has its own Scaffold)
                      // ProjectLocationPicker handles the pop internally, so we don't need to pop in the callback
                      final selectedLocation = await Navigator.push<LocationData>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectLocationPicker(
                            onLocationSelected: (locationData) {
                              // Don't pop here - ProjectLocationPicker will handle it
                              // This prevents double-pop which causes navigation issues
                            },
                            initialLocation: locationProvider.currentLocation,
                          ),
                        ),
                      );
                      
                      if (selectedLocation != null && mounted) {
                        locationProvider.setLocation(selectedLocation);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location selected successfully'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error selecting location: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error selecting location: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: ListTile(
                    leading: Icon(
                      locationProvider.currentLocation != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: locationProvider.currentLocation != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(
                      _getLocationDisplayText(locationProvider.currentLocation),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: locationProvider.currentLocation != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: locationProvider.currentLocation != null
                        ? null
                        : const Text('Optional: Select where the incident occurred'),
                    trailing: locationProvider.currentLocation != null
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final selectedLocation = await showDialog<LocationData>(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Container(
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height * 0.8,
                                    child: ProjectLocationPicker(
                                      onLocationSelected: (locationData) {
                                        // ProjectLocationPicker will handle the pop
                                        // Don't pop here to avoid double-pop
                                      },
                                      initialLocation: locationProvider.currentLocation,
                                    ),
                                  ),
                                ),
                              );
                              
                              if (selectedLocation != null) {
                                locationProvider.setLocation(selectedLocation);
                              }
                            },
                          )
                        : null,
                  ),
                ),
              ),
              
              // Quick location buttons
              if (locationProvider.currentLocation == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await locationProvider.getCurrentLocation();
                        },
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use Current Location'),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Report Incident',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

