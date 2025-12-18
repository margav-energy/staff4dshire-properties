import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff4dshire_shared/shared.dart';
class AddEditUserScreen extends StatefulWidget {
  final UserModel? user;

  const AddEditUserScreen({super.key, this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late UserRole _selectedRole;
  late bool _isActive;
  bool _obscurePassword = true;
  String? _photoPath;
  XFile? _selectedPhoto;
  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _firstNameController = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user?.lastName ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role ?? UserRole.staff;
    _isActive = widget.user?.isActive ?? true;
    _photoPath = widget.user?.photoUrl?.replaceFirst('pref:', '');
  }

  Future<void> _pickPhoto() async {
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

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,  // Reduce quality to 70% for smaller file size
        maxWidth: 512,     // Reduce to 512px for profile photos
        maxHeight: 512,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = pickedFile;
          _photoPath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _savePhoto(String userId) async {
    // If no new photo selected, return existing photo URL (for editing) or null (for new users)
    if (_selectedPhoto == null) {
      // When editing, preserve existing photo URL
      if (isEditing && widget.user?.photoUrl != null) {
        return widget.user?.photoUrl;
      }
      return null;
    }

    try {
      // Convert to base64 and store in SharedPreferences
      final bytes = await _selectedPhoto!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final photoKey = 'profile_photo_$userId';
      
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Check size before storing (limit to 1.5MB for base64)
        final sizeInMB = base64Image.length / (1024 * 1024);
        if (sizeInMB > 1.5) {
          throw Exception('Image is too large (${sizeInMB.toStringAsFixed(2)}MB). Please use a smaller image.');
        }
        
        await prefs.setString(photoKey, base64Image);
        return 'pref:$photoKey';
      } catch (e) {
        debugPrint('Error saving photo to SharedPreferences: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error saving photo: $e');
      // Return existing photo URL if save fails during edit
      return isEditing ? widget.user?.photoUrl : null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    String? photoUrl = widget.user?.photoUrl;
    
    // Save photo if a new one was selected (for editing, save with existing user ID)
    if (_selectedPhoto != null && isEditing && widget.user != null) {
      try {
        // Save to SharedPreferences for local caching
        final prefPhotoUrl = await _savePhoto(widget.user!.id);
        
        // Also convert to base64 for database storage
        final bytes = await _selectedPhoto!.readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = 'image/jpeg'; // Default
        photoUrl = 'data:$mimeType;base64,$base64Image';
      } catch (e) {
        debugPrint('Error saving photo during edit: $e');
        // Continue with existing photo URL if save fails
      }
    }

    final user = UserModel(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      photoUrl: photoUrl,
      isActive: _isActive,
      lastLogin: widget.user?.lastLogin,
    );

    // Return user, password, and photo info
    if (isEditing) {
      // For editing, return the user model directly (photo already saved above)
      Navigator.pop(context, user);
    } else {
      // For creating, return a map with user, password, and photo
      Navigator.pop(context, {
        'user': user,
        'password': _passwordController.text,
        'photo': _selectedPhoto,
        'photoPath': _photoPath,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Add New User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _photoPath != null
                                ? (kIsWeb
                                    ? Image.network(
                                        _photoPath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholderPhoto(theme);
                                        },
                                      )
                                    : Image.file(
                                        File(_photoPath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholderPhoto(theme);
                                        },
                                      ))
                                : _buildPlaceholderPhoto(theme),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _photoPath != null ? Icons.edit : Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickPhoto,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profile Picture',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isEditing, // Email can't be changed when editing
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'user@staff4dshire.com',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  hintText: 'Enter first name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 24),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  hintText: 'Enter last name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 24),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+44 7700 900123',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 24),

              // Password (only for new users)
              if (!isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Role Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role *',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...UserRole.values.map((role) {
                        final roleLabel = _getRoleLabel(role);
                        return RadioListTile<UserRole>(
                          title: Text(roleLabel),
                          value: role,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRole = value;
                              });
                            }
                          },
                          dense: true,
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Active Status
              Card(
                child: SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Active users can log in to the system'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  secondary: Icon(
                    _isActive ? Icons.check_circle : Icons.cancel,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveUser,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update User' : 'Create User'),
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

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return 'Superadmin';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.staff:
        return 'Staff';
    }
  }

  Widget _buildPlaceholderPhoto(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 60,
        color: theme.colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}

