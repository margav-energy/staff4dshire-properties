import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'chat_screen.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    // Use a small delay to ensure context is fully ready
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      // Always reload conversations on screen init to ensure fresh data after refresh
      await chatProvider.initialize(userId);
      // Explicitly load conversations again to ensure they're loaded
      await chatProvider.loadConversations(userId);
      // Ensure users are loaded for the new chat dialog
      userProvider.loadUsers(userId: userId);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  String _getDateHeaderLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      // Check if it's within the current year
      if (date.year == now.year) {
        return DateFormat('MMMM d').format(date);
      } else {
        return DateFormat('MMMM d, yyyy').format(date);
      }
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  List<dynamic> _buildGroupedConversations(List<Conversation> conversations) {
    final List<dynamic> items = [];
    String? lastDateHeader;
    
    for (final conversation in conversations) {
      final conversationDate = conversation.updatedAt ?? conversation.createdAt;
      final dateHeader = _getDateHeaderLabel(conversationDate);
      
      // Add date header if it's different from the last one
      if (dateHeader != lastDateHeader) {
        items.add({'type': 'header', 'label': dateHeader});
        lastDateHeader = dateHeader;
      }
      
      // Add the conversation
      items.add({'type': 'conversation', 'data': conversation});
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id;
              if (userId != null) {
                chatProvider.loadConversations(userId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNewChatDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.message),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final conversations = chatProvider.conversations;
          
          print('[ChatListScreen] Building with ${conversations.length} conversations');
          print('[ChatListScreen] isLoading: ${chatProvider.isLoading}');
          
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (conversations.isEmpty) {
            print('[ChatListScreen] Showing empty state - no conversations found');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with your team',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedItems = _buildGroupedConversations(conversations);

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id;
              if (userId != null) {
                await chatProvider.loadConversations(userId);
              }
            },
            child: ListView.builder(
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];
                
                // Show date header
                if (item['type'] == 'header') {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      item['label'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }
                
                // Show conversation
                final conversation = item['data'] as Conversation;
                final lastMessage = conversation.lastMessage;

                // Get participant photo and name for direct messages
                String? participantPhotoUrl;
                String participantInitial = 'U';
                bool isBase64Photo = false;
                if (conversation.type == 'direct') {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final currentUserId = authProvider.currentUser?.id;
                  if (currentUserId != null && conversation.participants != null) {
                    final otherParticipants = conversation.participants!
                        .where((p) => p.userId != currentUserId)
                        .toList();
                    if (otherParticipants.isNotEmpty) {
                      final otherParticipant = otherParticipants.first;
                      participantPhotoUrl = otherParticipant.photoUrl;
                      // Check if it's a base64 data URL
                      isBase64Photo = participantPhotoUrl != null && participantPhotoUrl!.startsWith('data:image');
                      participantInitial = otherParticipant.fullName.isNotEmpty
                          ? otherParticipant.fullName.substring(0, 1).toUpperCase()
                          : 'U';
                    }
                  }
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: participantPhotoUrl != null && 
                        participantPhotoUrl!.isNotEmpty && 
                        !participantPhotoUrl!.startsWith('pref:')
                        ? (isBase64Photo 
                            ? MemoryImage(
                                base64Decode(participantPhotoUrl!.split(',')[1]) as Uint8List
                              ) as ImageProvider
                            : NetworkImage(participantPhotoUrl!) as ImageProvider)
                        : null,
                    child: conversation.type == 'direct'
                        ? (participantPhotoUrl != null && 
                           participantPhotoUrl!.isNotEmpty && 
                           !participantPhotoUrl!.startsWith('pref:')
                            ? null
                            : Text(
                                participantInitial,
                                style: const TextStyle(color: Colors.white),
                              ))
                        : const Icon(Icons.group, color: Colors.white),
                  ),
                  title: Builder(
                    builder: (context) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final currentUserId = authProvider.currentUser?.id;
                      
                      String displayName = conversation.name ?? 
                          (conversation.type == 'direct' 
                              ? 'Direct Message' 
                              : 'Group Chat');
                      
                      // For direct messages without a name, show the other participant's name
                      if (conversation.type == 'direct' && 
                          currentUserId != null &&
                          conversation.participants != null &&
                          conversation.participants!.isNotEmpty) {
                        final otherParticipants = conversation.participants!
                            .where((p) => p.userId != currentUserId)
                            .toList();
                        if (otherParticipants.isNotEmpty) {
                          displayName = otherParticipants.first.fullName;
                        }
                      }
                      
                      return Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: conversation.unreadCount > 0 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                  subtitle: lastMessage != null
                      ? Text(
                          lastMessage.messageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const Text('No messages yet'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (lastMessage != null)
                        Text(
                          _formatTimestamp(lastMessage.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(conversationId: conversation.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final currentPath = GoRouterState.of(context).uri.path;
          return BottomNavBar(currentPath: currentPath);
        },
      ),
    );
  }

  Future<void> _showNewChatDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to start a chat')),
      );
      return;
    }

    // Get users from the same company (excluding current user)
    final companyUsers = userProvider.users
        .where((user) => user.id != currentUserId && user.isActive)
        .toList();

    if (companyUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other users available to chat with')),
      );
      return;
    }

    final selectedUser = await showDialog<UserModel>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start New Chat'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: companyUsers.length,
            itemBuilder: (context, index) {
              final user = companyUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.fullName),
                subtitle: Text(user.email),
                onTap: () => Navigator.pop(dialogContext, user),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedUser != null) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Create conversation
        final conversation = await chatProvider.createConversation(
          type: 'direct',
          userIds: [currentUserId, selectedUser.id],
          createdBy: currentUserId,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        if (conversation != null) {
          // Reload conversations
          await chatProvider.loadConversations(currentUserId);
          
          if (!mounted) return;
          // Navigate to the chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversationId: conversation.id),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create conversation')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

