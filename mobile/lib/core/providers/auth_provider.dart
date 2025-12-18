import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user_provider.dart';
import '../models/user_model.dart';
import '../services/photo_sync_service.dart';

enum UserRole { staff, supervisor, admin, superadmin }

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? companyId; // Company/organization ID
  final bool isSuperadmin; // True if user is a superadmin
  final String? assignedProjectId; // For supervisors
  final String? assignedProjectName; // For supervisors
  final List<String> assignedProjectIds; // For staff - list of assigned regular project IDs
  final List<String> assignedCalloutProjectIds; // For staff - list of assigned callout project IDs (admin-assigned)

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.companyId,
    this.isSuperadmin = false,
    this.assignedProjectId,
    this.assignedProjectName,
    List<String>? assignedProjectIds,
    List<String>? assignedCalloutProjectIds,
  }) : assignedProjectIds = assignedProjectIds ?? [],
       assignedCalloutProjectIds = assignedCalloutProjectIds ?? [];
  
  bool get canAccessAllCompanies => isSuperadmin || role == UserRole.superadmin;

  String get name => '$firstName $lastName';
  String get displayName => firstName;
}

class AuthProvider extends ChangeNotifier {
  static const String _storageKey = 'auth_user';
  static const String _storageKeyIsAuthenticated = 'auth_is_authenticated';
  bool _isInitialized = false;
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  GoogleSignIn? _googleSignIn;
  
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    return _googleSignIn!;
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize provider - load authentication state from storage
  Future<void> initialize({UserProvider? userProvider}) async {
    // Always reload authentication state to handle hot restart
    try {
      // Reset authentication state to reload from storage
      _currentUser = null;
      _isAuthenticated = false;
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool(_storageKeyIsAuthenticated) ?? false;
      final userJsonString = prefs.getString(_storageKey);
      
      if (isAuthenticated && userJsonString != null && userJsonString.isNotEmpty) {
        final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;
        final email = userJson['email'] as String?;
        
        // Try to restore user from UserProvider if available - prioritize UserProvider data
        if (email != null && userProvider != null) {
          // Wait a bit for UserProvider to be ready and ensure it's initialized
          await Future.delayed(const Duration(milliseconds: 200));
          if (!userProvider.isInitialized) {
            await userProvider.initialize();
          }
          await Future.delayed(const Duration(milliseconds: 100));
          
          final userModel = userProvider.getUserByEmail(email);
          if (userModel != null) {
            // Always use UserModel data, especially photoUrl, as it's the source of truth
            String? finalPhotoUrl = userModel.photoUrl;
            
            // Sync photos between database and SharedPreferences
            if (finalPhotoUrl != null) {
              // If photoUrl is base64 data, sync to SharedPreferences for fast local access
              if (finalPhotoUrl.startsWith('data:image')) {
                await PhotoSyncService.syncPhotoToLocal(userModel.id, finalPhotoUrl);
              }
              // If photoUrl is pref: but photo doesn't exist locally, try to sync from database
              else if (finalPhotoUrl.startsWith('pref:')) {
                // Try to sync from SharedPreferences to database (if photo exists locally)
                await PhotoSyncService.syncPhotoToDatabase(userModel.id, finalPhotoUrl);
              }
            }
            
            _currentUser = User(
              id: userModel.id,
              firstName: userModel.firstName,
              lastName: userModel.lastName,
              email: userModel.email,
              role: userModel.role,
              photoUrl: finalPhotoUrl, // Use photoUrl from UserModel (source of truth)
              assignedProjectId: userJson['assignedProjectId'] as String?,
              assignedProjectName: userJson['assignedProjectName'] as String?,
              assignedProjectIds: userJson['assignedProjectIds'] != null
                  ? List<String>.from(userJson['assignedProjectIds'] as List)
                  : [],
              assignedCalloutProjectIds: userJson['assignedCalloutProjectIds'] != null
                  ? List<String>.from(userJson['assignedCalloutProjectIds'] as List)
                  : [],
            );
            _isAuthenticated = true;
            // Save updated state with latest photoUrl
            await _saveAuthState();
          }
        } else if (email != null) {
          // Fallback: restore basic user data from JSON
          _currentUser = User(
            id: userJson['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            firstName: userJson['firstName'] as String? ?? 'User',
            lastName: userJson['lastName'] as String? ?? '',
            email: email,
            role: _parseRole(userJson['role'] as String?),
            photoUrl: userJson['photoUrl'] as String?,
            companyId: userJson['companyId'] as String?,
            isSuperadmin: userJson['isSuperadmin'] as bool? ?? false,
            assignedProjectId: userJson['assignedProjectId'] as String?,
            assignedProjectName: userJson['assignedProjectName'] as String?,
            assignedProjectIds: userJson['assignedProjectIds'] != null
                ? List<String>.from(userJson['assignedProjectIds'] as List)
                : [],
            assignedCalloutProjectIds: userJson['assignedCalloutProjectIds'] != null
                ? List<String>.from(userJson['assignedCalloutProjectIds'] as List)
                : [],
          );
          _isAuthenticated = true;
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  UserRole _parseRole(String? roleStr) {
    if (roleStr == null) return UserRole.staff;
    switch (roleStr.toLowerCase()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      default:
        return UserRole.staff;
    }
  }
  
  // Save authentication state to storage
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null && _isAuthenticated) {
        await prefs.setBool(_storageKeyIsAuthenticated, true);
        
        // Don't store large base64 photo URLs in auth_user to avoid quota exceeded
        // Photo URLs are stored separately in SharedPreferences with key 'profile_photo_${userId}'
        String? photoUrlRef = _currentUser!.photoUrl;
        if (photoUrlRef != null && (photoUrlRef.startsWith('data:image') || photoUrlRef.length > 1000)) {
          // If it's base64 or very long, just store a reference indicator
          photoUrlRef = photoUrlRef.startsWith('pref:') ? photoUrlRef : 'pref:profile_photo_${_currentUser!.id}';
        }
        
        final userJson = {
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'firstName': _currentUser!.firstName,
          'lastName': _currentUser!.lastName,
          'role': _currentUser!.role.toString().split('.').last,
          'photoUrl': photoUrlRef,
          'companyId': _currentUser!.companyId,
          'isSuperadmin': _currentUser!.isSuperadmin,
          'assignedProjectId': _currentUser!.assignedProjectId,
          'assignedProjectName': _currentUser!.assignedProjectName,
          'assignedProjectIds': _currentUser!.assignedProjectIds,
          'assignedCalloutProjectIds': _currentUser!.assignedCalloutProjectIds,
        };
        
        final jsonString = jsonEncode(userJson);
        // Check size before storing (localStorage limit is typically 5-10MB, but be safe)
        if (jsonString.length > 1000000) { // 1MB limit
          userJson['photoUrl'] = null;
          await prefs.setString(_storageKey, jsonEncode(userJson));
        } else {
          await prefs.setString(_storageKey, jsonString);
        }
      } else {
        await prefs.setBool(_storageKeyIsAuthenticated, false);
        await prefs.remove(_storageKey);
      }
    } catch (e) {
      // If quota exceeded, try to save without photoUrl
      if (e.toString().contains('QuotaExceeded') || e.toString().contains('quota')) {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (_currentUser != null && _isAuthenticated) {
            await prefs.setString(_storageKey, jsonEncode({
              'id': _currentUser!.id,
              'email': _currentUser!.email,
              'firstName': _currentUser!.firstName,
              'lastName': _currentUser!.lastName,
              'role': _currentUser!.role.toString().split('.').last,
              // Omit photoUrl to save space
              'assignedProjectId': _currentUser!.assignedProjectId,
              'assignedProjectName': _currentUser!.assignedProjectName,
              'assignedProjectIds': _currentUser!.assignedProjectIds,
              'assignedCalloutProjectIds': _currentUser!.assignedCalloutProjectIds,
            }));
          }
        } catch (e2) {
        }
      }
    }
  }
  
  // Clear authentication state from storage
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKeyIsAuthenticated, false);
      await prefs.remove(_storageKey);
    } catch (e) {
    }
  }

  Future<bool> login(String email, String password, {UserProvider? userProvider}) async {
    // Clear previous user state first to prevent state bleeding
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    UserRole role = UserRole.staff;
    String firstName = 'John';
    String lastName = 'Doe';
    String userId = DateTime.now().millisecondsSinceEpoch.toString(); // Default ID if user not found
    String? photoUrl;
    
    // Try to find user in UserProvider by email
    if (userProvider != null) {
      final userModel = userProvider.getUserByEmail(email);
      if (userModel != null) {
        // User exists - use their actual data
        userId = userModel.id;
        firstName = userModel.firstName;
        lastName = userModel.lastName;
        role = userModel.role;
        photoUrl = userModel.photoUrl; // Get photoUrl from UserModel
        // Update last login
        await userProvider.updateUser(userModel.id, UserModel(
          id: userModel.id,
          email: userModel.email,
          firstName: userModel.firstName,
          lastName: userModel.lastName,
          role: userModel.role,
          phoneNumber: userModel.phoneNumber,
          photoUrl: userModel.photoUrl, // Preserve photoUrl
          isActive: userModel.isActive,
          lastLogin: DateTime.now(),
        ));
      } else {
        // User not found - try to extract name from email
        final emailParts = email.split('@')[0].split('.');
        if (emailParts.isNotEmpty && emailParts[0].length > 1) {
          firstName = emailParts[0].substring(0, 1).toUpperCase() + emailParts[0].substring(1).toLowerCase();
        }
        if (emailParts.length > 1 && emailParts[1].length > 1) {
          lastName = emailParts[1].substring(0, 1).toUpperCase() + emailParts[1].substring(1).toLowerCase();
        }
        
        // Determine role based on email
        if (email.toLowerCase().contains('admin')) {
          role = UserRole.admin;
          if (firstName == 'John' || firstName.isEmpty) {
            firstName = 'David';
            lastName = lastName.isEmpty ? 'Williams' : lastName;
          }
        } else if (email.toLowerCase().contains('supervisor') || email.toLowerCase().contains('super')) {
          role = UserRole.supervisor;
          if (firstName == 'John' || firstName.isEmpty) {
            firstName = 'Sarah';
            lastName = lastName.isEmpty ? 'Johnson' : lastName;
          }
        } else {
          role = UserRole.staff;
          if (firstName == 'John' || firstName.isEmpty) {
            firstName = 'John';
            lastName = lastName.isEmpty ? 'Smith' : lastName;
          }
        }
      }
    } else {
      // Fallback to email-based extraction
      final emailParts = email.split('@')[0].split('.');
      if (emailParts.isNotEmpty && emailParts[0].length > 1) {
        firstName = emailParts[0].substring(0, 1).toUpperCase() + emailParts[0].substring(1).toLowerCase();
      }
      if (emailParts.length > 1 && emailParts[1].length > 1) {
        lastName = emailParts[1].substring(0, 1).toUpperCase() + emailParts[1].substring(1).toLowerCase();
      }
      
      if (email.toLowerCase().contains('admin')) {
        role = UserRole.admin;
      } else if (email.toLowerCase().contains('supervisor') || email.toLowerCase().contains('super')) {
        role = UserRole.supervisor;
      }
    }

    _currentUser = User(
      id: userId, // Use actual user ID from UserProvider
      firstName: firstName,
      lastName: lastName,
      email: email,
      role: role,
      photoUrl: photoUrl,
      assignedProjectIds: [], // Projects are now checked via project.assignedStaffIds
      assignedCalloutProjectIds: [], // Projects are now checked via project.assignedStaffIds
    );

    _isAuthenticated = true;
    _isLoading = false;
    _errorMessage = null;
    
    // Ensure UserProvider is loaded and refresh photoUrl from it to get the latest
    if (userProvider != null) {
      await userProvider.loadUsers();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Try to get user by email
      UserModel? updatedUserModel = userProvider.getUserByEmail(email);
      if (updatedUserModel == null) {
        // Fallback: try by ID
        updatedUserModel = userProvider.getUserById(userId);
      }
      
      if (updatedUserModel != null) {
        if (updatedUserModel.photoUrl != null && updatedUserModel.photoUrl!.isNotEmpty) {
          // Sync photos between database and SharedPreferences
          String? finalPhotoUrl = updatedUserModel.photoUrl;
          if (finalPhotoUrl != null) {
            // If photoUrl is base64 data, sync to SharedPreferences for fast local access
            if (finalPhotoUrl.startsWith('data:image')) {
              await PhotoSyncService.syncPhotoToLocal(updatedUserModel.id, finalPhotoUrl);
            }
            // If photoUrl is pref: but photo doesn't exist locally, try to sync from database
            else if (finalPhotoUrl.startsWith('pref:')) {
              // Try to sync from SharedPreferences to database (if photo exists locally)
              await PhotoSyncService.syncPhotoToDatabase(updatedUserModel.id, finalPhotoUrl);
            }
          }
          
          // Update photoUrl from UserProvider (source of truth)
          _currentUser = User(
            id: _currentUser!.id,
            firstName: _currentUser!.firstName,
            lastName: _currentUser!.lastName,
            email: _currentUser!.email,
            role: _currentUser!.role,
            photoUrl: finalPhotoUrl, // Get latest photoUrl
            assignedProjectIds: _currentUser!.assignedProjectIds,
            assignedCalloutProjectIds: _currentUser!.assignedCalloutProjectIds,
          );
        } else {
        }
      } else {
      }
    }
    
    await _saveAuthState(); // Save authentication state
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      // Clear assigned project on logout
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      await _clearAuthState(); // Clear authentication state from storage
      
      // Sign out from Google if signed in
      try {
        try {
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }
        } catch (e) {
          // Ignore Google sign out errors
        }
      } catch (e) {
        // Ignore Google sign out errors
      }
      
      notifyListeners();
    } catch (e) {
      // Still clear user state even if there's an error
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? photoPath,
    String? userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call for registration
      await Future.delayed(const Duration(seconds: 1));

      // Check if email already exists (in real app, this would be checked against backend)
      // For now, we'll simulate a check
      
      // Mock registration - in real app, this would create user on backend
      // Always default to staff role - admin can update from dashboard
      const UserRole role = UserRole.staff;
      
      final finalUserId = userId ?? DateTime.now().millisecondsSinceEpoch.toString();
      _currentUser = User(
        id: finalUserId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        photoUrl: photoPath,
        assignedProjectIds: [],
        assignedCalloutProjectIds: [],
      );

      _isAuthenticated = true;
      _isLoading = false;
      _errorMessage = null;
      await _saveAuthState(); // Save authentication state
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if running on web
      if (kIsWeb) {
        _isLoading = false;
        _errorMessage = 'Google Sign-In on web requires ClientID configuration. Please use email/password login for now.';
        notifyListeners();
        return false;
      }

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      // Get user details from Google
      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'User';
      final photoUrl = googleUser.photoUrl;
      
      // Split name into first and last
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      final lastName = nameParts.length > 1 
          ? nameParts.sublist(1).join(' ') 
          : '';

      // Simulate API call to authenticate/register with backend
      await Future.delayed(const Duration(seconds: 1));

      // Determine role based on email for demo purposes
      UserRole role = UserRole.staff;
      
      if (email.toLowerCase().contains('admin')) {
        role = UserRole.admin;
      } else if (email.toLowerCase().contains('supervisor') || 
                 email.toLowerCase().contains('super')) {
        role = UserRole.supervisor;
      } else {
        role = UserRole.staff;
      }

      _currentUser = User(
        id: googleUser.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        photoUrl: photoUrl,
        assignedProjectIds: role == UserRole.staff ? ['1', '2', '3'] : [],
        assignedCalloutProjectIds: role == UserRole.staff ? ['callout-1'] : [],
      );

      _isAuthenticated = true;
      _isLoading = false;
      _errorMessage = null;
      await _saveAuthState(); // Save authentication state
      notifyListeners();
      return true;
    } catch (e) {
      // Provide user-friendly error messages
      String errorMsg = 'Google sign-in failed';
      final errorStr = e.toString();
      
      if (errorStr.contains('ClientID') || errorStr.contains('client_id')) {
        errorMsg = 'Google Sign-In requires ClientID configuration. Please use email/password login for now.';
      } else if (errorStr.contains('network')) {
        errorMsg = 'Network error. Please check your internet connection.';
      } else {
        errorMsg = errorStr.length > 100 
            ? 'Google sign-in failed. Please try again or use email/password login.'
            : errorStr;
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  void setUserRole(UserRole role) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        email: _currentUser!.email,
        role: role,
        photoUrl: _currentUser!.photoUrl,
        assignedProjectId: _currentUser!.assignedProjectId,
        assignedProjectName: _currentUser!.assignedProjectName,
        assignedProjectIds: _currentUser!.assignedProjectIds,
        assignedCalloutProjectIds: _currentUser!.assignedCalloutProjectIds,
      );
      notifyListeners();
    }
  }

  void setAssignedProject(String? projectId, String? projectName) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        email: _currentUser!.email,
        role: _currentUser!.role,
        photoUrl: _currentUser!.photoUrl,
        assignedProjectId: projectId,
        assignedProjectName: projectName,
        assignedProjectIds: _currentUser!.assignedProjectIds,
        assignedCalloutProjectIds: _currentUser!.assignedCalloutProjectIds,
      );
      _saveAuthState();
      notifyListeners();
    }
  }

  // Method to assign callout projects to staff (admin only)
  void assignCalloutProjectToStaff(String staffId, String calloutProjectId) {
    // In real app, this would update via API
    // For now, this is a placeholder - would need to update the user in the user provider
    notifyListeners();
  }

  // Method to get callout projects assigned to current user
  List<String> getAssignedCalloutProjects() {
    return _currentUser?.assignedCalloutProjectIds ?? [];
  }

  // Refresh current user data from UserProvider (e.g., when profile is updated)
  Future<void> refreshCurrentUser({UserProvider? userProvider}) async {
    if (_currentUser == null || userProvider == null) return;
    
    final userModel = userProvider.getUserByEmail(_currentUser!.email);
    if (userModel != null) {
      _currentUser = User(
        id: userModel.id,
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        email: userModel.email,
        role: userModel.role,
        photoUrl: userModel.photoUrl, // Get updated photoUrl
        assignedProjectId: _currentUser!.assignedProjectId,
        assignedProjectName: _currentUser!.assignedProjectName,
        assignedProjectIds: _currentUser!.assignedProjectIds,
        assignedCalloutProjectIds: _currentUser!.assignedCalloutProjectIds,
      );
      await _saveAuthState(); // Save updated state
      notifyListeners();
    }
  }
}
