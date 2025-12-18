import '../config/api_config.dart';
import '../models/company_model.dart';
import 'api_service.dart';

/// API service for company-related operations
class CompanyApiService {
  /// Get all companies from API (superadmin only)
  static Future<List<Company>> getCompanies({String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      String endpoint = '/companies';
      if (userId != null) {
        endpoint += '?userId=$userId';
      }

      final response = await ApiService.get(endpoint);
      
      if (response is List) {
        return response.map((json) => Company.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> companies = response['data'] as List;
        return companies.map((json) => Company.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      print('CompanyApiService.getCompanies error: $e');
      rethrow;
    }
  }

  /// Get company by ID from API
  static Future<Company?> getCompanyById(String id, {String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      String endpoint = '/companies/$id';
      if (userId != null) {
        endpoint += '?userId=$userId';
      }

      final response = await ApiService.get(endpoint);
      
      if (response is Map<String, dynamic>) {
        return Company.fromJson(response);
      }
      
      return null;
    } catch (e) {
      print('CompanyApiService.getCompanyById error: $e');
      rethrow;
    }
  }

  /// Create a new company (superadmin only)
  static Future<Company> createCompany(Map<String, dynamic> data, {String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      String endpoint = '/companies';
      if (userId != null) {
        data['created_by_user_id'] = userId;
      }

      final response = await ApiService.post(endpoint, data);
      
      if (response is Map<String, dynamic>) {
        return Company.fromJson(response);
      }
      
      throw Exception('Invalid response format');
    } catch (e) {
      print('CompanyApiService.createCompany error: $e');
      rethrow;
    }
  }

  /// Update company (superadmin or company admin)
  static Future<Company> updateCompany(String id, Map<String, dynamic> data, {String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      String endpoint = '/companies/$id';
      if (userId != null) {
        endpoint += '?userId=$userId';
      }

      final response = await ApiService.put(endpoint, data);
      
      if (response is Map<String, dynamic>) {
        return Company.fromJson(response);
      }
      
      throw Exception('Invalid response format');
    } catch (e) {
      print('CompanyApiService.updateCompany error: $e');
      rethrow;
    }
  }

  /// Delete company (superadmin only)
  static Future<void> deleteCompany(String id, {String? userId}) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      String endpoint = '/companies/$id';
      if (userId != null) {
        endpoint += '?userId=$userId';
      }

      await ApiService.delete(endpoint);
    } catch (e) {
      print('CompanyApiService.deleteCompany error: $e');
      rethrow;
    }
  }

  /// Get company statistics (users count, projects count, etc.)
  static Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    try {
      if (!ApiConfig.isApiEnabled) {
        throw Exception('API is disabled');
      }

      // This would typically be a separate endpoint like /companies/:id/stats
      // For now, we'll return empty stats and let the provider calculate from other data
      return {
        'usersCount': 0,
        'projectsCount': 0,
        'activeUsersCount': 0,
      };
    } catch (e) {
      print('CompanyApiService.getCompanyStats error: $e');
      return {
        'usersCount': 0,
        'projectsCount': 0,
        'activeUsersCount': 0,
      };
    }
  }
}

