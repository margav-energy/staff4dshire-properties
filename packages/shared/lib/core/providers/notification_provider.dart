import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_api_service.dart';
import '../config/api_config.dart';


class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String? targetUserId; // User ID this notification is for (null = all users)

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.targetUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'targetUserId': targetUserId,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type']) {
      case 'success':
        type = NotificationType.success;
        break;
      case 'warning':
        type = NotificationType.warning;
        break;
      case 'error':
        type = NotificationType.error;
        break;
      default:
        type = NotificationType.info;
    }

    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: type,
      isRead: json['isRead'] ?? false,
      relatedEntityId: json['relatedEntityId'],
      relatedEntityType: json['relatedEntityType'],
      targetUserId: json['targetUserId'],
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? relatedEntityId,
    String? relatedEntityType,
    String? targetUserId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}

enum NotificationType {
  info,
  warning,
  error,
  success,
}

class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  final StreamController<NotificationItem> _notificationStreamController =
      StreamController<NotificationItem>.broadcast();
  
  Timer? _pollingTimer;
  bool _isInitialized = false;
  
  static const String _storageKey = 'notifications_storage';

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  
  // Get notifications for a specific user (or all if null)
  List<NotificationItem> getNotificationsForUser(String? userId) {
    if (userId == null) {
      return List.unmodifiable(_notifications);
    }
    return List.unmodifiable(_notifications.where((n) => 
      n.targetUserId == null || n.targetUserId == userId
    ).toList());
  }
  
  Stream<NotificationItem> get notificationStream => _notificationStreamController.stream;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  int getUnreadCountForUser(String? userId) {
    if (userId == null) {
      return unreadCount;
    }
    return _notifications.where((n) => 
      !n.isRead && (n.targetUserId == null || n.targetUserId == userId)
    ).length;
  }
  
  List<NotificationItem> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  
  List<NotificationItem> getUnreadNotificationsForUser(String? userId) {
    if (userId == null) {
      return unreadNotifications;
    }
    return _notifications.where((n) => 
      !n.isRead && (n.targetUserId == null || n.targetUserId == userId)
    ).toList();
  }
  
  /// Play a notification sound (works on web)
  /// Note: Sound implementation requires JavaScript interop - placeholder for now
  void _playNotificationSound() {
    if (kIsWeb) {
      // TODO: Implement sound notification using Web Audio API or audio file
      // For now, notifications will appear but without sound
      // To implement properly, use package:js_interop or load an audio file
      debugPrint('🔔 New notification received - sound notification placeholder');
    }
  }
  
  List<NotificationItem> get readNotifications => 
      _notifications.where((n) => n.isRead).toList();

  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    
    await loadNotifications(userId: userId);
    _startPolling(userId: userId);
    _isInitialized = true;
  }

  String? _currentUserId;
  
  void _startPolling({String? userId}) {
    _currentUserId = userId;
    // Poll for new notifications every 30 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForNewNotifications();
    });
  }

  Future<void> _checkForNewNotifications() async {
    if (ApiConfig.isApiEnabled && _currentUserId != null && _currentUserId!.isNotEmpty) {
      try {
        await loadNotifications(userId: _currentUserId);
      } catch (e) {
        debugPrint('Error checking for new notifications: $e');
      }
    }
  }
  
  /// Refresh notifications for a user (call this when user logs in or changes)
  Future<void> refreshNotifications(String userId) async {
    _currentUserId = userId;
    await loadNotifications(userId: userId);
  }

  Future<void> loadNotifications({String? userId}) async {
    try {
      // PRIORITY 1: Try to load from API if enabled and userId provided
      if (ApiConfig.isApiEnabled && userId != null && userId.isNotEmpty) {
        try {
          final apiNotifications = await NotificationApiService.getNotifications(userId);
          
          // Track previous notification IDs to detect new ones
          final previousNotificationIds = _notifications.map((n) => n.id).toSet();
          
          _notifications.clear();
          
          for (final json in apiNotifications) {
            try {
              // Map API response to NotificationItem format
              _notifications.add(NotificationItem(
                id: json['id'] as String,
                title: json['title'] as String,
                message: json['message'] as String,
                timestamp: DateTime.parse(json['timestamp'] as String),
                type: _parseNotificationType(json['type'] as String? ?? 'info'),
                isRead: json['isRead'] as bool? ?? false,
                relatedEntityId: json['relatedEntityId'] as String?,
                relatedEntityType: json['relatedEntityType'] as String?,
                targetUserId: json['targetUserId'] as String?,
              ));
            } catch (e) {
              debugPrint('Error parsing notification: $e');
            }
          }
          
          // Sort by timestamp (newest first)
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          // Check for new notifications and play sound
          final newNotifications = _notifications.where((n) => 
            !previousNotificationIds.contains(n.id) && !n.isRead
          ).toList();
          
          if (newNotifications.isNotEmpty) {
            _playNotificationSound();
            // Emit new notifications to stream
            for (final notification in newNotifications) {
              _notificationStreamController.add(notification);
            }
          }
          
          // Save to local storage as cache
          await _saveNotifications();
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Error loading notifications from API: $e');
          // Fall through to local storage
        }
      }
      
      // PRIORITY 2: Load from local storage cache
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_storageKey);
      
      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        _notifications.clear();
        for (final jsonString in notificationsJson) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            _notifications.add(NotificationItem.fromJson(json));
          } catch (e) {
            debugPrint('Error parsing cached notification: $e');
          }
        }
        
        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }
  
  NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return NotificationType.success;
      case 'warning':
        return NotificationType.warning;
      case 'error':
        return NotificationType.error;
      default:
        return NotificationType.info;
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedEntityId,
    String? relatedEntityType,
    String? targetUserId, // User ID to send notification to (null = all users)
  }) async {
    // Check if notification already exists (prevent duplicates)
    final existingIndex = _notifications.indexWhere(
      (n) => n.title == title &&
          n.message == message &&
          n.type == type &&
          (relatedEntityId == null || n.relatedEntityId == relatedEntityId),
    );

    if (existingIndex != -1) {
      // Update timestamp if notification exists but is read
      if (_notifications[existingIndex].isRead) {
        final updated = _notifications[existingIndex].copyWith(
          timestamp: DateTime.now(),
          isRead: false,
        );
        _notifications[existingIndex] = updated;
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        await _saveNotifications();
        notifyListeners();
      }
      return;
    }

    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      targetUserId: targetUserId,
    );

    _notifications.insert(0, notification);
    
    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }
    
    // Emit to stream for real-time listeners
    _notificationStreamController.add(notification);
    
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id, {String? userId}) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      
      // Update on API if enabled
      if (ApiConfig.isApiEnabled && userId != null) {
        try {
          await NotificationApiService.markAsRead(id, userId);
        } catch (e) {
          debugPrint('Error marking notification as read on API: $e');
        }
      }
      
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    bool hasChanges = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      // Update on API if enabled
      if (ApiConfig.isApiEnabled && userId != null) {
        try {
          await NotificationApiService.markAllAsRead(userId);
        } catch (e) {
          debugPrint('Error marking all notifications as read on API: $e');
        }
      }
      
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id, {String? userId}) async {
    _notifications.removeWhere((n) => n.id == id);
    
    // Delete on API if enabled
    if (ApiConfig.isApiEnabled && userId != null) {
      try {
        await NotificationApiService.deleteNotification(id, userId);
      } catch (e) {
        debugPrint('Error deleting notification on API: $e');
      }
    }
    
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _notificationStreamController.close();
    super.dispose();
  }
}


