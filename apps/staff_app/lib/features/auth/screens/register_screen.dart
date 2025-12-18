import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:staff4dshire_shared/shared.dart';
import '../widgets/welcome_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isUsingInvitationCode = false;
  String? _photoPath;
  XFile? _selectedPhoto;
  List<Company> _companies = [];
  String? _selectedCompanyId;
  bool _isLoadingCompanies = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoadingCompanies = true;
    });

    try {
      final companies = await CompanyApiService.getCompanies();
      setState(() {
        _companies = companies.where((c) => c.isActive).toList();
        _isLoadingCompanies = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load companies: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = pickedFile;
          if (kIsWeb) {
            // For web, we'll handle it differently
            _photoPath = pickedFile.path;
          } else {
            _photoPath = pickedFile.path;
          }
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
    if (_selectedPhoto == null) return null;

    try {
      // Convert to base64 and store in SharedPreferences (works for both web and mobile)
      final bytes = await _selectedPhoto!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final photoKey = 'profile_photo_$userId';
      
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Check size before storing
        final sizeInMB = base64Image.length / (1024 * 1024);
        if (sizeInMB > 1.0) {
          throw Exception('Image is too large. Please use a smaller image.');
        }
        
        await prefs.setString(photoKey, base64Image);
        return 'pref:$photoKey';
      } catch (e) {
        debugPrint('Error saving photo to SharedPreferences: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error saving photo: $e');
      return null;
    }
  }

  Future<void> _handleEmailRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if photo is selected
    if (_photoPath == null || _selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or select a profile picture'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Check if using invitation code
      CompanyInvitation? invitation;
      String? invitationEmail;
      UserRole? invitationRole;
      String? companyId;
      
      if (_isUsingInvitationCode && _invitationCodeController.text.trim().isNotEmpty) {
        try {
          final code = _invitationCodeController.text.trim().toUpperCase();
          invitation = await CompanyInvitationApiService.getInvitationByToken(code);
          
          if (invitation.isExpired || invitation.isUsed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid or expired invitation code. Please check and try again.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          
          invitationEmail = invitation.email;
          // Convert string role to UserRole enum
          switch (invitation.role.toLowerCase()) {
            case 'superadmin':
              invitationRole = UserRole.superadmin;
              break;
            case 'admin':
              invitationRole = UserRole.admin;
              break;
            case 'supervisor':
              invitationRole = UserRole.supervisor;
              break;
            case 'staff':
            default:
              invitationRole = UserRole.staff;
              break;
          }
          companyId = invitation.companyId;
          _selectedCompanyId = invitation.companyId; // Pre-select company from invitation
          
          // Pre-fill email if it matches invitation
          if (_emailController.text.trim().isEmpty) {
            _emailController.text = invitationEmail;
          } else if (_emailController.text.trim().toLowerCase() != invitationEmail.toLowerCase()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email does not match invitation. Please use the email from your invitation.'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to validate invitation code: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      // Use selected company ID (from invitation or dropdown)
      final finalCompanyId = companyId ?? _selectedCompanyId;
      
      // Validate company selection for non-invitation registrations
      if (!_isUsingInvitationCode && (finalCompanyId == null || finalCompanyId.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your company'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Create user first via API to get the database-generated UUID
      final userModel = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        email: invitationEmail ?? _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: invitationRole ?? UserRole.staff, // Use invitation role or default to staff
        isActive: true,
        lastLogin: null,
        companyId: finalCompanyId,
      );
      
      // Save user to database via API (this will generate a new UUID)
      final createdUser = await userProvider.addUser(
        userModel,
        password: _passwordController.text,
      );
      
      // Now we have the database UUID - save photo with this UUID
      final databaseUserId = createdUser.id;
      final photoPath = await _savePhoto(databaseUserId);
      
      // Update user's photo URL using the database UUID
      if (photoPath != null && _selectedPhoto != null) {
        try {
          // Convert photo to base64 for database storage
          final bytes = await _selectedPhoto!.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = 'image/jpeg'; // Default
          final photoUrl = 'data:$mimeType;base64,$base64Image';
          
          // Update user's photo URL in database (stores base64 for cross-device access)
          await userProvider.updateUserPhoto(databaseUserId, photoUrl);
          
          // Reload users to get updated photo URL
          await userProvider.loadUsers();
          
          // Mark invitation as used if applicable
          if (invitation != null) {
            try {
              await CompanyInvitationApiService.markInvitationAsUsed(invitation.id);
            } catch (e) {
              debugPrint('Failed to mark invitation as used: $e');
              // Don't fail registration if this fails
            }
          }
        } catch (e) {
          debugPrint('Error saving photo to database: $e');
          // Fallback: use SharedPreferences reference
          await userProvider.updateUserPhoto(databaseUserId, photoPath);
        }
      }
      
      // Register with auth provider using database UUID and photo path
      final success = await authProvider.register(
        firstName: createdUser.firstName,
        lastName: createdUser.lastName,
        email: createdUser.email,
        password: _passwordController.text,
        photoPath: photoPath,
        userId: databaseUserId,
      );

      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user != null) {
          // Navigate to onboarding IMMEDIATELY before router redirect can intercept
          // This must happen before any router redirect logic runs
          context.go('/onboarding');
          
          // Show welcome dialog after navigation
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            WelcomeDialog.show(context, user);
          }
        } else {
          throw Exception('User registration succeeded but user is null');
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              Colors.white,
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staff4dshire',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              'Properties',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Create Account',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),

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
                          'Profile Picture *',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (_photoPath == null)
                          Text(
                            'Required for dashboard display',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // First Name Field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        hintText: 'Enter your first name',
                        prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Last Name Field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
                        hintText: 'Enter your last name',
                        prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Invitation Code Section (Optional)
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    child: ExpansionTile(
                      leading: const Icon(Icons.confirmation_number),
                      title: const Text('Have an invitation code?'),
                      subtitle: const Text('Enter code from your invitation email'),
                      initiallyExpanded: false,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _isUsingInvitationCode = expanded;
                        });
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _invitationCodeController,
                            decoration: InputDecoration(
                              labelText: 'Invitation Code',
                              hintText: 'Enter code (e.g., 4TFW2J3N-P3JN-UX9E)',
                              prefixIcon: const Icon(Icons.code),
                              border: const OutlineInputBorder(),
                              helperText: 'Enter the invitation code from your email',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              setState(() {}); // Trigger rebuild
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Company Selection (only show if not using invitation code)
                  if (!_isUsingInvitationCode || _invitationCodeController.text.trim().isEmpty) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCompanyId,
                        decoration: InputDecoration(
                          labelText: 'Company *',
                          hintText: 'Select your company',
                          prefixIcon: Icon(Icons.business, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _isLoadingCompanies
                            ? [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Loading companies...'),
                                  enabled: false,
                                ),
                              ]
                            : _companies.map((company) {
                                return DropdownMenuItem<String>(
                                  value: company.id,
                                  child: Text(company.name),
                                );
                              }).toList(),
                        onChanged: _isLoadingCompanies
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCompanyId = value;
                                });
                              },
                        validator: (value) {
                          if (!_isUsingInvitationCode && (value == null || value.isEmpty)) {
                            return 'Please select your company';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Email Field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: _isUsingInvitationCode && _invitationCodeController.text.isNotEmpty,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outlined, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password Field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        hintText: 'Confirm your password',
                        prefixIcon: Icon(Icons.lock_outlined, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Already have account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
