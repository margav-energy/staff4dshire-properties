import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  
  List<NotificationItem> get readNotifications => 
      _notifications.where((n) => n.isRead).toList();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await loadNotifications();
    _startPolling();
    _isInitialized = true;
  }

  void _startPolling() {
    // Poll for new notifications every 30 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForNewNotifications();
    });
  }

  Future<void> _checkForNewNotifications() async {
    // In a real app, this would fetch from the backend API
    // For now, we'll simulate by checking for events that should trigger notifications
    // This method can be expanded to check:
    // - New document expiry warnings
    // - Timesheet approval status changes
    // - New toolbox talks
    // - System announcements
    
    // The actual notifications will be created by event triggers (see addNotification method)
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_storageKey);
      
      if (notificationsJson != null) {
        _notifications.clear();
        for (final jsonString in notificationsJson) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          _notifications.add(NotificationItem.fromJson(json));
        }
        
        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
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

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    bool hasChanges = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
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


