import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

// File system imports - conditional for web compatibility
import 'dart:io' if (dart.library.html) 'file_io_stub.dart' show File, Directory;
import 'package:path_provider/path_provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/timesheet_provider.dart';
import '../../../core/providers/job_completion_provider.dart';
import '../../../core/providers/invoice_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../projects/screens/staff_project_selection_screen.dart';
import '../../../core/models/project_model.dart';
import '../widgets/fit_to_work_declaration_widget.dart';
import '../widgets/map_location_picker.dart';
import '../../projects/widgets/project_location_picker.dart';
import '../../jobs/widgets/job_completion_dialog.dart';

class SignInOutScreen extends StatefulWidget {
  const SignInOutScreen({super.key});

  @override
  State<SignInOutScreen> createState() => _SignInOutScreenState();
}

class _SignInOutScreenState extends State<SignInOutScreen> {
  Project? _selectedProject;
  String? _beforePhotoPath;
  String? _afterPhotoPath;
  final ImagePicker _imagePicker = ImagePicker();
  FitToWorkDeclaration? _fitToWorkDeclaration;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _restoreProjectFromActiveEntry();
  }

  void _restoreProjectFromActiveEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      final activeEntry = timesheetProvider.activeEntry;
      
      if (activeEntry != null && activeEntry.projectName.isNotEmpty && _selectedProject == null) {
        // Restore project from active entry
        setState(() {
          _selectedProject = Project(
            id: activeEntry.projectId,
            name: activeEntry.projectName,
            isActive: true,
          );
        });
      }
    });
  }

  Future<void> _getLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();
  }

  Future<void> _handleSignIn() async {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check fit-to-work declaration - required for sign-in
    if (_fitToWorkDeclaration == null || _fitToWorkDeclaration!.isFit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the fit-to-work declaration first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent sign-in if not fit to work
    if (_fitToWorkDeclaration!.isFit == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot sign in if you are not fit to work. Please contact your supervisor.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Capture before photo - required for sign-in
    final beforePhotoPath = await _takePhoto('before');
    if (beforePhotoPath == null) {
      // User canceled photo capture, ask if they want to proceed
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Photo Required'),
            content: const Text('A before photo is required to sign in. Please take a photo to continue.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return; // Don't proceed without photo
    }

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation == null) {
      await locationProvider.getCurrentLocation();
      if (locationProvider.currentLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please enable location services.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Validate location matches project address (except for callout projects)
    if (_selectedProject!.type != ProjectType.callout) {
      if (_selectedProject!.latitude != null && _selectedProject!.longitude != null) {
        final staffLocation = locationProvider.currentLocation!;
        final projectLat = _selectedProject!.latitude!;
        final projectLng = _selectedProject!.longitude!;
        
        // Calculate distance in meters
        final distance = Geolocator.distanceBetween(
          staffLocation.latitude,
          staffLocation.longitude,
          projectLat,
          projectLng,
        );
        
        // Allow within 100 meters (0.1 km)
        const maxDistanceMeters = 100.0;
        
        if (distance > maxDistanceMeters) {
          if (mounted) {
            final distanceKm = (distance / 1000).toStringAsFixed(2);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You are too far from the project location. Distance: ${distanceKm} km. Please move closer to the project address.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      } else {
        // Project doesn't have location set, warn but allow
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: Project location not set. Proceeding with sign-in.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
    final now = DateTime.now();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    await timesheetProvider.addEntry(
      TimeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        signInTime: now,
        projectId: _selectedProject!.id,
        projectName: _selectedProject!.name,
        location: locationProvider.currentLocation!.address ?? 
            '${locationProvider.currentLocation!.latitude.toStringAsFixed(6)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(6)}',
        latitude: locationProvider.currentLocation!.latitude,
        longitude: locationProvider.currentLocation!.longitude,
        staffId: currentUser?.id ?? 'staff1',
        staffName: currentUser?.name ?? 'Staff Member',
        beforePhoto: beforePhotoPath,
        isFitToWork: _fitToWorkDeclaration!.isFit,
        fitToWorkNotes: _fitToWorkDeclaration!.notes,
        fitToWorkDeclaredAt: _fitToWorkDeclaration!.declaredAt,
      ),
    );

    setState(() {
      _beforePhotoPath = beforePhotoPath;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully signed in!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    // Capture after photo - required for sign-out
    final afterPhotoPath = await _takePhoto('after');
    if (afterPhotoPath == null) {
      // User canceled photo capture, ask if they want to proceed
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Photo Required'),
            content: const Text('An after photo is required to sign out. Please take a photo to complete your work sign-out.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return; // Don't proceed without photo
    }

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.currentLocation == null) {
      await locationProvider.getCurrentLocation();
    }

    final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
    final activeEntry = timesheetProvider.activeEntry;
    
    if (activeEntry == null || _selectedProject == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active time entry found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show job completion dialog
    final completionResult = await JobCompletionDialog.show(
      context,
      _selectedProject!,
      activeEntry,
    );

    if (completionResult == null) {
      // User canceled job completion dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign out cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Update time entry with sign-out time and after photo
    final updatedEntry = TimeEntry(
      id: activeEntry.id,
      signInTime: activeEntry.signInTime,
      signOutTime: DateTime.now(),
      projectId: activeEntry.projectId,
      projectName: activeEntry.projectName,
      location: activeEntry.location,
      latitude: activeEntry.latitude,
      longitude: activeEntry.longitude,
      staffId: activeEntry.staffId,
      staffName: activeEntry.staffName,
      beforePhoto: activeEntry.beforePhoto,
      afterPhoto: afterPhotoPath,
      isFitToWork: activeEntry.isFitToWork,
      fitToWorkNotes: activeEntry.fitToWorkNotes,
      fitToWorkDeclaredAt: activeEntry.fitToWorkDeclaredAt,
    );
    await timesheetProvider.updateEntry(activeEntry.id, updatedEntry);

    // Save job completion
    final jobCompletionProvider = Provider.of<JobCompletionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      try {
        final completion = await jobCompletionProvider.createCompletion(
          timeEntryId: activeEntry.id,
          projectId: activeEntry.projectId,
          userId: currentUser.id,
          isCompleted: completionResult.isCompleted,
          completionReason: completionResult.completionReason,
          completionImagePath: completionResult.completionImagePath,
        );

        // For callout jobs marked as completed, generate invoice immediately
        // For regular jobs, invoice will be generated after supervisor approval
        if (_selectedProject!.type == ProjectType.callout && completionResult.isCompleted) {
          // Calculate hours worked
          final hoursWorked = updatedEntry.duration.inMinutes / 60.0;
          // Default hourly rate (can be configured per project/user)
          const defaultHourlyRate = 25.0;
          final amount = hoursWorked * defaultHourlyRate;

          await invoiceProvider.generateInvoice(
            projectId: activeEntry.projectId,
            staffId: currentUser.id,
            timeEntryId: activeEntry.id,
            jobCompletionId: completion.id,
            amount: amount,
            hoursWorked: hoursWorked,
            hourlyRate: defaultHourlyRate,
            description: 'Callout job completion - ${_selectedProject!.name}',
          );
        }
      } catch (e) {
        debugPrint('Error saving job completion: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving job completion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completionResult.isCompleted
                ? 'Job marked as completed. Sign out successful!'
                : 'Job completion details submitted. Awaiting supervisor approval.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    setState(() {
      _selectedProject = null;
      _beforePhotoPath = null;
      _afterPhotoPath = null;
      _fitToWorkDeclaration = null; // Reset fit-to-work declaration on sign out
    });
  }

  Future<void> _selectProject() async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(builder: (context) => const StaffProjectSelectionScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedProject = result;
      });
    }
  }

  Future<Widget> _buildPhotoWidget(String photoPath) async {
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
            height: 200,
            width: double.infinity,
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
        // Use dynamic to avoid type issues with conditional imports
        // On mobile, File will be from dart:io
        // ignore: avoid_web_libraries_in_flutter
        final file = File(photoPath);
        final exists = await file.exists() as bool;
        if (exists) {
          // Cast to dynamic to avoid type mismatch with conditional imports
          return Image.file(
            file as dynamic,
            height: 200,
            width: double.infinity,
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

  // Write bytes to file (mobile only)
  Future<void> _writeBytesToFile(String filePath, Uint8List bytes) async {
    if (kIsWeb) {
      throw UnsupportedError('File writing not supported on web');
    }
    // On mobile (!kIsWeb), we can safely use dart:io File
    // Create the file using the real File class from dart:io
    // We need to use a different approach since conditional imports make this tricky
    // Use the file path directly with proper file operations
    try {
      // Since we're not on web, File will be from dart:io and has writeAsBytes
      // ignore: avoid_web_libraries_in_flutter
      final file = File(filePath);
      // Call writeAsBytes dynamically to work with conditional imports
      final result = await (file as dynamic).writeAsBytes(bytes);
      return;
    } catch (e) {
      // If direct write fails, try using path_provider with a different approach
      debugPrint('Error writing file: $e');
      rethrow;
    }
  }

  // Compress image to reduce file size
  Future<Uint8List?> _compressImage(XFile photo) async {
    try {
      final bytes = await photo.readAsBytes();
      
      if (kIsWeb) {
        // On web, use Image package for compression (if available) or return as-is with size limit
        // For now, return the bytes as-is since we've already reduced quality in pickImage
        return bytes;
      } else {
        // On mobile, we can use additional compression if needed
        // For now, return bytes as-is since pickImage already handles compression
        return bytes;
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  // Clean up old photos from SharedPreferences to free up space
  Future<void> _cleanupOldPhotos({int keepLastDays = 7}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final photoKeys = allKeys.where((key) => key.startsWith('photo_')).toList();
      
      if (photoKeys.isEmpty) return;
      
      final cutoffTime = DateTime.now().subtract(Duration(days: keepLastDays));
      final cutoffTimestamp = cutoffTime.millisecondsSinceEpoch;
      
      int cleanedCount = 0;
      for (final key in photoKeys) {
        // Extract timestamp from key like "photo_before_1764687893226"
        final parts = key.split('_');
        if (parts.length >= 3) {
          try {
            final timestamp = int.parse(parts[2]);
            if (timestamp < cutoffTimestamp) {
              await prefs.remove(key);
              cleanedCount++;
            }
          } catch (e) {
            // If we can't parse timestamp, keep the photo to be safe
            debugPrint('Could not parse timestamp from key: $key');
          }
        }
      }
      
      if (cleanedCount > 0) {
        debugPrint('Cleaned up $cleanedCount old photos from storage');
      }
    } catch (e) {
      debugPrint('Error cleaning up old photos: $e');
    }
  }

  Future<String?> _takePhoto(String label) async {
    try {
      // Let user choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${label == 'before' ? 'Before' : 'After'} Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, size: 32),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture new photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, size: 32),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (source == null) {
        return null; // User canceled
      }

      // Use lower quality and smaller max width to reduce file size
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 60, // Reduced from 85 to 60
        maxWidth: 800, // Reduced from 1920 to 800 to save space
        maxHeight: 800,
      );

      if (photo == null) {
        return null;
      }

      // Clean up old photos before storing new one (on web)
      if (kIsWeb) {
        await _cleanupOldPhotos();
      }

      if (kIsWeb) {
        // On web, convert to base64 and store in SharedPreferences
        final bytes = await photo.readAsBytes();
        final base64Image = base64Encode(bytes);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final photoKey = 'photo_${label}_$timestamp';
        
        try {
          final prefs = await SharedPreferences.getInstance();
          
          // Check size before storing (warn if too large)
          final sizeInMB = base64Image.length / (1024 * 1024);
          if (sizeInMB > 1.0) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image is too large. Please use a smaller image.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return null;
          }
          
          await prefs.setString(photoKey, base64Image);
          
          // Return a key identifier for web
          return 'pref:$photoKey';
        } catch (e) {
          if (e.toString().contains('QuotaExceeded') || e.toString().contains('quota')) {
            // Storage quota exceeded - try to clean up more and show error
            await _cleanupOldPhotos(keepLastDays: 1); // Keep only last day
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage full. Old photos have been cleaned up. Please try again.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
          rethrow;
        }
      } else {
        // On mobile, save compressed image to app directory
        try {
          final appDir = await getApplicationDocumentsDirectory();
          // ignore: avoid_web_libraries_in_flutter
          final photosDir = Directory('${appDir.path}/timesheet_photos');
          if (!await photosDir.exists()) {
            await photosDir.create(recursive: true);
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${label}_$timestamp.jpg'; // Use jpg for better compression
          final filePath = '${photosDir.path}/$fileName';
          
          // Save the original photo first, then we can compress later if needed
          // For now, just save with lower quality settings (already done in pickImage)
          await photo.saveTo(filePath);
          return filePath;
        } catch (fileError) {
          // Fallback: if file system fails, use base64 storage like web
          final bytes = await photo.readAsBytes();
          final base64Image = base64Encode(bytes);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final photoKey = 'photo_${label}_$timestamp';
          
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(photoKey, base64Image);
            return 'pref:$photoKey';
          } catch (e) {
            debugPrint('Error storing photo fallback: $e');
            rethrow;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    
    // Always check provider for active sign-in
    final activeEntry = timesheetProvider.activeEntry;
    final isSignedIn = activeEntry != null;
    final signInTime = activeEntry?.signInTime;
    
    // Restore project if we have an active entry but no selected project
    if (activeEntry != null && activeEntry.projectName.isNotEmpty && _selectedProject == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedProject = Project(
              id: activeEntry.projectId,
              name: activeEntry.projectName,
              isActive: true,
            );
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In/Out'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Status Card
              Card(
                color: isSignedIn ? Colors.green : null,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        isSignedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 64,
                        color: isSignedIn
                            ? Colors.white
                            : theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSignedIn ? 'Signed In' : 'Not Signed In',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: isSignedIn
                              ? Colors.white
                              : theme.colorScheme.secondary,
                        ),
                      ),
                      if (isSignedIn && activeEntry != null) ...[
                        if (activeEntry!.projectName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            activeEntry!.projectName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Since ${DateFormat('MMM dd, yyyy HH:mm').format(activeEntry!.signInTime)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<DateTime>(
                          stream: Stream.periodic(
                            const Duration(seconds: 1),
                            (_) => DateTime.now(),
                          ),
                          builder: (context, snapshot) {
                            final now = snapshot.data ?? DateTime.now();
                            final duration = now.difference(activeEntry!.signInTime);
                            final hours = duration.inHours;
                            final minutes = duration.inMinutes.remainder(60);
                            final seconds = duration.inSeconds.remainder(60);
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Project Selection
              Card(
                child: InkWell(
                  onTap: isSignedIn ? null : _selectProject,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project',
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeEntry?.projectName ?? _selectedProject?.name ?? 'Select Project',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: (activeEntry != null || _selectedProject != null)
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isSignedIn)
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.secondary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fit-to-Work Declaration (when not signed in)
              if (!isSignedIn) ...[
                FitToWorkDeclarationWidget(
                  initialDeclaration: _fitToWorkDeclaration,
                  onDeclarationComplete: (declaration) {
                    setState(() {
                      _fitToWorkDeclaration = declaration;
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Before Photo (when signed in)
              if (isSignedIn && activeEntry?.beforePhoto != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Before Photo',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Widget>(
                            future: _buildPhotoWidget(activeEntry!.beforePhoto!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (snapshot.hasData) {
                                return snapshot.data!;
                              }
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, size: 48),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Location Status
              Card(
                child: InkWell(
                  onTap: isSignedIn ? null : () async {
                    // Open project location picker (same as project management) for better search
                    final selectedLocation = await Navigator.push<LocationData>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectLocationPicker(
                          initialLocation: locationProvider.currentLocation,
                          onLocationSelected: (location) {
                            // Update location provider with selected location
                            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                            locationProvider.setLocation(location);
                          },
                        ),
                      ),
                    );
                    
                    if (selectedLocation != null && mounted) {
                      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                      locationProvider.setLocation(selectedLocation);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              locationProvider.currentLocation != null
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed,
                              color: locationProvider.currentLocation != null
                                  ? Colors.green
                                  : theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Location',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            if (!isSignedIn) ...[
                              IconButton(
                                icon: const Icon(Icons.map),
                                iconSize: 20,
                                tooltip: 'Select on Map',
                                onPressed: () async {
                                  // Use ProjectLocationPicker (same as project management) for better search
                                  final selectedLocation = await Navigator.push<LocationData>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectLocationPicker(
                                        initialLocation: locationProvider.currentLocation,
                                        onLocationSelected: (location) {
                                          final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                                          locationProvider.setLocation(location);
                                        },
                                      ),
                                    ),
                                  );
                                  
                                  if (selectedLocation != null && mounted) {
                                    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                                    locationProvider.setLocation(selectedLocation);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                iconSize: 20,
                                tooltip: 'Refresh Location',
                                onPressed: () {
                                  _getLocation();
                                },
                              ),
                            ] else
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                iconSize: 20,
                                tooltip: 'Refresh Location',
                                onPressed: () {
                                  _getLocation();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (locationProvider.isLoading)
                          const LinearProgressIndicator()
                        else if (locationProvider.error != null)
                          Text(
                            locationProvider.error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          )
                        else if (locationProvider.currentLocation != null)
                          Text(
                            locationProvider.currentLocation!.address ?? 
                            '${locationProvider.currentLocation!.latitude.toStringAsFixed(6)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(6)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            isSignedIn 
                                ? 'Getting location...'
                                : 'Tap to select location on map',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        if (!isSignedIn && locationProvider.currentLocation == null)
                          const SizedBox(height: 8),
                        if (!isSignedIn && locationProvider.currentLocation == null)
                          Text(
                            'Or use the map icon to select coordinates',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sign In/Out Button
              if (!isSignedIn)
                ElevatedButton.icon(
                  onPressed: _handleSignIn,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Sign In & Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Sign Out & Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),

              const SizedBox(height: 16),

              // Current Time Display
              Card(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<DateTime>(
                        stream: Stream.periodic(
                          const Duration(seconds: 1),
                          (_) => DateTime.now(),
                        ),
                        builder: (context, snapshot) {
                          final now = snapshot.data ?? DateTime.now();
                          return Text(
                            DateFormat('HH:mm:ss').format(now),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
