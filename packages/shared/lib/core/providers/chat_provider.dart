import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';
import '../services/chat_socket_service.dart';
import '../utils/notification_sound_player.dart';

class ChatProvider extends ChangeNotifier {
  final ChatSocketService _socketService = ChatSocketService();

  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messages = {}; // conversationId -> messages
  Map<String, Conversation> _conversationDetails = {}; // conversationId -> conversation details
  bool _isLoading = false;
  String? _currentConversationId;
  Map<String, Set<String>> _typingUsers = {}; // conversationId -> set of userIds
  bool _isInitialized = false;
  String? _initializedUserId;

  List<Conversation> get conversations => _conversations;
  List<Message> getMessages(String conversationId) => _messages[conversationId] ?? [];
  Conversation? getConversation(String conversationId) {
    final details = _conversationDetails[conversationId];
    if (details != null) return details;
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }
  bool get isLoading => _isLoading;
  String? get currentConversationId => _currentConversationId;
  Set<String> getTypingUsers(String conversationId) => _typingUsers[conversationId] ?? {};
  
  /// Get total unread message count across all conversations
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// Initialize chat provider and connect to socket
  Future<void> initialize(String userId) async {
    // Avoid double-initialization (this was causing duplicate joins + weird UI behavior)
    if (_isInitialized && _initializedUserId == userId) {
      return;
    }

    // If switching users, reset local state and reconnect
    if (_initializedUserId != null && _initializedUserId != userId) {
      _conversations = [];
      _messages = {};
      _conversationDetails = {};
      _typingUsers = {};
      _currentConversationId = null;
      _socketService.disconnect();
      _isInitialized = false;
    }

    _initializedUserId = userId;

    // Connect socket first
    _socketService.connect(userId);

    // Wait a bit for socket to connect before setting up listeners
    int attempts = 0;
    while (!_socketService.isConnected && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    // Set up socket listeners (remove old listeners first to avoid duplicates)
    _socketService.removeAllListeners();

    // Set up socket listeners BEFORE loading conversations
    _socketService.onNewMessage((data) {
      print('[ChatProvider] Received new message via socket: ${data['id']}');
      final senderId = data['senderId'] as String?;
      final conversationId = data['conversationId'] as String?;
      
      // Play sound if:
      // 1. Message is from someone else (not the current user)
      // 2. Message is from a different conversation OR from current conversation (both cases should play sound)
      final isFromOtherUser = senderId != null && senderId != _initializedUserId;
      if (isFromOtherUser) {
        _playNotificationSound();
      }
      _handleNewMessage(data);
    });

    _socketService.onUserTyping((data) {
      final conversationId = data['conversationId'] as String?;
      final userId = data['userId'] as String?;
      if (conversationId != null && userId != null) {
        _typingUsers[conversationId] ??= {};
        _typingUsers[conversationId]!.add(userId);
        notifyListeners();
      }
    });

    _socketService.onUserStoppedTyping((data) {
      final conversationId = data['conversationId'] as String?;
      final userId = data['userId'] as String?;
      if (conversationId != null && userId != null) {
        _typingUsers[conversationId]?.remove(userId);
        notifyListeners();
      }
    });

    // Listen for message updates (edits)
    _socketService.socket?.on('message-updated', (data) {
      if (data is Map<String, dynamic>) {
        try {
          final message = Message.fromJson(data);
          final conversationId = message.conversationId;
          final messages = _messages[conversationId] ?? [];
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = message;
            notifyListeners();
          }
        } catch (e) {
          print('[ChatProvider] Error handling message-updated: $e');
        }
      }
    });

    // Listen for message deletions
    _socketService.socket?.on('message-deleted', (data) {
      if (data is Map<String, dynamic>) {
        try {
          final message = Message.fromJson(data);
          final conversationId = message.conversationId;
          final messages = _messages[conversationId] ?? [];
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = message;
            notifyListeners();
          }
        } catch (e) {
          print('[ChatProvider] Error handling message-deleted: $e');
        }
      }
    });

    // Listen for messages read updates
    _socketService.onMessagesRead((data) {
      final conversationId = data['conversationId'] as String?;
      final readByUserId = data['userId'] as String?;
      
      if (conversationId != null && readByUserId != null) {
        // Update read status for messages in this conversation
        final messages = _messages[conversationId] ?? [];
        bool updated = false;
        for (var message in messages) {
          if (message.senderId != readByUserId && 
              (message.readStatus == 'sent' || message.readStatus == 'delivered')) {
            // Message is now read by this user
            final updatedMessage = Message(
              id: message.id,
              conversationId: message.conversationId,
              senderId: message.senderId,
              senderName: message.senderName,
              senderPhotoUrl: message.senderPhotoUrl,
              messageText: message.messageText,
              messageType: message.messageType,
              fileUrl: message.fileUrl,
              fileName: message.fileName,
              fileSize: message.fileSize,
              isEdited: message.isEdited,
              isDeleted: message.isDeleted,
              editedAt: message.editedAt,
              createdAt: message.createdAt,
              readStatus: 'read',
            );
            final index = messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              messages[index] = updatedMessage;
              updated = true;
            }
          }
        }
        if (updated) {
          notifyListeners();
        }
      }
    });

    // Listen for conversation deletions
    _socketService.socket?.on('conversation-deleted', (data) {
      if (data is Map<String, dynamic>) {
        try {
          final conversationId = data['conversationId'] as String?;
          if (conversationId != null) {
            _conversations.removeWhere((c) => c.id == conversationId);
            _messages.remove(conversationId);
            _conversationDetails.remove(conversationId);
            _typingUsers.remove(conversationId);
            if (_currentConversationId == conversationId) {
              _currentConversationId = null;
            }
            notifyListeners();
          }
        } catch (e) {
          print('[ChatProvider] Error handling conversation-deleted: $e');
        }
      }
    });

    // Load conversations after socket is set up
    await loadConversations(userId);

    _isInitialized = true;
  }

  /// Load all conversations for a user
  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('[ChatProvider] Loading conversations for user: $userId');
      final conversationsJson = await ChatApiService.getConversations(userId);
      print('[ChatProvider] Received ${conversationsJson.length} conversations from API');
      
      _conversations = [];
      for (var json in conversationsJson) {
        try {
          final conversation = Conversation.fromJson(json);
          _conversations.add(conversation);
        } catch (e) {
          print('[ChatProvider] Error parsing conversation: $e');
          print('[ChatProvider] Conversation JSON: $json');
        }
      }
      
      // Sort conversations by most recent activity (newest first - this is correct for chat list)
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      print('[ChatProvider] Loaded ${_conversations.length} conversations successfully');
      
      // Join all conversation rooms for real-time updates
      for (final conversation in _conversations) {
        _socketService.joinConversation(conversation.id);
      }
    } catch (e) {
      print('[ChatProvider] Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(String conversationId, {int limit = 50, String? userId}) async {
    try {
      final messagesJson = await ChatApiService.getMessages(conversationId, limit: limit, userId: userId);
      final messages = messagesJson.map((json) => Message.fromJson(json)).toList();
      // Sort messages by creation time (newest first)
      // Since ListView has reverse: true, newest will appear at bottom
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _messages[conversationId] = messages;
      print('[ChatProvider] Loaded ${messages.length} messages for conversation $conversationId');
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  /// Load conversation details
  Future<void> loadConversationDetails(String conversationId) async {
    try {
      final conversationJson = await ChatApiService.getConversation(conversationId);
      if (conversationJson != null) {
        _conversationDetails[conversationId] = Conversation.fromJson(conversationJson);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading conversation details: $e');
    }
  }

  /// Create a new conversation
  Future<Conversation?> createConversation({
    required String type,
    required List<String> userIds,
    String? projectId,
    String? name,
    String? createdBy,
  }) async {
    try {
      final conversationJson = await ChatApiService.createConversation(
        type: type,
        userIds: userIds,
        projectId: projectId,
        name: name,
        createdBy: createdBy,
      );

      if (conversationJson != null) {
        final conversation = Conversation.fromJson(conversationJson);
        _conversations.insert(0, conversation);
        _conversationDetails[conversation.id] = conversation;
        notifyListeners();
        return conversation;
      }
    } catch (e) {
      print('Error creating conversation: $e');
    }
    return null;
  }

  /// Send a message
  Future<Message?> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
    String? messageType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final messageJson = await ChatApiService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        messageText: messageText,
        messageType: messageType,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
      );

      if (messageJson != null) {
        final message = Message.fromJson(messageJson);
        
        print('[ChatProvider] ✅ Message sent successfully: ${message.id}');

        // IMPORTANT:
        // Do not insert into the local message list here.
        // The sender will also receive the socket event via the conversation room,
        // and inserting here causes duplicates + order flicker.

        // Update conversation preview optimistically (last message + move to top)
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          final conversation = _conversations[conversationIndex];
          // Remove from current position and add at top
          _conversations.removeAt(conversationIndex);
          _conversations.insert(0, Conversation(
            id: conversation.id,
            type: conversation.type,
            name: conversation.name,
            projectId: conversation.projectId,
            companyId: conversation.companyId,
            createdBy: conversation.createdBy,
            createdAt: conversation.createdAt,
            updatedAt: DateTime.now(),
            lastMessage: message,
            participantIds: conversation.participantIds,
            participants: conversation.participants,
            unreadCount: conversation.unreadCount,
          ));
          print('[ChatProvider] ✅ Updated conversation ${conversationId} with new message');
        }

        notifyListeners();
        return message;
      }
    } catch (e) {
      print('Error sending message: $e');
    }
    return null;
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await ChatApiService.markAsRead(conversationId, userId);
      
      // Update local conversation unread count
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        final conversation = _conversations[conversationIndex];
        _conversations[conversationIndex] = Conversation(
          id: conversation.id,
          type: conversation.type,
          name: conversation.name,
          projectId: conversation.projectId,
          companyId: conversation.companyId,
          createdBy: conversation.createdBy,
          createdAt: conversation.createdAt,
          updatedAt: conversation.updatedAt,
          lastMessage: conversation.lastMessage,
          participantIds: conversation.participantIds,
          participants: conversation.participants,
          unreadCount: 0,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  /// Clear current conversation when user leaves the chat screen.
  /// This ensures unread badges + notification sounds work while user is on other screens.
  void clearCurrentConversation() {
    _currentConversationId = null;
  }

  /// Set current conversation and join socket room
  void setCurrentConversation(String conversationId) {
    print('[ChatProvider] Setting current conversation: $conversationId');
    
    // Always ensure we're joined to this conversation room
    if (_socketService.isConnected) {
      _socketService.joinConversation(conversationId);
      print('[ChatProvider] Joined conversation room: $conversationId');
    } else {
      print('[ChatProvider] ⚠️ Socket not connected, cannot join conversation room');
    }
    
    if (_currentConversationId != conversationId) {
      // Leave previous conversation room (but keep it in our joined list for receiving messages)
      // Actually, we should stay in all conversation rooms to receive messages
      // Only leave if we really need to (for now, don't leave)
      
      _currentConversationId = conversationId;
      
      // Note: loadMessages will be called by the UI with userId
      // Load conversation details (includes participant info)
      loadConversationDetails(conversationId);
      
      // Also ensure this conversation is in our conversations list
      if (!_conversations.any((c) => c.id == conversationId)) {
        print('[ChatProvider] ⚠️ Conversation $conversationId not in list, reloading conversations...');
        // Will need userId to reload - this should be handled by the caller
      }
    } else if (_messages[conversationId] == null || _messages[conversationId]!.isEmpty) {
      // If already current conversation but no messages, reload them
      // Note: UI should call loadMessages with userId
      print('[ChatProvider] No messages for current conversation, reloading...');
    }
  }

  /// Send typing indicator
  void sendTyping({
    required String conversationId,
    required String userId,
    required String userName,
  }) {
    _socketService.sendTyping(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
    );
  }

  /// Send stop typing indicator
  void sendStopTyping({
    required String conversationId,
    required String userId,
  }) {
    _socketService.sendStopTyping(
      conversationId: conversationId,
      userId: userId,
    );
  }

  /// Handle new message from socket
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data);
      final conversationId = message.conversationId;

      print('[ChatProvider] Handling new message: ${message.id} for conversation: $conversationId');

      // Add message to local list (only if not already present)
      _messages[conversationId] ??= [];
      final existingMessageIndex = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
      if (existingMessageIndex == -1) {
        _messages[conversationId]!.add(message);
        // Keep messages sorted by creation time (newest first for reverse ListView)
        _messages[conversationId]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('[ChatProvider] ✅ Added new message ${message.id} to conversation $conversationId');
      } else {
        // Update existing message (in case of edits or status updates)
        _messages[conversationId]![existingMessageIndex] = message;
        // Re-sort to maintain order
        _messages[conversationId]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('[ChatProvider] Updated existing message ${message.id} in conversation $conversationId');
      }

      // Update conversation's last message and move to top
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        final conversation = _conversations[conversationIndex];
        // Create updated conversation with new last message
        final updatedConversation = Conversation(
          id: conversation.id,
          type: conversation.type,
          name: conversation.name,
          projectId: conversation.projectId,
          companyId: conversation.companyId,
          createdBy: conversation.createdBy,
          createdAt: conversation.createdAt,
          updatedAt: DateTime.now(),
          lastMessage: message,
          participantIds: conversation.participantIds,
          participants: conversation.participants,
          unreadCount: conversation.id == _currentConversationId 
              ? conversation.unreadCount 
              : conversation.unreadCount + 1,
        );
        
        // Remove old conversation and add at the beginning (most recent)
        _conversations.removeAt(conversationIndex);
        _conversations.insert(0, updatedConversation);
        
        print('[ChatProvider] ✅ Updated conversation $conversationId with new message');
      } else {
        // If conversation not in list, we need to reload conversations
        // But we can't do that here without userId, so we'll update messages only
        print('[ChatProvider] ⚠️ Conversation $conversationId not in list - message added but conversation not updated');
      }

      notifyListeners();
    } catch (e) {
      print('[ChatProvider] ❌ Error handling new message: $e');
      print('[ChatProvider] Error data: $data');
    }
  }

  /// Play notification sound
  void _playNotificationSound() {
    // On web, sound can be blocked until the first user gesture.
    // We "prime" audio from app root; after that this should work.
    NotificationSoundPlayer.playNotificationSound();
  }

  /// Edit a message (Update)
  Future<bool> editMessage({
    required String messageId,
    required String conversationId,
    required String newText,
    required String senderId,
  }) async {
    try {
      print('[ChatProvider] Editing message: $messageId with new text: $newText');
      // Call API to edit message
      final messageJson = await ChatApiService.editMessage(
        messageId: messageId,
        messageText: newText,
        senderId: senderId,
      );

      print('[ChatProvider] Edit API response: $messageJson');

      if (messageJson != null) {
        final updatedMessage = Message.fromJson(messageJson);
        final messages = _messages[conversationId] ?? [];
        final messageIndex = messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          // Update conversation's last message if this is the last message
          final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
          if (conversationIndex != -1) {
            final conversation = _conversations[conversationIndex];
            if (conversation.lastMessage?.id == messageId) {
              _conversations[conversationIndex] = Conversation(
                id: conversation.id,
                type: conversation.type,
                name: conversation.name,
                projectId: conversation.projectId,
                companyId: conversation.companyId,
                createdBy: conversation.createdBy,
                createdAt: conversation.createdAt,
                updatedAt: DateTime.now(),
                lastMessage: updatedMessage,
                participantIds: conversation.participantIds,
                participants: conversation.participants,
                unreadCount: conversation.unreadCount,
              );
            }
          }
          notifyListeners();
          print('[ChatProvider] ✅ Message updated successfully');
          return true;
        } else {
          print('[ChatProvider] ❌ Message not found in local list');
        }
      } else {
        print('[ChatProvider] ❌ Edit API returned null');
      }
      return false;
    } catch (e) {
      print('Error editing message: $e');
      return false;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage({
    required String messageId,
    required String conversationId,
    required String senderId,
  }) async {
    try {
      // Call API to delete message
      final success = await ChatApiService.deleteMessage(
        messageId: messageId,
        senderId: senderId,
      );

      if (success) {
        // Update local message
        final messages = _messages[conversationId] ?? [];
        final messageIndex = messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final oldMessage = messages[messageIndex];
          messages[messageIndex] = Message(
            id: oldMessage.id,
            conversationId: oldMessage.conversationId,
            senderId: oldMessage.senderId,
            senderName: oldMessage.senderName,
            senderPhotoUrl: oldMessage.senderPhotoUrl,
            messageText: '[Message deleted]',
            messageType: oldMessage.messageType,
            fileUrl: oldMessage.fileUrl,
            fileName: oldMessage.fileName,
            fileSize: oldMessage.fileSize,
            isEdited: oldMessage.isEdited,
            isDeleted: true,
            editedAt: oldMessage.editedAt,
            createdAt: oldMessage.createdAt,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId, String userId) async {
    try {
      // Call API to delete conversation
      final success = await ChatApiService.deleteConversation(
        conversationId: conversationId,
        userId: userId,
      );

      if (success) {
        // Remove from local lists
        _conversations.removeWhere((c) => c.id == conversationId);
        _messages.remove(conversationId);
        _conversationDetails.remove(conversationId);
        _typingUsers.remove(conversationId);
        if (_currentConversationId == conversationId) {
          _currentConversationId = null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }

  /// Upload file and return file URL
  Future<String?> uploadFile({
    required String fileData, // base64 encoded
    required String fileName,
    required String fileType,
    int? fileSize,
  }) async {
    try {
      final result = await ChatApiService.uploadFile(
        fileData: fileData,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
      );
      return result?['fileUrl'] as String?;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Disconnect from socket
  void disconnect() {
    _socketService.disconnect();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

