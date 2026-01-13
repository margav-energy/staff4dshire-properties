import '../config/api_config.dart';

/// Helper class to convert photo URLs from database format to network URLs
class PhotoUrlHelper {
  /// Convert a photo URL from database format to a network-accessible URL
  /// Handles both "pref:profile_photo_{userId}" format and direct URLs
  static String? getPhotoUrl(String? photoUrl, {String? userId}) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    // If it's a base64 data URL, return as-is (can be used directly)
    if (photoUrl.startsWith('data:image')) {
      return photoUrl;
    }

    // If it's already a full URL (http/https), return as-is
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }

    // If it's a pref: format, convert to API URL
    if (photoUrl.startsWith('pref:profile_photo_')) {
      final extractedUserId = photoUrl.replaceFirst('pref:profile_photo_', '');
      // Use the extracted userId or provided userId
      final targetUserId = extractedUserId.isNotEmpty ? extractedUserId : userId;
      if (targetUserId != null && targetUserId.isNotEmpty) {
        return '${ApiConfig.baseUrl.replaceAll('/api', '')}/api/users/$targetUserId/photo';
      }
    }

    // If it starts with /, it's a relative URL - make it absolute
    if (photoUrl.startsWith('/')) {
      return '${ApiConfig.baseUrl.replaceAll('/api', '')}$photoUrl';
    }

    // If userId is provided and photoUrl doesn't start with http, try to construct URL
    if (userId != null && userId.isNotEmpty) {
      return '${ApiConfig.baseUrl.replaceAll('/api', '')}/api/users/$userId/photo';
    }

    // Return as-is if we can't convert it
    return photoUrl;
  }
}

