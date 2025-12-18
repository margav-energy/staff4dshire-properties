import '../config/api_config.dart';
import 'api_service.dart';

class NotificationApiService {
  static String get _baseEndpoint => '/notifications';

  /// Fetch all notifications for a user
  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return [];
    }

    try {
      final response = await ApiService.get('$_baseEndpoint?userId=$userId');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get unread notification count for a user
  static Future<int> getUnreadCount(String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return 0;
    }

    try {
      final response = await ApiService.get('$_baseEndpoint/unread-count?userId=$userId');
      
      if (response is Map<String, dynamic> && response['count'] != null) {
        return response['count'] as int;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark a notification as read
  static Future<bool> markAsRead(String notificationId, String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return false;
    }

    try {
      await ApiService.put('$_baseEndpoint/$notificationId/read?userId=$userId', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllAsRead(String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return false;
    }

    try {
      await ApiService.put('$_baseEndpoint/read-all', {'userId': userId});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId, String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return false;
    }

    try {
      await ApiService.delete('$_baseEndpoint/$notificationId?userId=$userId');
      return true;
    } catch (e) {
      return false;
    }
  }
}


