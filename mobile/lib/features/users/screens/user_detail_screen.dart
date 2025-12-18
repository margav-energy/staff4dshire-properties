import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/user_model.dart';
import '../../../core/models/document_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/user_provider.dart';
import 'add_edit_user_screen.dart';
import 'user_onboarding_view_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _currentPhotoUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Get latest user data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedUser = userProvider.getUserById(widget.user.id);
      if (mounted) {
        setState(() {
          _currentPhotoUrl = updatedUser?.photoUrl ?? widget.user.photoUrl;
        });
      }
    });
    _currentPhotoUrl = widget.user.photoUrl;
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      // Let user choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profile Photo'),
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
        return; // User canceled
      }

      setState(() {
        _isUploadingPhoto = true;
      });

      // Use lower quality and smaller max width to reduce file size
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo == null) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // Convert to base64 and store in SharedPreferences (works for both web and mobile)
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);
      final photoKey = 'profile_photo_${widget.user.id}';
      
      String? photoUrl;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Check size before storing
        final sizeInMB = base64Image.length / (1024 * 1024);
        if (sizeInMB > 1.0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image is too large. Please use a smaller image.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            _isUploadingPhoto = false;
          });
          return;
        }
        
        await prefs.setString(photoKey, base64Image);
        photoUrl = 'pref:$photoKey';
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading photo: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // Update user photo URL in UserProvider
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUserPhoto(widget.user.id, photoUrl);

      // Refresh user data from provider
      final updatedUser = userProvider.getUserById(widget.user.id);
      
      setState(() {
        _currentPhotoUrl = photoUrl;
        _isUploadingPhoto = false;
      });

      // If this is the currently logged-in user, refresh their auth data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser?.id == widget.user.id) {
        await authProvider.refreshCurrentUser(userProvider: userProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_currentPhotoUrl == null) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: _getRoleColor(widget.user.role).withOpacity(0.1),
        child: Text(
          widget.user.firstName[0] + widget.user.lastName[0],
          style: TextStyle(
            fontSize: 32,
            color: _getRoleColor(widget.user.role),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Check if it's a SharedPreferences reference
    if (_currentPhotoUrl!.startsWith('pref:')) {
      return _buildPhotoFromPrefs(_currentPhotoUrl!);
    }

    // Network image (for URLs) - with fallback to initials
    return CircleAvatar(
      radius: 50,
      backgroundColor: _getRoleColor(widget.user.role).withOpacity(0.1),
      backgroundImage: NetworkImage(_currentPhotoUrl!) as ImageProvider,
      onBackgroundImageError: (exception, stackTrace) {
        // Error loading image - will fallback to child
      },
      child: Text(
        widget.user.firstName[0] + widget.user.lastName[0],
        style: TextStyle(
          fontSize: 32,
          color: _getRoleColor(widget.user.role),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhotoFromPrefs(String prefKey) {
    final actualKey = prefKey.replaceFirst('pref:', '');
    return FutureBuilder<String?>(
      future: _loadPhotoFromPrefs(actualKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 50,
            backgroundColor: _getRoleColor(widget.user.role).withOpacity(0.1),
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: 50,
            backgroundColor: _getRoleColor(widget.user.role).withOpacity(0.1),
            backgroundImage: MemoryImage(base64Decode(snapshot.data!)) as ImageProvider,
          );
        }

        return CircleAvatar(
          radius: 50,
          backgroundColor: _getRoleColor(widget.user.role).withOpacity(0.1),
          child: Text(
            widget.user.firstName[0] + widget.user.lastName[0],
            style: TextStyle(
              fontSize: 32,
              color: _getRoleColor(widget.user.role),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Future<String?> _loadPhotoFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      // Error loading photo - will return null
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get latest user data from provider and update if changed
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.getUserById(widget.user.id) ?? widget.user;
        
        // Update photo URL if it changed
        if (currentUser.photoUrl != _currentPhotoUrl && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentPhotoUrl = currentUser.photoUrl;
              });
            }
          });
        }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit User',
            onPressed: () async {
              final result = await Navigator.push<UserModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditUserScreen(user: currentUser),
                ),
              );
              
              if (result != null && mounted) {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.updateUser(currentUser.id, result);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          _buildProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: _isUploadingPhoto
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUser.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_getRoleLabel(currentUser.role)),
                      backgroundColor: _getRoleColor(currentUser.role).withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: _getRoleColor(widget.user.role),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow('Email', currentUser.email, Icons.email),
                    const SizedBox(height: 12),
                    if (currentUser.phoneNumber != null) ...[
                      _InfoRow('Phone', currentUser.phoneNumber!, Icons.phone),
                      const SizedBox(height: 12),
                    ],
                    _InfoRow(
                      'Status',
                      currentUser.isActive ? 'Active' : 'Inactive',
                      currentUser.isActive ? Icons.check_circle : Icons.cancel,
                      color: currentUser.isActive ? Colors.green : Colors.red,
                    ),
                    if (currentUser.lastLogin != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        'Last Login',
                        DateFormat('MMM dd, yyyy HH:mm').format(currentUser.lastLogin!),
                        Icons.access_time,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Onboarding Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Onboarding',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserOnboardingViewScreen(user: currentUser),
                              ),
                            );
                          },
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text('View Full Details'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'View complete onboarding information including personal details, qualifications, policies, and declarations.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User Documents Section
            Consumer<DocumentProvider>(
              builder: (context, documentProvider, child) {
                // In a real app, documents would be filtered by user ID
                final userDocuments = documentProvider.documents; // Filter by user.id when available

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
                              'Documents',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Navigate to documents filtered by user
                                context.push('/documents');
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (userDocuments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 48,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No documents found',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...userDocuments.take(5).map((doc) {
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(doc.name),
                              subtitle: Text(
                                _getDocumentTypeLabel(doc.type) +
                                    (doc.expiryDate != null
                                        ? ' • Expires: ${DateFormat('MMM dd, yyyy').format(doc.expiryDate!)}'
                                        : ''),
                              ),
                              trailing: doc.isVerified
                                  ? const Icon(Icons.verified, color: Colors.green, size: 20)
                                  : null,
                              onTap: () {
                                // Show document details
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return 'Superadmin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.staff:
        return 'Staff';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return Colors.red;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.supervisor:
        return Colors.blue;
      case UserRole.staff:
        return Colors.green;
    }
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.driverLicense:
        return 'Driver License';
      case DocumentType.compliance:
        return 'Compliance';
      case DocumentType.accreditation:
        return 'Accreditation';
      case DocumentType.cscs:
        return 'CSCS';
      case DocumentType.healthSafety:
        return 'Health & Safety';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.cpp:
        return 'CPP';
      case DocumentType.rams:
        return 'RAMS';
      case DocumentType.other:
        return 'Other';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoRow(this.label, this.value, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
