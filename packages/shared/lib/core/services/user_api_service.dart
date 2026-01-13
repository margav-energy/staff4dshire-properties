import 'dart:convert';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart' show UserRole;
import 'api_service.dart';

/// API service for user-related operations
class UserApiService {
  // Convert backend API response to UserModel
  static UserModel _fromApiJson(Map<String, dynamic> json) {
    UserRole userRole = UserRole.staff;
    final roleStr = (json['role'] as String? ?? '').toLowerCase();
    if (roleStr == 'superadmin') {
      userRole = UserRole.superadmin;
    } else if (roleStr == 'admin') {
      userRole = UserRole.admin;
    } else if (roleStr == 'supervisor') {
      userRole = UserRole.supervisor;
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      role: userRole,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
      companyId: json['company_id'] as String?,
      isSuperadmin: (json['is_superadmin'] ?? false) as bool || userRole == UserRole.superadmin,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : (json['lastLogin'] != null
              ? DateTime.parse(json['lastLogin'] as String)
              : null),
    );
  }

  // Convert UserModel to backend API format
  static Map<String, dynamic> _toApiJson(UserModel user) {
    final roleString = user.role.toString().split('.').last;
    // Ensure role is one of the valid values
    final validRoles = ['superadmin', 'admin', 'supervisor', 'staff'];
    final role = validRoles.contains(roleString) ? roleString : 'staff';
    
    return {
      'email': user.email.trim(),
      'first_name': user.firstName.trim(),
      'last_name': user.lastName.trim(),
      'role': role,
      'phone_number': user.phoneNumber?.trim().isEmpty == true ? null : user.phoneNumber?.trim(),
      'photo_url': user.photoUrl,
      'company_id': user.companyId,
      'is_superadmin': user.isSuperadmin || user.role == UserRole.superadmin,
      'is_active': user.isActive ?? true,
      if (user.lastLogin != null) 'last_login': user.lastLogin!.toIso8601String(),
    };
  }

  /// Get all users from API (filtered by company unless superadmin)
  /// [userId] - Optional current user ID to filter by company
  static Future<List<UserModel>> getUsers({String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      String endpoint = '/users';
      if (userId != null && userId.isNotEmpty) {
        endpoint += '?userId=$userId';
      }

      print('[UserApiService] Fetching users from: $endpoint');
      final response = await ApiService.get(endpoint);
      
      List<UserModel> users = [];
      if (response is List) {
        users = response.map((json) => _fromApiJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> usersList = response['data'] as List;
        users = usersList.map((json) => _fromApiJson(json as Map<String, dynamic>)).toList();
      }
      
      print('[UserApiService] Received ${users.length} users');
      if (users.isNotEmpty && userId != null) {
        print('[UserApiService] First user company_id: ${users.first.companyId}');
        print('[UserApiService] All users and their company_ids:');
        for (var user in users) {
          print('  - ${user.email} (${user.firstName} ${user.lastName}): companyId = ${user.companyId}');
        }
      }
      
      return users;
    } catch (e) {
      print('[UserApiService] Error fetching users: $e');
      rethrow;
    }
  }

  /// Get user by ID from API
  static Future<UserModel?> getUserById(String id) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      final response = await ApiService.get('/users/$id');
      
      if (response is Map<String, dynamic>) {
        return _fromApiJson(response);
      }
      
      return null;
    } catch (e) {
      print('UserApiService.getUserById error: $e');
      return null;
    }
  }

  /// Get user by email from API
  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      final response = await ApiService.get('/users/email/${Uri.encodeComponent(email)}');
      
      if (response is Map<String, dynamic>) {
        return _fromApiJson(response);
      }
      
      return null;
    } catch (e) {
      // 404 is expected if user doesn't exist, return null silently
      // Other errors are logged but also return null
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return null;
      }
      print('UserApiService.getUserByEmail error: $e');
      return null;
    }
  }

  /// Create user via API
  static Future<UserModel> createUser(UserModel user, {String? passwordHash, String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      final data = _toApiJson(user);
      // Send as 'password' (plain text) so backend can hash it properly
      // Backend will hash it before saving
      if (passwordHash != null && passwordHash.isNotEmpty) {
        data['password'] = passwordHash; // Send as plain password, backend will hash it
      } else {
        throw Exception('Password is required');
      }
      
      // Include userId in query params so backend can get company_id
      String endpoint = '/users';
      if (userId != null && userId.isNotEmpty) {
        endpoint += '?userId=$userId';
      }

      // Validate required fields before sending
      if (data['email']?.toString().trim().isEmpty ?? true) {
        throw Exception('Email is required');
      }
      if (data['first_name']?.toString().trim().isEmpty ?? true) {
        throw Exception('First name is required');
      }
      if (data['last_name']?.toString().trim().isEmpty ?? true) {
        throw Exception('Last name is required');
      }
      if (data['role']?.toString().trim().isEmpty ?? true) {
        throw Exception('Role is required');
      }
      if (!data.containsKey('password') || (data['password']?.toString().trim().isEmpty ?? true)) {
        throw Exception('Password is required');
      }

      print('[UserApiService] Creating user with data: email=${data['email']}, first_name=${data['first_name']}, last_name=${data['last_name']}, role=${data['role']}, has_password=${data.containsKey('password')}, password_length=${data['password']?.toString().length ?? 0}, userId=$userId');
      print('[UserApiService] Full data being sent: ${jsonEncode(data)}');

      final response = await ApiService.post(endpoint, data);
      
      if (response is Map<String, dynamic>) {
        return _fromApiJson(response);
      }
      
      throw Exception('Invalid response from API');
    } catch (e) {
      print('[UserApiService] createUser error: $e');
      rethrow;
    }
  }

  /// Update user via API
  static Future<UserModel> updateUser(String id, UserModel user) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      final data = _toApiJson(user);
      final response = await ApiService.put('/users/$id', data);
      
      if (response is Map<String, dynamic>) {
        return _fromApiJson(response);
      }
      
      throw Exception('Invalid response from API');
    } catch (e) {
      print('UserApiService.updateUser error: $e');
      rethrow;
    }
  }

  /// Delete user via API
  static Future<void> deleteUser(String id) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      await ApiService.delete('/users/$id');
    } catch (e) {
      print('UserApiService.deleteUser error: $e');
      rethrow;
    }
  }

  /// Update user photo URL via API
  static Future<UserModel> updateUserPhoto(String id, String? photoUrl) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      final response = await ApiService.put('/users/$id', {'photo_url': photoUrl});
      
      if (response is Map<String, dynamic>) {
        return _fromApiJson(response);
      }
      
      throw Exception('Invalid response from API');
    } catch (e) {
      print('UserApiService.updateUserPhoto error: $e');
      rethrow;
    }
  }
}

