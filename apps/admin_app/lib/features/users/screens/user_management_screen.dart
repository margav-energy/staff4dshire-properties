import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_edit_user_screen.dart';
import 'user_detail_screen.dart';
import 'user_onboarding_view_screen.dart';
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  UserRole? _filterRole;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load users when screen opens (filtered by company)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      userProvider.loadUsers(userId: userId);
    });
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    var filtered = users;
    
    if (_filterRole != null) {
      filtered = filtered.where((u) => u.role == _filterRole).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((u) {
        final query = _searchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Generate Invitation Code',
            onPressed: () => _showGenerateInvitationDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add User',
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return Column(
            children: [
              // Search and Filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _filterRole == null,
                            onTap: () {
                              setState(() {
                                _filterRole = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ...UserRole.values.map((role) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: _getRoleLabel(role),
                                isSelected: _filterRole == role,
                                onTap: () {
                                  setState(() {
                                    _filterRole = role;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // User List
              Expanded(
                child: _getFilteredUsers(userProvider.users).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _getFilteredUsers(userProvider.users).length,
                    itemBuilder: (context, index) {
                      final user = _getFilteredUsers(userProvider.users)[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                            child: Text(
                              user.firstName[0] + user.lastName[0],
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    label: Text(
                                      _getRoleLabel(user.role),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: _getRoleColor(user.role),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  if (!user.isActive)
                                    const Chip(
                                      label: Text(
                                        'Inactive',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.grey,
                                      labelStyle: TextStyle(color: Colors.white),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  _OnboardingStatusChip(userId: user.id),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'onboarding',
                                child: Row(
                                  children: [
                                    Icon(Icons.description, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Onboarding'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: user.isActive ? 'deactivate' : 'activate',
                                child: Row(
                                  children: [
                                    Icon(
                                      user.isActive ? Icons.block : Icons.check_circle,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(user.isActive ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'reset',
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_reset, size: 20),
                                    SizedBox(width: 8),
                                    Text('Reset Password'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text('Delete User', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _showUserDetails(context, user);
                              } else if (value == 'onboarding') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserOnboardingViewScreen(user: user),
                                  ),
                                );
                              } else if (value == 'edit') {
                                _showEditUserDialog(context, user);
                              } else if (value == 'deactivate' || value == 'activate') {
                                _toggleUserStatus(user);
                              } else if (value == 'reset') {
                                _resetPassword(user);
                              } else if (value == 'delete') {
                                _deleteUser(context, user);
                              }
                            },
                          ),
                          onTap: () => _showUserDetails(context, user),
                        ),
                      );
                    },
                  ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditUserScreen(),
      ),
    );

    if (result != null && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = result['user'] as UserModel;
      final password = result['password'] as String?;
      final selectedPhoto = result['photo'] as XFile?;
      
      try {
        // Get current user's ID to pass to backend for company_id lookup
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.currentUser?.id;
        
        // Create user first via API to get database UUID
        final createdUser = await userProvider.addUser(
          user, 
          password: password,
          userId: currentUserId,
        );
        
        // Save photo with database UUID if photo was selected
        if (selectedPhoto != null) {
          try {
            final bytes = await selectedPhoto.readAsBytes();
            final base64Image = base64Encode(bytes);
            
            // Check size before storing (limit to 1.5MB for database storage)
            final sizeInMB = base64Image.length / (1024 * 1024);
            if (sizeInMB <= 1.5) {
              // Store photo in both SharedPreferences (for fast local access) and database (for persistence)
              final prefs = await SharedPreferences.getInstance();
              final photoKey = 'profile_photo_${createdUser.id}';
              
              // Save to SharedPreferences for local caching
              await prefs.setString(photoKey, base64Image);
              
              // Store base64 in database for cross-device persistence
              // Format: data:image/jpeg;base64,{base64data}
              final mimeType = 'image/jpeg'; // Default, could detect from file
              final photoUrl = 'data:$mimeType;base64,$base64Image';
              
              // Update user's photo URL in database
              await userProvider.updateUserPhoto(createdUser.id, photoUrl);
              
              // Reload users to get updated photo URL (filtered by company)
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id;
              await userProvider.loadUsers(userId: userId);
            } else {
              debugPrint('Image too large (${sizeInMB.toStringAsFixed(2)}MB), skipping photo save. Max size: 2MB');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo is too large. Please use an image smaller than 2MB.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error saving photo: $e');
            // Continue even if photo save fails
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ ERROR creating user: $e');
        if (mounted) {
          // Show detailed error to user
          final errorMessage = e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add user: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error Details'),
                      content: SingleChildScrollView(
                        child: Text(errorMessage),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showGenerateInvitationDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final companyId = currentUser?.companyId;
    
    if (companyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to generate invitation: Company ID not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get company name from CompanyProvider
    String? companyName;
    try {
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final company = companyProvider.getCompanyById(companyId);
      companyName = company?.name;
    } catch (e) {
      debugPrint('Error getting company name: $e');
    }

    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedRole = [UserRole.staff]; // Use a list to hold the value

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Generate Invitation Code'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (companyName != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.business, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Company: $companyName',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Role',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<UserRole>(
                        title: const Text('Staff'),
                        value: UserRole.staff,
                        groupValue: selectedRole[0],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedRole[0] = value;
                            });
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<UserRole>(
                        title: const Text('Supervisor'),
                        value: UserRole.supervisor,
                        groupValue: selectedRole[0],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedRole[0] = value;
                            });
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email (Optional)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: 'Enter email address (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If no email is provided, a general invitation code will be generated.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogContext, {
                      'role': selectedRole[0],
                      'email': emailController.text.trim(),
                    });
                  },
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();

    if (result == null) return;

    final role = result['role'] as UserRole? ?? UserRole.staff;
    final email = result['email'] as String? ?? '';

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Generate unique email if not provided
      final invitationEmail = email.isEmpty 
          ? 'invite-${DateTime.now().millisecondsSinceEpoch}@staff4dshire.local'
          : email;

      final invitation = await CompanyInvitationApiService.createInvitation(
        companyId: companyId!,
        email: invitationEmail,
        role: role == UserRole.staff ? 'staff' : 'supervisor',
        invitedById: currentUser?.id,
        expiresInDays: 30,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Get company name from invitation if not already fetched
      final displayCompanyName = invitation.companyName ?? companyName ?? 'Your Company';

      // Show invitation code dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (resultContext) => AlertDialog(
          title: const Text('Invitation Code Generated'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company: $displayCompanyName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Role: ${role == UserRole.staff ? "Staff" : "Supervisor"}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Email: $email',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invitation Code',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        invitation.invitationToken,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share this code with ${role == UserRole.staff ? "staff" : "supervisor"} members. They will need to enter it when registering.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Expires: ${_formatDate(invitation.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(resultContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating invitation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showEditUserDialog(BuildContext context, UserModel user) async {
    final result = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUserScreen(user: user),
      ),
    );

    if (result != null && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      try {
        // If photo was changed, save it first
        // Note: The photo would need to be handled separately since we're only getting UserModel back
        // For now, we'll update the user and handle photo separately if needed
        await userProvider.updateUser(user.id, result);
        
        // Check if we need to update photo (this would require checking if photo was changed)
        // For now, photos updated via this screen would need to be saved before calling updateUser
        // Or we'd need to modify the return type to include photo info
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.toggleUserStatus(user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${user.isActive ? 'deactivated' : 'activated'}'),
        ),
      );
    }
  }

  Future<void> _resetPassword(UserModel user) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Are you sure you want to reset the password for "${user.fullName}"?\n\n'
          'A new password will be generated and sent to ${user.email} via email. '
          'The user will be required to change their password on next login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Resetting password...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // Get current admin user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminUserId = authProvider.currentUser?.id;

      if (adminUserId == null) {
        throw Exception('Admin user not found');
      }

      // Call admin reset password API
      final response = await PasswordResetApiService.adminResetPassword(
        userId: user.id,
        adminUserId: adminUserId,
        sendEmail: true,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['password_sent_via_email'] == true
                ? 'Password reset email sent to ${user.email}'
                : 'Password has been reset. New password: ${response['new_password']}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting password: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    // Prevent deleting yourself
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user.fullName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.deleteUser(user.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${user.fullName}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to show onboarding status badge
class _OnboardingStatusChip extends StatefulWidget {
  final String userId;

  const _OnboardingStatusChip({required this.userId});

  @override
  State<_OnboardingStatusChip> createState() => _OnboardingStatusChipState();
}

class _OnboardingStatusChipState extends State<_OnboardingStatusChip> {
  bool _isLoading = true;
  bool _hasOnboardingData = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    // Defer async operations to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingStatus();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    if (!mounted) return;
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    try {
      await onboardingProvider.loadProgress(widget.userId);
      await onboardingProvider.loadCisOnboarding(widget.userId);
      
      if (!mounted) return;
      setState(() {
        _hasOnboardingData = onboardingProvider.progress?.step1Completed == true ||
                            onboardingProvider.cisOnboarding?.isComplete == true;
        _isComplete = onboardingProvider.isComplete || onboardingProvider.isCisComplete;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (!_hasOnboardingData) {
      return const Chip(
        label: Text(
          'Pending Onboarding',
          style: TextStyle(fontSize: 11),
        ),
        backgroundColor: Colors.orange,
        labelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return Chip(
      label: Text(
        _isComplete ? 'Onboarding Complete' : 'Onboarding In Progress',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: _isComplete ? Colors.green : Colors.blue,
      labelStyle: const TextStyle(color: Colors.white),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

