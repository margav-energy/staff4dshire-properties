import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class ChatSocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  /// Connect to Socket.io server
  void connect(String userId) {
    if (_socket != null && _isConnected) {
      print('[ChatSocketService] Already connected, skipping');
      return; // Already connected
    }

    // Get base URL without /api suffix for Socket.io
    String baseUrl = ApiConfig.baseUrl;
    print('[ChatSocketService] Base URL from config: $baseUrl');
    
    String socketUrl = baseUrl.replaceAll('/api', '').replaceAll('/api/', '');
    // Ensure we have a clean URL (remove trailing slashes)
    if (socketUrl.endsWith('/')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 1);
    }
    
    print('[ChatSocketService] Connecting to Socket.io server: $socketUrl');
    print('[ChatSocketService] User ID: $userId');
    
    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Allow fallback to polling
            .enableAutoConnect()
            .setTimeout(10000)
            .build(),
      );

      _socket!.onConnect((_) {
        print('[ChatSocketService] ✅ Successfully connected to server');
        _isConnected = true;
        // Join user's personal room
        _socket!.emit('join-user-room', userId);
        print('[ChatSocketService] Sent join-user-room for userId: $userId');
      });

      _socket!.onDisconnect((reason) {
        print('[ChatSocketService] ❌ Disconnected from server. Reason: $reason');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('[ChatSocketService] ❌ Connection error: $error');
        print('[ChatSocketService] Socket URL was: $socketUrl');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('[ChatSocketService] ❌ Socket error: $error');
      });

      _socket!.on('connect_error', (error) {
        print('[ChatSocketService] ❌ Connect error event: $error');
      });
    } catch (e) {
      print('[ChatSocketService] ❌ Exception while connecting: $e');
      _isConnected = false;
    }
  }

  /// Join a conversation room
  void joinConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join-conversation', conversationId);
    }
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave-conversation', conversationId);
    }
  }

  /// Send typing indicator
  void sendTyping({
    required String conversationId,
    required String userId,
    required String userName,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing', {
        'conversationId': conversationId,
        'userId': userId,
        'userName': userName,
      });
    }
  }

  /// Send stop typing indicator
  void sendStopTyping({
    required String conversationId,
    required String userId,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('stop-typing', {
        'conversationId': conversationId,
        'userId': userId,
      });
    }
  }

  /// Listen for new messages
  void onNewMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('new-message', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Listen for user typing
  void onUserTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user-typing', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Listen for user stopped typing
  void onUserStoppedTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user-stopped-typing', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Listen for messages read updates
  void onMessagesRead(Function(Map<String, dynamic>) callback) {
    _socket?.on('messages-read', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Remove all listeners
  void removeAllListeners() {
    _socket?.clearListeners();
  }

  /// Disconnect from server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }
}

