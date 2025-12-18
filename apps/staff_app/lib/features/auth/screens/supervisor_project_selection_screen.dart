import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:staff4dshire_shared/shared.dart';
import '../../projects/screens/project_selection_screen.dart';
class SupervisorProjectSelectionScreen extends StatefulWidget {
  const SupervisorProjectSelectionScreen({super.key});

  @override
  State<SupervisorProjectSelectionScreen> createState() => _SupervisorProjectSelectionScreenState();
}

class _SupervisorProjectSelectionScreenState extends State<SupervisorProjectSelectionScreen> {
  Project? _selectedProject;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
    _getLocation();
    _loadAssignedProject();
  }

  void _checkAuth() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If not authenticated, redirect to login
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      return;
    }
    
    // If not a supervisor, redirect to appropriate dashboard
    if (authProvider.currentUser?.role != UserRole.supervisor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final role = authProvider.currentUser?.role.toString().split('.').last ?? 'staff';
          context.go('/dashboard?role=$role');
        }
      });
    }
  }

  void _loadAssignedProject() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null && user.assignedProjectId != null && user.assignedProjectName != null) {
        setState(() {
          _selectedProject = Project(
            id: user.assignedProjectId!,
            name: user.assignedProjectName!,
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

  Future<void> _selectProject() async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(builder: (context) => const ProjectSelectionScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedProject = result;
      });
    }
  }

  Future<void> _signInToProject() async {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project first'),
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
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Update user with assigned project
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        // Update user in auth provider
        authProvider.setAssignedProject(_selectedProject!.id, _selectedProject!.name);
      }

      // Get location
      if (locationProvider.currentLocation == null) {
        await locationProvider.getCurrentLocation();
      }

      // Navigate to supervisor dashboard
      if (mounted) {
        context.go('/dashboard?role=supervisor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        title: const Text('Select Project'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_ind,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Supervisor Sign-In',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select your assigned project to continue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Project Selection
              Card(
                child: InkWell(
                  onTap: _selectProject,
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
                                'Assigned Project',
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedProject?.name ?? 'Select Project',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _selectedProject != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
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

              // Location Status
              Card(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (locationProvider.currentLocation!.address != null)
                              Text(
                                locationProvider.currentLocation!.address!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (locationProvider.currentLocation!.address != null)
                              const SizedBox(height: 4),
                            Text(
                              '${locationProvider.currentLocation!.latitude.toStringAsFixed(6)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(6)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Getting location...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sign In Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInToProject,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_isLoading ? 'Signing In...' : 'Sign In to Project'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

