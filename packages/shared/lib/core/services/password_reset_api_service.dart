import '../config/api_config.dart';
import 'api_service.dart';

class PasswordResetApiService {
  /// Request password reset (sends email with reset token)
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
    String? baseUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'email': email.trim().toLowerCase(),
      };
      
      // Use the app's actual base URL (for web, this will be the current origin)
      final appBaseUrl = baseUrl ?? ApiConfig.appBaseUrl;
      if (appBaseUrl.isNotEmpty && appBaseUrl != 'Use invitation code') {
        data['base_url'] = appBaseUrl;
      }
      
      final response = await ApiService.post('/password-reset/request', data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password using 6-digit code
  static Future<Map<String, dynamic>> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      final data = <String, dynamic>{
        'code': code,
        'new_password': newPassword,
      };
      
      final response = await ApiService.post('/password-reset/reset', data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Change password (requires authentication)
  /// skipCurrentPasswordCheck: true for mandatory password changes
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    bool skipCurrentPasswordCheck = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'new_password': newPassword,
      };
      
      if (!skipCurrentPasswordCheck) {
        data['current_password'] = currentPassword;
      } else {
        data['skip_current_password_check'] = true;
      }
      
      final response = await ApiService.post('/password-reset/change', data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Admin resets password for another user
  /// Returns the new password (if sendEmail is false) or sends it via email
  static Future<Map<String, dynamic>> adminResetPassword({
    required String userId,
    required String adminUserId,
    bool sendEmail = true,
  }) async {
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'admin_user_id': adminUserId,
        'send_email': sendEmail,
      };
      
      final response = await ApiService.post('/password-reset/admin-reset', data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}

