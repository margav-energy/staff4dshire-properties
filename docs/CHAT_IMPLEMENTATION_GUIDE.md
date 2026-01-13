# Chat Feature Implementation Guide

## Overview
This guide outlines what you'll need to implement a real-time chat feature in the Staff4dshire Properties application.

## Architecture Decision: WebSocket vs HTTP Polling

**Recommended: WebSocket (Socket.io)**
- Real-time, bidirectional communication
- Lower latency (no polling delays)
- More efficient (no constant HTTP requests)
- Better user experience

**Alternative: HTTP Polling**
- Simpler to implement
- Works with existing HTTP infrastructure
- Higher latency and server load
- Not ideal for real-time chat

---

## 1. Backend Requirements

### A. Database Schema

You'll need two new tables:

#### `conversations` Table
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('direct', 'group', 'project')),
    name VARCHAR(255), -- For group/project chats
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE, -- If project chat
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_read_at TIMESTAMP, -- For unread message tracking
    UNIQUE(conversation_id, user_id)
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    file_url VARCHAR(500), -- For images/files
    file_name VARCHAR(255),
    file_size BIGINT,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
```

### B. Dependencies to Install

```bash
cd backend
npm install socket.io
```

### C. Backend Structure

#### 1. Update `server.js` to include Socket.io

```javascript
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Configure appropriately for production
    methods: ["GET", "POST"]
  }
});

// ... existing middleware and routes ...

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  // Join user to their personal room
  socket.on('join-user-room', (userId) => {
    socket.join(`user-${userId}`);
    console.log(`User ${userId} joined their room`);
  });
  
  // Join conversation
  socket.on('join-conversation', (conversationId) => {
    socket.join(`conversation-${conversationId}`);
    console.log(`User joined conversation ${conversationId}`);
  });
  
  // Leave conversation
  socket.on('leave-conversation', (conversationId) => {
    socket.leave(`conversation-${conversationId}`);
  });
  
  // Handle new message
  socket.on('send-message', async (data) => {
    // Save message to database (via API route)
    // Then broadcast to conversation room
    io.to(`conversation-${data.conversationId}`).emit('new-message', data);
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Update listen to use server instead of app
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
```

#### 2. Create `backend/routes/chat.js`

```javascript
const express = require('express');
const router = express.Router();
const pool = require('../db');

// Get all conversations for a user
router.get('/conversations', async (req, res) => {
  try {
    const { userId } = req.query;
    // Query to get conversations with last message
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get messages for a conversation
router.get('/conversations/:conversationId/messages', async (req, res) => {
  try {
    const { conversationId } = req.params;
    // Query messages with sender info
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new conversation
router.post('/conversations', async (req, res) => {
  try {
    const { type, userIds, projectId, name } = req.body;
    // Create conversation and participants
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message
router.post('/messages', async (req, res) => {
  try {
    const { conversationId, senderId, messageText, messageType, fileUrl } = req.body;
    // Insert message
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mark messages as read
router.put('/conversations/:conversationId/read', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { userId } = req.body;
    // Update last_read_at
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

#### 3. Register route in `server.js`

```javascript
app.use('/api/chat', require('./routes/chat'));
```

---

## 2. Frontend Requirements (Flutter)

### A. Dependencies to Install

Add to `packages/shared/pubspec.yaml` (or relevant app's pubspec.yaml):

```yaml
dependencies:
  socket_io_client: ^2.0.3+1  # For WebSocket connection
  image_picker: ^1.0.5        # Optional: For sending images
  file_picker: ^6.0.0         # Optional: For sending files
```

Run:
```bash
flutter pub get
```

### B. Frontend Structure

#### 1. Create Models

**`packages/shared/lib/core/models/chat_models.dart`**
```dart
class Conversation {
  final String id;
  final String type; // 'direct', 'group', 'project'
  final String? name;
  final String? projectId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final List<String> participantIds;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.projectId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    required this.participantIds,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Parse JSON
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String messageText;
  final String messageType; // 'text', 'image', 'file', 'system'
  final String? fileUrl;
  final String? fileName;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.messageText,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse JSON
  }
}
```

#### 2. Create API Service

**`packages/shared/lib/core/services/chat_api_service.dart`**
```dart
class ChatApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  static Future<List<Conversation>> getConversations(String userId) async {
    // GET /api/chat/conversations?userId=xxx
  }
  
  static Future<List<Message>> getMessages(String conversationId) async {
    // GET /api/chat/conversations/:conversationId/messages
  }
  
  static Future<Conversation> createConversation({
    required String type,
    required List<String> userIds,
    String? projectId,
    String? name,
  }) async {
    // POST /api/chat/conversations
  }
  
  static Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
    String? messageType,
    String? fileUrl,
  }) async {
    // POST /api/chat/messages
  }
  
  static Future<void> markAsRead(String conversationId, String userId) async {
    // PUT /api/chat/conversations/:conversationId/read
  }
}
```

#### 3. Create Socket Service

**`packages/shared/lib/core/services/chat_socket_service.dart`**
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  IO.Socket? _socket;
  
  void connect(String userId) {
    _socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .build(),
    );
    
    _socket!.onConnect((_) {
      print('Socket connected');
      _socket!.emit('join-user-room', userId);
    });
    
    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }
  
  void joinConversation(String conversationId) {
    _socket?.emit('join-conversation', conversationId);
  }
  
  void leaveConversation(String conversationId) {
    _socket?.emit('leave-conversation', conversationId);
  }
  
  void sendMessage(Map<String, dynamic> messageData) {
    _socket?.emit('send-message', messageData);
  }
  
  void onNewMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('new-message', (data) => callback(data));
  }
  
  void disconnect() {
    _socket?.disconnect();
  }
}
```

#### 4. Create Provider

**`packages/shared/lib/core/providers/chat_provider.dart`**
```dart
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';
import '../services/chat_socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatSocketService _socketService = ChatSocketService();
  
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messages = {}; // conversationId -> messages
  bool _isLoading = false;
  String? _currentConversationId;
  
  List<Conversation> get conversations => _conversations;
  List<Message> getMessages(String conversationId) => _messages[conversationId] ?? [];
  bool get isLoading => _isLoading;
  
  Future<void> initialize(String userId) async {
    _socketService.connect(userId);
    _socketService.onNewMessage((data) {
      // Handle new message
      _handleNewMessage(data);
    });
    await loadConversations(userId);
  }
  
  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _conversations = await ChatApiService.getConversations(userId);
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMessages(String conversationId) async {
    try {
      final messages = await ChatApiService.getMessages(conversationId);
      _messages[conversationId] = messages;
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }
  
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
  }) async {
    try {
      final message = await ChatApiService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        messageText: messageText,
      );
      
      // Add to local list
      _messages[conversationId] ??= [];
      _messages[conversationId]!.add(message);
      notifyListeners();
      
      // Also send via socket for real-time
      _socketService.sendMessage({
        'conversationId': conversationId,
        'senderId': senderId,
        'messageText': messageText,
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }
  
  void _handleNewMessage(Map<String, dynamic> data) {
    // Update local state with new message
    notifyListeners();
  }
  
  void setCurrentConversation(String conversationId) {
    _currentConversationId = conversationId;
    _socketService.joinConversation(conversationId);
    loadMessages(conversationId);
  }
  
  void disconnect() {
    _socketService.disconnect();
  }
}
```

#### 5. Create UI Screens

**`apps/admin_app/lib/features/chat/screens/chat_list_screen.dart`**
- List of conversations
- Unread badges
- Last message preview
- Search functionality

**`apps/admin_app/lib/features/chat/screens/chat_screen.dart`**
- Message list (ListView.builder)
- Message input field
- Send button
- Real-time message updates
- Typing indicators (optional)

---

## 3. Implementation Steps

### Phase 1: Database Setup
1. Run SQL migration to create tables
2. Test database queries manually

### Phase 2: Backend API
1. Install Socket.io dependency
2. Create `backend/routes/chat.js` with REST endpoints
3. Update `server.js` to include Socket.io server
4. Test endpoints with Postman/curl

### Phase 3: Backend Real-time
1. Implement Socket.io event handlers
2. Test real-time message broadcasting
3. Handle connection/disconnection

### Phase 4: Frontend Setup
1. Install Flutter dependencies
2. Create models (`chat_models.dart`)
3. Create API service (`chat_api_service.dart`)
4. Create Socket service (`chat_socket_service.dart`)

### Phase 5: Frontend State Management
1. Create `ChatProvider`
2. Integrate with existing provider system
3. Register in main.dart

### Phase 6: Frontend UI
1. Create chat list screen
2. Create chat screen (conversation view)
3. Add navigation routes
4. Style according to design system

### Phase 7: Testing & Polish
1. Test real-time messaging
2. Test with multiple users
3. Handle edge cases (offline, reconnection)
4. Add error handling
5. Add loading states

---

## 4. Additional Features (Optional)

- **File/Image Sharing**: Upload to storage, send URLs
- **Read Receipts**: Track message reads
- **Typing Indicators**: Show when someone is typing
- **Message Reactions**: Emoji reactions
- **Message Search**: Search within conversations
- **Push Notifications**: Notify when app is closed
- **Message Encryption**: End-to-end encryption
- **Group Chat Management**: Add/remove participants

---

## 5. Security Considerations

- **Authentication**: Verify user identity on socket connection
- **Authorization**: Check if user is participant before sending messages
- **Input Validation**: Sanitize message content
- **Rate Limiting**: Prevent spam
- **File Upload Limits**: Restrict file sizes/types
- **CORS Configuration**: Configure Socket.io CORS properly

---

## 6. Performance Optimization

- **Pagination**: Load messages in chunks (e.g., 50 at a time)
- **Lazy Loading**: Load conversations on demand
- **Caching**: Cache conversations locally
- **Connection Pooling**: Reuse socket connections
- **Message Batching**: Batch multiple messages if needed

---

## Quick Start Checklist

- [ ] Install Socket.io on backend
- [ ] Create database tables
- [ ] Create backend API routes
- [ ] Set up Socket.io server
- [ ] Install socket_io_client on Flutter
- [ ] Create chat models
- [ ] Create API service
- [ ] Create Socket service
- [ ] Create ChatProvider
- [ ] Create UI screens
- [ ] Add navigation routes
- [ ] Test end-to-end

---

## Estimated Development Time

- Database setup: 1-2 hours
- Backend API: 4-6 hours
- Socket.io setup: 2-3 hours
- Frontend models/services: 3-4 hours
- Frontend UI: 6-8 hours
- Testing & polish: 3-4 hours

**Total: ~20-30 hours** for a basic implementation


