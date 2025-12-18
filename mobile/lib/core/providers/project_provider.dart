import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

// Export ProjectType for use in other files
export '../models/project_model.dart' show ProjectType;

class ProjectProvider extends ChangeNotifier {
  static const String _storageKey = 'projects_list';
  bool _isInitialized = false;
  
  // Default projects (used as initial data)
  static final List<Project> _defaultProjects = [
    // Regular Projects - Construction Category
    Project(
      id: '1',
      name: 'City Center Development',
      address: '123 Main Street, London',
      description: 'High-rise residential building',
      isActive: true,
      type: ProjectType.regular,
      category: 'Construction',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      photos: [],
      drawings: [],
    ),
    Project(
      id: '2',
      name: 'Riverside Complex',
      address: '456 River Road, Manchester',
      description: 'Commercial and residential complex',
      isActive: true,
      type: ProjectType.regular,
      category: 'Construction',
      startDate: DateTime.now().subtract(const Duration(days: 15)),
      photos: [],
      drawings: [],
    ),
    // Regular Projects - Maintenance Category
    Project(
      id: '3',
      name: 'Park View Apartments',
      address: '789 Park Avenue, Birmingham',
      description: 'Luxury apartment complex',
      isActive: true,
      type: ProjectType.regular,
      category: 'Maintenance',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      photos: [],
      drawings: [],
    ),
    Project(
      id: '4',
      name: 'Office Building Renovation',
      address: '321 Business Park, Leeds',
      description: 'Complete office renovation project',
      isActive: true,
      type: ProjectType.regular,
      category: 'Renovation',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      photos: [],
      drawings: [],
    ),
    // Callout Projects (admin-assigned)
    Project(
      id: 'callout-1',
      name: 'Emergency Repair - Water Leak',
      address: '45 High Street, London',
      description: 'Urgent water leak repair - assigned by admin',
      isActive: true,
      type: ProjectType.callout,
      assignedStaffIds: ['1', '3'], // Assigned to staff IDs 1 and 3
      startDate: DateTime.now(),
      photos: [],
      drawings: [],
    ),
    Project(
      id: 'callout-2',
      name: 'Weekend Site Inspection',
      address: '78 Industrial Way, Manchester',
      description: 'Weekend safety inspection - assigned by admin',
      isActive: true,
      type: ProjectType.callout,
      assignedStaffIds: ['1'], // Assigned to staff ID 1
      startDate: DateTime.now(),
      photos: [],
      drawings: [],
    ),
  ];

  List<Project> _projects = [];

  List<Project> get projects => _projects.where((p) => p.isActive).toList();
  List<Project> get allProjects => _projects;

  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Initialize provider - load from API or fallback to local storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // PRIORITY 1: Try to load from API/database first (source of truth)
      if (ApiConfig.isApiEnabled) {
        try {
          await _loadFromApi();
          // If API load succeeds, save to local storage as cache
          await _saveToStorage();
          _isInitialized = true;
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('❌ CRITICAL: Failed to load projects from API: $e');
          debugPrint('⚠️  Falling back to local storage cache');
          // Continue to fallback below
        }
      }
      
      // PRIORITY 2: Load from local storage cache (if API unavailable)
      final prefs = await SharedPreferences.getInstance();
      final projectsJsonString = prefs.getString(_storageKey);
      
      if (projectsJsonString != null && projectsJsonString.isNotEmpty) {
        // Load from storage
        final List<dynamic> projectsJson = jsonDecode(projectsJsonString);
        _projects = projectsJson
            .map((json) => Project.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // PRIORITY 3: Only use defaults if no cached data exists
        debugPrint('⚠️  No projects found in cache, using default projects');
        _projects = List<Project>.from(_defaultProjects);
        await _saveToStorage();
        // Try to save defaults to API if enabled
        if (ApiConfig.isApiEnabled) {
          try {
            for (final project in _defaultProjects) {
              // Check if project already exists in API before creating
              try {
                await ApiService.get('/projects/${project.id}');
                // Project exists, skip
              } catch (e) {
                // Project doesn't exist, create it
                final apiJson = _projectToApiJson(project);
                await ApiService.post('/projects', apiJson);
              }
            }
            // Reload from API after creating defaults
            await _loadFromApi();
            await _saveToStorage();
          } catch (e) {
            debugPrint('⚠️  Failed to sync default projects to API: $e');
          }
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading projects: $e');
      // Last resort: use defaults
      if (_projects.isEmpty) {
        _projects = List<Project>.from(_defaultProjects);
        await _saveToStorage();
      }
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Load projects from API
  Future<void> _loadFromApi() async {
    try {
      final response = await ApiService.get('/projects');
      if (response is List) {
        _projects = response
            .map((json) => _projectFromApiJson(json as Map<String, dynamic>))
            .toList();
        // Also save to local storage as backup
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint('Error loading projects from API: $e');
      rethrow;
    }
  }
  
  // Convert API JSON format to Project model
  Project _projectFromApiJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      beforePhoto: json['before_photo'] as String?,
      afterPhoto: json['after_photo'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      type: (json['type'] as String?) == 'callout' ? ProjectType.callout : ProjectType.regular,
      category: json['category'] as String?,
      assignedStaffIds: json['assigned_staff_ids'] != null
          ? List<String>.from((json['assigned_staff_ids'] as List).map((id) => id.toString()))
          : [],
      assignedSupervisorIds: json['assigned_supervisor_ids'] != null
          ? List<String>.from((json['assigned_supervisor_ids'] as List).map((id) => id.toString()))
          : [],
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      drawings: json['drawings'] != null
          ? (json['drawings'] as List).map((d) => ProjectDrawing.fromJson(d as Map<String, dynamic>)).toList()
          : [],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      companyId: json['company_id'] as String?,
    );
  }
  
  // Convert Project to API JSON format
  Map<String, dynamic> _projectToApiJson(Project project) {
    return {
      'name': project.name,
      'address': project.address,
      'latitude': project.latitude,
      'longitude': project.longitude,
      'description': project.description,
      'is_active': project.isActive,
      'is_completed': project.isCompleted,
      'before_photo': project.beforePhoto,
      'after_photo': project.afterPhoto,
      'completed_at': project.completedAt?.toIso8601String(),
      'type': project.type == ProjectType.callout ? 'callout' : 'regular',
      'category': project.category,
      'photos': project.photos,
      'drawings': project.drawings.map((d) => d.toJson()).toList(),
      'assigned_staff_ids': project.assignedStaffIds,
      'assigned_supervisor_ids': project.assignedSupervisorIds,
      'start_date': project.startDate?.toIso8601String(),
      'company_id': project.companyId,
    };
  }

  Future<void> loadProjects() async {
    if (!_isInitialized) {
      await initialize();
    }
    notifyListeners();
  }

  // Force refresh of projects list
  void refreshProjects() {
    notifyListeners();
  }

  // Save projects to SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = _projects.map((project) => project.toJson()).toList();
      final projectsJsonString = jsonEncode(projectsJson);
      await prefs.setString(_storageKey, projectsJsonString);
    } catch (e) {
      debugPrint('Error saving projects: $e');
    }
  }

  Future<void> addProject(Project project) async {
    // CRITICAL: Save to API/database FIRST (source of truth)
    if (ApiConfig.isApiEnabled) {
      try {
        final apiJson = _projectToApiJson(project);
        final response = await ApiService.post('/projects', apiJson);
        // Update project with API-generated ID if needed
        if (response['id'] != null && response['id'] != project.id) {
          project = project.copyWith(id: response['id'] as String);
        }
        // Reload from API to get complete data
        await _loadFromApi();
        // Save to local storage as cache only AFTER successful API save
        await _saveToStorage();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('❌ CRITICAL: Failed to save project to database: $e');
        throw Exception('Failed to save project to database. Please check your connection and try again.');
      }
    }
    
    // Only save locally if API is disabled (for testing)
    debugPrint('⚠️  API disabled, saving project locally only');
    _projects.add(project);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateProject(String id, Project updatedProject) async {
    // CRITICAL: Save to API/database FIRST (source of truth)
    if (ApiConfig.isApiEnabled) {
      try {
        final apiJson = _projectToApiJson(updatedProject);
        await ApiService.put('/projects/$id', apiJson);
        // Reload from API to get complete data
        await _loadFromApi();
        // Save to local storage as cache only AFTER successful API save
        await _saveToStorage();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('❌ CRITICAL: Failed to update project in database: $e');
        throw Exception('Failed to update project in database. Please check your connection and try again.');
      }
    }
    
    // Only update locally if API is disabled (for testing)
    final index = _projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    // Try to delete from API first if enabled
    if (ApiConfig.isApiEnabled) {
      try {
        await ApiService.delete('/projects/$id');
        // Reload from API to get updated list
        await _loadFromApi();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Failed to delete project from API, deleting locally: $e');
        // Fall through to local storage
      }
    }
    
    // Fallback to local storage
    _projects.removeWhere((p) => p.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> toggleProjectStatus(String id) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      final project = _projects[index];
      _projects[index] = project.copyWith(
        isActive: !project.isActive,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> markProjectAsCompleted(String id, {String? beforePhoto, String? afterPhoto}) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      final project = _projects[index];
      _projects[index] = project.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        beforePhoto: beforePhoto ?? project.beforePhoto,
        afterPhoto: afterPhoto ?? project.afterPhoto,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> updateProjectPhotos(String id, {String? beforePhoto, String? afterPhoto}) async {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      final project = _projects[index];
      _projects[index] = project.copyWith(
        beforePhoto: beforePhoto ?? project.beforePhoto,
        afterPhoto: afterPhoto ?? project.afterPhoto,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }
}

