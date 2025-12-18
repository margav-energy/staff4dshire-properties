import '../config/api_config.dart';
import '../models/company_invitation_model.dart';
import 'api_service.dart';

class CompanyInvitationApiService {
  /// Create an invitation for a company
  static Future<CompanyInvitation> createInvitation({
    required String companyId,
    required String email,
    String role = 'admin',
    String? invitedById,
    int expiresInDays = 7,
    String? baseUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'company_id': companyId,
        'email': email,
        'role': role,
        'invited_by': invitedById,
        'expires_in_days': expiresInDays,
      };
      
      // Include base URL for email links (use production URL or provided URL)
      if (baseUrl != null) {
        data['base_url'] = baseUrl;
      }
      
      final response = await ApiService.post('/company-invitations', data);
      
      return CompanyInvitation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('CompanyInvitationApiService.createInvitation error: $e');
      rethrow;
    }
  }

  /// Get invitation by token
  static Future<CompanyInvitation> getInvitationByToken(String token) async {
    try {
      final response = await ApiService.get('/company-invitations/token/${Uri.encodeComponent(token)}');
      return CompanyInvitation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('CompanyInvitationApiService.getInvitationByToken error: $e');
      rethrow;
    }
  }

  /// Get all invitations for a company
  static Future<List<CompanyInvitation>> getInvitationsByCompany(String companyId) async {
    try {
      final response = await ApiService.get('/company-invitations/company/$companyId');
      if (response is List) {
        return response.map((json) => CompanyInvitation.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('CompanyInvitationApiService.getInvitationsByCompany error: $e');
      rethrow;
    }
  }

  /// Mark invitation as used
  static Future<CompanyInvitation> markInvitationAsUsed(String invitationId) async {
    try {
      final response = await ApiService.put('/company-invitations/$invitationId/use', {});
      return CompanyInvitation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('CompanyInvitationApiService.markInvitationAsUsed error: $e');
      rethrow;
    }
  }

  /// Delete invitation
  static Future<void> deleteInvitation(String invitationId) async {
    try {
      await ApiService.delete('/company-invitations/$invitationId');
    } catch (e) {
      print('CompanyInvitationApiService.deleteInvitation error: $e');
      rethrow;
    }
  }
}

