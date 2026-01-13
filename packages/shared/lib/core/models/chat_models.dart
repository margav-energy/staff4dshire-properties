class Conversation {
  final String id;
  final String type; // 'direct', 'group', 'project'
  final String? name;
  final String? projectId;
  final String? companyId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final List<String> participantIds;
  final List<ConversationParticipant>? participants;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.projectId,
    this.companyId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    required this.participantIds,
    this.participants,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Handle date parsing with null safety
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    try {
      return Conversation(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'direct',
        name: json['name']?.toString(),
        projectId: json['projectId']?.toString() ?? json['project_id']?.toString(),
        companyId: json['companyId']?.toString() ?? json['company_id']?.toString(),
        createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
        createdAt: parseDateTime(json['createdAt'] ?? json['created_at']),
        updatedAt: parseDateTime(json['updatedAt'] ?? json['updated_at']),
        lastMessage: json['lastMessage'] != null
            ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        participantIds: (json['participantIds'] as List<dynamic>?)
                ?.map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            (json['participant_ids'] as List<dynamic>?)
                ?.map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [],
        participants: json['participants'] != null
            ? (json['participants'] as List<dynamic>)
                .map((e) => ConversationParticipant.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        unreadCount: (json['unreadCount'] as int?) ?? (json['unread_count'] as int?) ?? 0,
      );
    } catch (e, stackTrace) {
      print('[Conversation.fromJson] Error parsing conversation: $e');
      print('[Conversation.fromJson] Stack trace: $stackTrace');
      print('[Conversation.fromJson] JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'projectId': projectId,
      'companyId': companyId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'participantIds': participantIds,
      'participants': participants?.map((p) => p.toJson()).toList(),
      'unreadCount': unreadCount,
    };
  }
}

class ConversationParticipant {
  final String userId;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? email;

  ConversationParticipant({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.email,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    try {
      return ConversationParticipant(
        userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? json['first_name']?.toString() ?? 'Unknown',
        lastName: json['lastName']?.toString() ?? json['last_name']?.toString() ?? 'User',
        photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
        email: json['email']?.toString(),
      );
    } catch (e, stackTrace) {
      print('[ConversationParticipant.fromJson] Error parsing participant: $e');
      print('[ConversationParticipant.fromJson] Stack trace: $stackTrace');
      print('[ConversationParticipant.fromJson] JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'email': email,
    };
  }

  String get fullName => '$firstName $lastName';
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
  final int? fileSize;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? editedAt;
  final DateTime createdAt;
  final String readStatus; // 'sent', 'delivered', 'read'

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
    this.fileSize,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
    required this.createdAt,
    this.readStatus = 'sent',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id']?.toString() ?? '',
        conversationId: json['conversationId']?.toString() ?? json['conversation_id']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? json['sender_name']?.toString() ?? 'Unknown',
        senderPhotoUrl: json['senderPhotoUrl']?.toString() ?? json['sender_photo_url']?.toString(),
      messageText: json['messageText']?.toString() ?? json['message_text']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? json['message_type']?.toString() ?? 'text',
      fileUrl: json['fileUrl']?.toString() ?? json['file_url']?.toString(),
      fileName: json['fileName']?.toString() ?? json['file_name']?.toString(),
      fileSize: json['fileSize'] != null 
          ? (json['fileSize'] is int ? json['fileSize'] as int : int.tryParse(json['fileSize'].toString()))
          : (json['file_size'] != null 
              ? (json['file_size'] is int ? json['file_size'] as int : int.tryParse(json['file_size'].toString()))
              : null),
        isEdited: json['isEdited'] as bool? ?? json['is_edited'] as bool? ?? false,
        isDeleted: json['isDeleted'] as bool? ?? json['is_deleted'] as bool? ?? false,
        editedAt: json['editedAt'] != null || json['edited_at'] != null
            ? DateTime.tryParse((json['editedAt'] ?? json['edited_at']).toString())
            : null,
        createdAt: json['createdAt'] != null || json['created_at'] != null
            ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString()) ?? DateTime.now()
            : DateTime.now(),
        readStatus: json['readStatus']?.toString() ?? json['read_status']?.toString() ?? 'sent',
      );
    } catch (e, stackTrace) {
      print('[Message.fromJson] Error parsing message: $e');
      print('[Message.fromJson] Stack trace: $stackTrace');
      print('[Message.fromJson] JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'messageText': messageText,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'editedAt': editedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'readStatus': readStatus,
    };
  }
}

