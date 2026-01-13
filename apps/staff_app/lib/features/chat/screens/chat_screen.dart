import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html show AnchorElement;

// Conditional import for file operations
import 'dart:io' if (dart.library.html) 'package:staff4dshire_shared/core/utils/web_file_stub.dart' as io;

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _previewFileBytes;
  String? _previewFileName;
  String? _previewFileType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        // Ensure conversations are loaded (in case screen was opened directly)
        await chatProvider.loadConversations(userId);
        // Set current conversation and load messages
        chatProvider.setCurrentConversation(widget.conversationId);
        // Load conversation details to get participant info (name, photo)
        await chatProvider.loadConversationDetails(widget.conversationId);
        // Explicitly load messages to ensure they're fetched (with userId for read status)
        await chatProvider.loadMessages(widget.conversationId, userId: userId);
        // Mark as read after messages are loaded
        await chatProvider.markAsRead(widget.conversationId, userId);
        
        if (mounted) {
          // Trigger UI update
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    // Leaving the chat screen: clear "current conversation" so badges/sounds work elsewhere
    try {
      Provider.of<ChatProvider>(context, listen: false).clearCurrentConversation();
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Since list is reversed, scroll to position 0 (which is the bottom/newest)
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final messageText = text;
    _messageController.clear();
    setState(() => _isTyping = false);

    // Send message
    final message = await chatProvider.sendMessage(
      conversationId: widget.conversationId,
      senderId: userId,
      messageText: messageText,
    );

    // Scroll to bottom after sending
    if (message != null) {
      _scrollToBottom();
    }
  }

  void _onTypingChanged(String text) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final userName = authProvider.currentUser?.name ?? 'User';

    if (userId == null) return;

    if (text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      chatProvider.sendTyping(
        conversationId: widget.conversationId,
        userId: userId,
        userName: userName,
      );
    } else if (text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      chatProvider.sendStopTyping(
        conversationId: widget.conversationId,
        userId: userId,
      );
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }

  String _getDateHeaderLabel(DateTime date) {
    // Convert to local time to ensure proper comparison
    final localDate = date.toLocal();
    final now = DateTime.now();
    // Create date-only objects for comparison (no time component)
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      // Check if it's within the current year
      if (dateOnly.year == now.year) {
        return DateFormat('MMMM d').format(localDate);
      } else {
        return DateFormat('MMMM d, yyyy').format(localDate);
      }
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  List<dynamic> _buildGroupedMessages(List<Message> messages) {
    final List<dynamic> items = [];
    DateTime? lastDate;
    
    for (final message in messages) {
      // Convert to local time to ensure proper date comparison
      final messageDate = message.createdAt.toLocal();
      // Create date-only object (no time component) for grouping
      final dateOnly = DateTime(messageDate.year, messageDate.month, messageDate.day);
      
      // Add date header if it's different from the last one
      if (lastDate == null || !_isSameDate(dateOnly, lastDate)) {
        items.add({'type': 'header', 'date': dateOnly});
        lastDate = dateOnly;
      }
      
      // Add the message
      items.add({'type': 'message', 'data': message});
    }
    
    return items;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    final conversation = chatProvider.getConversation(widget.conversationId);
    final messages = chatProvider.getMessages(widget.conversationId);
    final typingUsers = chatProvider.getTypingUsers(widget.conversationId);

    // Get conversation name and avatar - for direct messages, show the other participant's info
    String conversationName = conversation?.name ?? '';
    String? conversationPhotoUrl;
    String conversationInitial = 'U';
    bool isBase64Photo = false;
    
    if (conversation != null && conversation.type == 'direct' && currentUserId != null) {
      // Find the other participant's info
      if (conversation.participantIds.isNotEmpty) {
        final otherParticipants = conversation.participantIds
            .where((id) => id != currentUserId)
            .toList();
        
        if (otherParticipants.isNotEmpty) {
          // First try to get from participants list
          if (conversation.participants != null && conversation.participants!.isNotEmpty) {
            final otherParticipant = conversation.participants!
                .firstWhere(
                  (p) => otherParticipants.contains(p.userId),
                  orElse: () => conversation.participants!.first,
                );
            conversationName = otherParticipant.fullName;
            conversationPhotoUrl = PhotoUrlHelper.getPhotoUrl(
              otherParticipant.photoUrl,
              userId: otherParticipant.userId,
            );
            // Check if it's a base64 data URL
            isBase64Photo = conversationPhotoUrl != null && conversationPhotoUrl!.startsWith('data:image');
            conversationInitial = conversationName.isNotEmpty
                ? conversationName.substring(0, 1).toUpperCase()
                : 'U';
          } else {
            // If participants not loaded, try to load conversation details
            // This will trigger a reload if needed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatProvider.loadConversationDetails(widget.conversationId);
            });
          }
        }
      }
    }

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: conversationPhotoUrl != null && 
                  conversationPhotoUrl!.isNotEmpty
                  ? (isBase64Photo
                      ? MemoryImage(
                          base64Decode(conversationPhotoUrl!.split(',')[1]) as Uint8List
                        ) as ImageProvider
                      : NetworkImage(conversationPhotoUrl!) as ImageProvider)
                  : null,
              child: conversationPhotoUrl == null || 
                  conversationPhotoUrl!.isEmpty
                  ? Text(
                      conversationInitial,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversationName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (typingUsers.isNotEmpty)
                    Text(
                      '${typingUsers.length} typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      // Build grouped messages with date headers
                      final groupedItems = _buildGroupedMessages(messages);
                      
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // WhatsApp-like: newest messages at bottom
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedItems.length,
                        itemBuilder: (context, index) {
                          final item = groupedItems[index];
                          
                          // Show date header
                          if (item['type'] == 'header') {
                            final date = item['date'] as DateTime;
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getDateHeaderLabel(date),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          // Show message
                          final message = item['data'] as Message;
                          final isCurrentUser = message.senderId == currentUserId;
                          
                          // Find the message index in the original list to determine avatar display
                          final messageIndex = messages.indexWhere((m) => m.id == message.id);
                          // With reverse: true, messages are sorted newest first (DESC)
                          // So index 0 = newest message (displayed at bottom)
                          // For avatar display: show if this is the first message (index 0) or
                          // if the previous message in the array (index - 1) was from a different sender
                          // Previous in array = next in display order (since reversed)
                          final showAvatar = messageIndex == 0 ||
                              (messageIndex > 0 && messages[messageIndex - 1].senderId != message.senderId);

                          return GestureDetector(
                            onLongPress: isCurrentUser && !message.isDeleted
                                ? () => _showMessageOptions(context, message, chatProvider, currentUserId!)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: isCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Removed avatars - chat name/icon now in AppBar
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                                          bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Removed sender name - now shown in AppBar header
                                          if (message.messageType == 'image' && message.fileUrl != null)
                                            GestureDetector(
                                              onTap: () => _showImageFullScreen(context, message.fileUrl!),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  message.fileUrl!,
                                                  width: 200,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 200,
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.broken_image),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          if (message.messageType == 'file' && message.fileUrl != null && message.fileName != null)
                                            InkWell(
                                              onTap: () {
                                                // Open file in new tab/window
                                                if (kIsWeb) {
                                                  final anchor = html.AnchorElement(href: message.fileUrl)
                                                    ..target = '_blank'
                                                    ..download = message.fileName;
                                                  anchor.click();
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surface,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: theme.colorScheme.outline),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.insert_drive_file,
                                                      color: theme.colorScheme.primary,
                                                      size: 32,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Flexible(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            message.fileName!,
                                                            style: TextStyle(
                                                              color: isCurrentUser
                                                                  ? Colors.white
                                                                  : theme.colorScheme.onSurface,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (message.fileSize != null)
                                                            Text(
                                                              _formatFileSize(message.fileSize!),
                                                              style: TextStyle(
                                                                color: isCurrentUser
                                                                    ? Colors.white70
                                                                    : theme.colorScheme.onSurfaceVariant,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (message.messageText.isNotEmpty && message.messageText != '📷 Image' && message.messageText != '📎 File: ${message.fileName ?? ""}')
                                            Text(
                                              message.isDeleted ? '[Message deleted]' : message.messageText,
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : theme.colorScheme.onSurface,
                                                fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _formatMessageTime(message.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isCurrentUser
                                                      ? Colors.white70
                                                      : theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                              if (message.isEdited) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  'edited',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                    color: isCurrentUser
                                                        ? Colors.white70
                                                        : theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                              // Read receipts (ticks) - only show for current user's messages
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  message.readStatus == 'read' 
                                                      ? Icons.done_all 
                                                      : (message.readStatus == 'delivered' 
                                                          ? Icons.done_all 
                                                          : Icons.done),
                                                  size: 14,
                                                  color: message.readStatus == 'read' 
                                                      ? Colors.blue 
                                                      : (isCurrentUser ? Colors.white70 : null),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => _showFileOptions(context),
                  color: theme.colorScheme.primary,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _onTypingChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message, ChatProvider chatProvider, String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(context, message, chatProvider, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardDialog(context, message, chatProvider, userId);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMessage(context, message, chatProvider, userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(BuildContext context, Message message, ChatProvider chatProvider, String userId) {
    final controller = TextEditingController(text: message.messageText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != message.messageText) {
                try {
                  final success = await chatProvider.editMessage(
                    messageId: message.id,
                    conversationId: widget.conversationId,
                    newText: newText,
                    senderId: userId,
                  );
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message updated')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update message')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context, Message message, ChatProvider chatProvider, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await chatProvider.deleteMessage(
                messageId: message.id,
                conversationId: widget.conversationId,
                senderId: userId,
              );
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = result.files.single;
        if (kIsWeb) {
          // For web, use bytes directly
          if (file.bytes != null) {
            setState(() {
              _previewFileBytes = file.bytes!;
              _previewFileName = file.name;
              _previewFileType = 'file';
            });
            _showFilePreviewDialog(context, file.bytes!, file.name, 'file');
          }
        } else {
          // For mobile, use path
          if (file.path != null) {
            final bytes = await io.File(file.path!).readAsBytes();
            setState(() {
              _previewFileBytes = bytes;
              _previewFileName = file.name;
              _previewFileType = 'file';
            });
            _showFilePreviewDialog(context, bytes, file.name, 'file');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _previewFileBytes = bytes;
            _previewFileName = image.name;
            _previewFileType = 'image';
          });
          _showFilePreviewDialog(context, bytes, image.name, 'image');
        } else {
          // For mobile, use path
          final bytes = await io.File(image.path).readAsBytes();
          setState(() {
            _previewFileBytes = bytes;
            _previewFileName = image.name;
            _previewFileType = 'image';
          });
          _showFilePreviewDialog(context, bytes, image.name, 'image');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showFilePreviewDialog(BuildContext context, Uint8List bytes, String fileName, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview ${type == 'image' ? 'Image' : 'File'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'image')
                Image.memory(
                  bytes,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              if (type == 'file')
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.insert_drive_file, size: 64, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(fileName, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(_formatFileSize(bytes.length), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _previewFileBytes = null;
                _previewFileName = null;
                _previewFileType = null;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendFileBytes(bytes, fileName, type);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(BuildContext context, Message message, ChatProvider chatProvider, String userId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    // Load users if not already loaded
    if (userProvider.users.isEmpty) {
      userProvider.loadUsers(userId: userId);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Message'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              // Filter to get active users from same company (excluding current user)
              final availableUsers = userProvider.users
                  .where((u) => 
                      u.id != userId && 
                      u.isActive && 
                      u.companyId == currentUser?.companyId)
                  .toList();

              if (availableUsers.isEmpty) {
                return const Text('No users available to forward to');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final user = availableUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoUrl != null 
                          ? NetworkImage(user.photoUrl!) 
                          : null,
                      child: user.photoUrl == null
                          ? Text(user.fullName.isNotEmpty 
                              ? user.fullName.substring(0, 1).toUpperCase() 
                              : user.email.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(user.fullName),
                    subtitle: Text(user.email),
                    onTap: () async {
                      Navigator.pop(context);
                      await _forwardMessage(message, user.id, chatProvider, userId);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _forwardMessage(Message message, String targetUserId, ChatProvider chatProvider, String senderId) async {
    try {
      // Find or create a direct conversation with the target user
      final conversations = chatProvider.conversations;
      Conversation? targetConversation;
      
      // Look for existing direct conversation
      for (var conv in conversations) {
        if (conv.type == 'direct' && 
            conv.participantIds.contains(targetUserId) && 
            conv.participantIds.contains(senderId) &&
            conv.participantIds.length == 2) {
          targetConversation = conv;
          break;
        }
      }

      String conversationId;
      if (targetConversation != null) {
        conversationId = targetConversation.id;
      } else {
        // Create new direct conversation
        final newConv = await chatProvider.createConversation(
          type: 'direct',
          userIds: [targetUserId, senderId],
          createdBy: senderId,
        );
        if (newConv == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create conversation')),
            );
          }
          return;
        }
        conversationId = newConv.id;
        // Reload conversations
        await chatProvider.loadConversations(senderId);
      }

      // Forward the message
      await chatProvider.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        messageText: message.messageText,
        messageType: message.messageType,
        fileUrl: message.fileUrl,
        fileName: message.fileName,
        fileSize: message.fileSize,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message forwarded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error forwarding message: $e')),
        );
      }
    }
  }

  Future<void> _sendFile(String filePath, String fileName, String type) async {
    // For mobile platforms - read from file path
    try {
      if (!kIsWeb) {
        final file = io.File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await _sendFileBytes(bytes, fileName, type);
        } else {
          throw Exception('File not found: $filePath');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image, color: Colors.white, size: 64),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFileBytes(Uint8List bytes, String fileName, String type) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Convert to base64
      final base64String = base64Encode(bytes);
      final mimeType = type == 'image' 
          ? (fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg')
          : 'application/octet-stream';
      final dataUrl = 'data:$mimeType;base64,$base64String';

      print('[ChatScreen] Uploading file: $fileName, size: ${bytes.length}, type: $type');

      // Upload file
      final fileUrl = await chatProvider.uploadFile(
        fileData: dataUrl,
        fileName: fileName,
        fileType: type,
        fileSize: bytes.length,
      );

      print('[ChatScreen] Upload result: fileUrl = $fileUrl');

      if (fileUrl != null && fileUrl.isNotEmpty) {
        // Send message with file
        print('[ChatScreen] Sending message with file URL: $fileUrl');
        final sentMessage = await chatProvider.sendMessage(
          conversationId: widget.conversationId,
          senderId: userId,
          messageText: type == 'image' ? '📷 Image' : '📎 File: $fileName',
          messageType: type,
          fileUrl: fileUrl,
          fileName: fileName,
          fileSize: bytes.length,
        );
        
        if (sentMessage != null) {
          if (mounted) {
            _scrollToBottom();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded but failed to send message')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload file')),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[ChatScreen] Error uploading file: $e');
      print('[ChatScreen] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) Navigator.pop(context); // Close loading
    }
  }
}
