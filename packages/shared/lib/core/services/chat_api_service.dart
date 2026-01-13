import '../config/api_config.dart';
import 'api_service.dart';

class ChatApiService {
  static String get _baseEndpoint => '/chat';

  /// Get all conversations for a user
  static Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return [];
    }

    try {
      print('[ChatApiService] Fetching conversations for userId: $userId');
      final response = await ApiService.get('$_baseEndpoint/conversations?userId=$userId');
      print('[ChatApiService] Received response type: ${response.runtimeType}');
      
      if (response is List) {
        print('[ChatApiService] Parsed ${response.length} conversations');
        return response.cast<Map<String, dynamic>>();
      } else if (response is Map<String, dynamic>) {
        print('[ChatApiService] Received Map instead of List: $response');
        // Check if it's wrapped in a data field
        if (response.containsKey('data') && response['data'] is List) {
          return (response['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      
      print('[ChatApiService] Unexpected response format, returning empty list');
      return [];
    } catch (e) {
      print('[ChatApiService] Error fetching conversations: $e');
      print('[ChatApiService] Error stack: ${StackTrace.current}');
      return [];
    }
  }

  /// Get conversation by ID
  static Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    if (!ApiConfig.isApiEnabled) {
      return null;
    }

    try {
      final response = await ApiService.get('$_baseEndpoint/conversations/$conversationId');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return null;
    } catch (e) {
      print('Error fetching conversation: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
    String? userId,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      return [];
    }

    try {
      String url = '$_baseEndpoint/conversations/$conversationId/messages?limit=$limit&offset=$offset';
      if (userId != null) {
        url += '&userId=$userId';
      }
      final response = await ApiService.get(url);
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Create a new conversation
  static Future<Map<String, dynamic>?> createConversation({
    required String type,
    required List<String> userIds,
    String? projectId,
    String? name,
    String? createdBy,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      return null;
    }

    try {
      final response = await ApiService.post(
        '$_baseEndpoint/conversations',
        {
          'type': type,
          'userIds': userIds,
          if (projectId != null) 'projectId': projectId,
          if (name != null) 'name': name,
          if (createdBy != null) 'createdBy': createdBy,
        },
      );
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return null;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  /// Send a message
  static Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
    String? messageType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      return null;
    }

    try {
      final response = await ApiService.post(
        '$_baseEndpoint/messages',
        {
          'conversationId': conversationId,
          'senderId': senderId,
          'messageText': messageText,
          if (messageType != null) 'messageType': messageType,
          if (fileUrl != null) 'fileUrl': fileUrl,
          if (fileName != null) 'fileName': fileName,
          if (fileSize != null) 'fileSize': fileSize,
        },
      );
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Mark conversation as read
  static Future<bool> markAsRead(String conversationId, String userId) async {
    if (!ApiConfig.isApiEnabled) {
      return false;
    }

    try {
      final response = await ApiService.put(
        '$_baseEndpoint/conversations/$conversationId/read',
        {'userId': userId},
      );
      
      return response is Map<String, dynamic>;
    } catch (e) {
      print('Error marking conversation as read: $e');
      return false;
    }
  }

  /// Edit a message
  static Future<Map<String, dynamic>?> editMessage({
    required String messageId,
    required String messageText,
    required String senderId,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      print('[ChatApiService] API not enabled');
      return null;
    }

    try {
      print('[ChatApiService] Editing message $messageId');
      final response = await ApiService.put(
        '$_baseEndpoint/messages/$messageId',
        {
          'messageText': messageText,
          'senderId': senderId,
        },
      );
      
      print('[ChatApiService] Edit response: $response');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      print('[ChatApiService] Edit response is not a Map');
      return null;
    } catch (e, stackTrace) {
      print('[ChatApiService] Error editing message: $e');
      print('[ChatApiService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Delete a message
  static Future<bool> deleteMessage({
    required String messageId,
    required String senderId,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      return false;
    }

    try {
      final response = await ApiService.delete(
        '$_baseEndpoint/messages/$messageId',
        {'senderId': senderId},
      );
      
      return response is Map<String, dynamic> && response['success'] == true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Delete a conversation
  static Future<bool> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      return false;
    }

    try {
      final response = await ApiService.delete(
        '$_baseEndpoint/conversations/$conversationId',
        {'userId': userId},
      );
      
      return response is Map<String, dynamic> && response['success'] == true;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }

  /// Upload a file for chat (accepts base64 encoded file)
  static Future<Map<String, dynamic>?> uploadFile({
    required String fileData, // base64 encoded file
    required String fileName,
    required String fileType,
    int? fileSize,
  }) async {
    if (!ApiConfig.isApiEnabled) {
      print('[ChatApiService] API not enabled for file upload');
      return null;
    }

    try {
      print('[ChatApiService] Uploading file: $fileName, type: $fileType, size: $fileSize');
      print('[ChatApiService] File data length: ${fileData.length}');
      
      final response = await ApiService.post(
        '$_baseEndpoint/upload',
        {
          'fileData': fileData,
          'fileName': fileName,
          'fileType': fileType,
          if (fileSize != null) 'fileSize': fileSize,
        },
      );
      
      print('[ChatApiService] Upload response: ${response.runtimeType}');
      print('[ChatApiService] Upload response data: $response');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      print('[ChatApiService] Upload response is not a Map');
      return null;
    } catch (e, stackTrace) {
      print('[ChatApiService] Error uploading file: $e');
      print('[ChatApiService] Stack trace: $stackTrace');
      return null;
    }
  }
}

