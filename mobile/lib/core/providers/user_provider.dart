import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'auth_provider.dart' show UserRole;
import '../services/user_api_service.dart';
import '../config/api_config.dart';

class UserProvider extends ChangeNotifier {
  static const String _storageKey = 'users_list';
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  // Default users (used as initial data)
  static final List<UserModel> _defaultUsers = [
    UserModel(
      id: '1',
      email: 'john.doe@staff4dshire.com',
      firstName: 'John',
      lastName: 'Doe',
      role: UserRole.staff,
      phoneNumber: '+44 7700 900123',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    UserModel(
      id: '2',
      email: 'jane.smith@staff4dshire.com',
      firstName: 'Jane',
      lastName: 'Smith',
      role: UserRole.supervisor,
      phoneNumber: '+44 7700 900456',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
    ),
    UserModel(
      id: '3',
      email: 'mike.johnson@staff4dshire.com',
      firstName: 'Mike',
      lastName: 'Johnson',
      role: UserRole.staff,
      phoneNumber: '+44 7700 900789',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    UserModel(
      id: '4',
      email: 'admin@staff4dshire.com',
      firstName: 'Admin',
      lastName: 'User',
      role: UserRole.admin,
      phoneNumber: '+44 7700 900000',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    UserModel(
      id: '5',
      email: 'inactive@staff4dshire.com',
      firstName: 'Inactive',
      lastName: 'User',
      role: UserRole.staff,
      isActive: false,
      lastLogin: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];
  
  List<UserModel> _users = [];

  List<UserModel> get users => _users;
  List<UserModel> get activeUsers => _users.where((u) => u.isActive).toList();
  
  int get totalStaffCount => _users.where((u) => u.isActive && u.role == UserRole.staff).length;
  int get totalUsersCount => _users.length;
  int get activeUsersCount => _users.where((u) => u.isActive).length;

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }
  
  UserModel? getUserByEmail(String email) {
    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  List<UserModel> getUsersByRole(UserRole role) {
    return _users.where((u) => u.role == role).toList();
  }

  // Initialize provider - load from API or storage
  Future<void> initialize() async {
    // Allow re-initialization on hot restart
    if (_isInitialized && _users.isNotEmpty) return;
    
    try {
      // PRIORITY 1: Try to load from API/database first (source of truth)
      if (ApiConfig.isApiEnabled) {
        try {
          await _syncFromApi();
          // If API load succeeds, save to local storage as cache
          await _saveToStorage();
          _isInitialized = true;
          notifyListeners();
          return;
        } catch (e) {
          // Continue to fallback below
        }
      }
      
      // PRIORITY 2: Load from local storage cache (if API unavailable)
      await _loadFromStorage();
      
      // PRIORITY 3: Only use defaults if no cached data exists
      if (_users.isEmpty) {
        _users = List<UserModel>.from(_defaultUsers);
        await _saveToStorage();
        // Try to save defaults to API if enabled
        if (ApiConfig.isApiEnabled) {
          try {
            for (final user in _defaultUsers) {
              // Check if user already exists in API before creating
              try {
                await UserApiService.getUserByEmail(user.email);
                // User exists, skip
              } catch (e) {
                // User doesn't exist, create it
                await UserApiService.createUser(user);
              }
            }
            // Reload from API after creating defaults
            await _syncFromApi();
            await _saveToStorage();
          } catch (e) {
            // Silent fail
          }
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Last resort: use defaults
      if (_users.isEmpty) {
        _users = List<UserModel>.from(_defaultUsers);
        await _saveToStorage();
      }
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Load users from local storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJsonString = prefs.getString(_storageKey);
      
      if (usersJsonString != null && usersJsonString.isNotEmpty) {
        final List<dynamic> usersJson = jsonDecode(usersJsonString);
        _users = usersJson
            .map((json) {
              final userMap = json as Map<String, dynamic>;
              // Restore photo_url reference - will be loaded from API if needed
              // Photos stored as 'db:userId' references will be fetched from database
              return UserModel.fromJson(userMap);
            })
            .toList();
      }
    } catch (e) {
      // Clear corrupted cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
      } catch (clearError) {
        // Silent fail
      }
    }
  }
  
  // Sync users from API
  Future<void> _syncFromApi() async {
    try {
      final apiUsers = await UserApiService.getUsers();
      if (apiUsers.isNotEmpty) {
        // Keep full photo URLs in memory, only strip when saving to cache
        _users = apiUsers;
        await _saveToStorage();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadUsers() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }
    
    // Refresh from API if enabled
    if (ApiConfig.isApiEnabled) {
      try {
        await _syncFromApi();
      } catch (e) {
        // Continue with cached data
      }
    }
    
    notifyListeners();
  }

  // Save users to SharedPreferences (optimized - excludes large photo data)
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Create lightweight version without base64 photo data to save storage
      final usersJson = _users.map((u) {
        final userJson = u.toJson();
        // Replace base64 photo URLs with references to save space
        if (userJson['photo_url'] != null && userJson['photo_url'].toString().startsWith('data:image')) {
          // Store only a reference indicator, not the full base64 data
          userJson['photo_url'] = 'db:${u.id}'; // Indicates photo is in database
        }
        return userJson;
      }).toList();
      
      final encodedJson = jsonEncode(usersJson);
      final sizeInMB = encodedJson.length / (1024 * 1024);
      
      // Only save if reasonable size (under 2MB)
      if (sizeInMB <= 2.0) {
        await prefs.setString(_storageKey, encodedJson);
      } else {
        // Clear old cache to free space
        await prefs.remove(_storageKey);
      }
    } catch (e) {
      if (e.toString().contains('QuotaExceeded') || e.toString().contains('quota')) {
        // Try to clear old cache to free space
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_storageKey);
        } catch (clearError) {
          // Silent fail
        }
      }
      // Fail gracefully - users will still load from API
    }
  }

  Future<UserModel> addUser(UserModel user, {String? password}) async {
    // Check if user with same email already exists
    if (_users.any((u) => u.email.toLowerCase() == user.email.toLowerCase())) {
      throw Exception('User with this email already exists');
    }
    
    // CRITICAL: Save to API/database FIRST (source of truth)
    if (ApiConfig.isApiEnabled) {
      try {
        // Hash password if provided (for now, just pass plain text - backend should hash it)
        // TODO: Implement proper password hashing
        String? passwordHash = password;
        if (password != null && password.isNotEmpty) {
          // For now, pass plain password as hash (backend should hash it)
          // In production, use: import 'dart:convert'; import 'package:crypto/crypto.dart';
          passwordHash = password; // Backend should hash this
        }
        
        final createdUser = await UserApiService.createUser(user, passwordHash: passwordHash);
        _users.add(createdUser);
        // Save to local storage as cache only AFTER successful API save
        await _saveToStorage();
        notifyListeners();
        return createdUser;
      } catch (e) {
        throw Exception('Failed to save user to database: ${e.toString()}');
      }
    }
    
    // Only create locally if API is disabled (for testing)
    _users.add(user);
    await _saveToStorage();
    notifyListeners();
    return user;
  }

  Future<void> updateUser(String id, UserModel updatedUser) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return;
    
    // CRITICAL: Save to API/database FIRST (source of truth)
    if (ApiConfig.isApiEnabled) {
      try {
        final updatedUserFromApi = await UserApiService.updateUser(id, updatedUser);
        _users[index] = updatedUserFromApi;
        // Save to local storage as cache only AFTER successful API save
        await _saveToStorage();
        notifyListeners();
        return;
      } catch (e) {
        throw Exception('Failed to update user in database. Please check your connection and try again.');
      }
    }
    
    // Only update locally if API is disabled (for testing)
    _users[index] = updatedUser;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> deleteUser(String id) async {
    // Try to delete via API first
    if (ApiConfig.isApiEnabled) {
      try {
        await UserApiService.deleteUser(id);
        _users.removeWhere((u) => u.id == id);
        await _saveToStorage();
        notifyListeners();
        return;
      } catch (e) {
        // Continue with local delete as fallback
      }
    }
    
    // Fallback: delete locally
    _users.removeWhere((u) => u.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> toggleUserStatus(String id) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return;
    
    final user = _users[index];
    final updatedUser = UserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoUrl,
      isActive: !user.isActive,
      lastLogin: user.lastLogin,
    );
    
    // Use updateUser which handles API sync
    await updateUser(id, updatedUser);
  }
  
  // Update user role (for admin)
  Future<void> updateUserRole(String id, UserRole newRole) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return;
    
    final user = _users[index];
    final updatedUser = UserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: newRole,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoUrl,
      isActive: user.isActive,
      lastLogin: user.lastLogin,
    );
    
    // Use updateUser which handles API sync
    await updateUser(id, updatedUser);
  }
  
  // Update user photo URL
  Future<void> updateUserPhoto(String id, String? photoUrl) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return;
    
    final user = _users[index];
    final updatedUser = UserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      phoneNumber: user.phoneNumber,
      photoUrl: photoUrl,
      isActive: user.isActive,
      lastLogin: user.lastLogin,
    );
    
    // CRITICAL: Save to API/database FIRST (source of truth)
    if (ApiConfig.isApiEnabled) {
      try {
        final updatedUserFromApi = await UserApiService.updateUserPhoto(id, photoUrl);
        _users[index] = updatedUserFromApi;
        // Save to local storage as cache only AFTER successful API save
        await _saveToStorage();
        notifyListeners();
        return;
      } catch (e) {
        throw Exception('Failed to save photo to database. Please check your connection and try again.');
      }
    }
    
    // Only update locally if API is disabled (for testing)
    _users[index] = updatedUser;
    await _saveToStorage();
    notifyListeners();
  }
}

