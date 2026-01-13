const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST upload file for chat (accepts base64 encoded files)
// This route MUST come before parameterized routes to ensure proper matching
router.post('/upload', async (req, res) => {
  try {
    console.log('[CHAT] Upload request received');
    const { fileData, fileName, fileType, fileSize } = req.body;

    if (!fileData || !fileName || !fileType) {
      console.log('[CHAT] Missing required fields:', { fileData: !!fileData, fileName: !!fileName, fileType: !!fileType });
      return res.status(400).json({ error: 'fileData, fileName, and fileType are required' });
    }

    console.log('[CHAT] File upload:', { fileName, fileType, fileSize, dataLength: fileData?.length });

    // Validate file size (max 10MB for base64)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize && fileSize > maxSize) {
      return res.status(400).json({ error: 'File size exceeds 10MB limit' });
    }

    // For now, return the base64 data URL as the file URL
    // In production, you would:
    // 1. Decode base64
    // 2. Upload to cloud storage (S3, Cloudinary, etc.)
    // 3. Return the public URL

    // For this implementation, we'll store it as a data URL
    const fileUrl = fileData; // Store base64 data URL directly

    console.log('[CHAT] File upload successful:', { fileName, fileType });
    res.json({
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize || null,
    });
  } catch (error) {
    console.error('[CHAT] Error uploading file:', error);
    res.status(500).json({ error: 'Failed to upload file', message: error.message });
  }
});

// GET all conversations for a user
router.get('/conversations', async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId query parameter is required' });
    }

    // Get user's company_id for filtering
    const userResult = await pool.query(
      'SELECT company_id FROM users WHERE id = $1',
      [userId]
    );

    const userCompanyId = userResult.rows[0]?.company_id;

    // Get all conversations where user is a participant
    // Filter by company_id if user has one (to ensure company isolation)
    let conversationsQuery = `
      SELECT c.id, c.type, c.name, c.project_id, c.company_id, c.created_by, c.created_at, c.updated_at,
             cp.last_read_at
      FROM conversations c
      INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
      WHERE cp.user_id = $1
    `;
    const queryParams = [userId];

    if (userCompanyId) {
      conversationsQuery += ` AND (c.company_id = $2 OR c.company_id IS NULL)`;
      queryParams.push(userCompanyId);
    }

    conversationsQuery += ` ORDER BY c.updated_at DESC`;

    const conversationsResult = await pool.query(conversationsQuery, queryParams);

    // For each conversation, get last message and unread count
    const conversations = await Promise.all(
      conversationsResult.rows.map(async (conv) => {
        // Get last message
        const lastMessageResult = await pool.query(
          `SELECT m.id, m.message_text, m.message_type, m.created_at, m.sender_id,
                  u.first_name, u.last_name, u.photo_url
           FROM messages m
           INNER JOIN users u ON m.sender_id = u.id
           WHERE m.conversation_id = $1 AND m.is_deleted = FALSE
           ORDER BY m.created_at DESC
           LIMIT 1`,
          [conv.id]
        );

        // Get unread count (messages after last_read_at)
        const unreadResult = await pool.query(
          `SELECT COUNT(*) as count
           FROM messages
           WHERE conversation_id = $1 
           AND sender_id != $2 
           AND is_deleted = FALSE
           AND ($3::timestamp IS NULL OR created_at > $3)`,
          [conv.id, userId, conv.last_read_at]
        );

        // Get participant IDs and details
        const participantsResult = await pool.query(
          `SELECT cp.user_id, u.first_name, u.last_name, u.photo_url, u.email
           FROM conversation_participants cp
           INNER JOIN users u ON cp.user_id = u.id
           WHERE cp.conversation_id = $1`,
          [conv.id]
        );

        const lastMessage = lastMessageResult.rows[0] ? {
          id: lastMessageResult.rows[0].id,
          messageText: lastMessageResult.rows[0].message_text,
          messageType: lastMessageResult.rows[0].message_type,
          senderId: lastMessageResult.rows[0].sender_id,
          senderName: `${lastMessageResult.rows[0].first_name} ${lastMessageResult.rows[0].last_name}`,
          senderPhotoUrl: lastMessageResult.rows[0].photo_url,
          createdAt: lastMessageResult.rows[0].created_at.toISOString(),
        } : null;

        const participants = participantsResult.rows.map(p => ({
          userId: p.user_id,
          firstName: p.first_name,
          lastName: p.last_name,
          photoUrl: p.photo_url,
          email: p.email,
        }));

        return {
          id: conv.id,
          type: conv.type,
          name: conv.name,
          projectId: conv.project_id,
          companyId: conv.company_id,
          createdBy: conv.created_by,
          createdAt: conv.created_at.toISOString(),
          updatedAt: conv.updated_at.toISOString(),
          lastMessage: lastMessage,
          participantIds: participants.map(p => p.userId),
          participants: participants,
          unreadCount: parseInt(unreadResult.rows[0].count) || 0,
        };
      })
    );

    res.json(conversations);
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ error: 'Failed to fetch conversations', message: error.message });
  }
});

// GET messages for a conversation
router.get('/conversations/:conversationId/messages', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { limit = 50, offset = 0, userId } = req.query;

    // Verify conversation exists
    const convCheck = await pool.query(
      'SELECT id FROM conversations WHERE id = $1',
      [conversationId]
    );

    if (convCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Get messages with sender info and read status
    const result = await pool.query(
      `SELECT m.id, m.conversation_id, m.sender_id, m.message_text, m.message_type,
              m.file_url, m.file_name, m.file_size, m.is_edited, m.is_deleted,
              m.edited_at, m.created_at,
              u.first_name, u.last_name, u.photo_url,
              CASE 
                WHEN m.sender_id = $4 THEN 'sent'
                WHEN EXISTS (
                  SELECT 1 FROM message_reads mr 
                  WHERE mr.message_id = m.id AND mr.user_id = $4
                ) THEN 'read'
                ELSE 'sent'
              END as read_status
       FROM messages m
       INNER JOIN users u ON m.sender_id = u.id
       WHERE m.conversation_id = $1 AND m.is_deleted = FALSE
       ORDER BY m.created_at DESC
       LIMIT $2 OFFSET $3`,
      [conversationId, limit, offset, userId || null]
    );

    const messages = result.rows.map(row => ({
      id: row.id,
      conversationId: row.conversation_id,
      senderId: row.sender_id,
      senderName: `${row.first_name} ${row.last_name}`,
      senderPhotoUrl: row.photo_url || null,
      messageText: row.message_text,
      messageType: row.message_type || 'text',
      fileUrl: row.file_url || null,
      fileName: row.file_name || null,
      fileSize: row.file_size ? parseInt(row.file_size) : null,
      isEdited: row.is_edited || false,
      isDeleted: row.is_deleted || false,
      editedAt: row.edited_at ? row.edited_at.toISOString() : null,
      createdAt: row.created_at.toISOString(),
      readStatus: row.read_status || 'sent',
    }));

    // Reverse to get chronological order (oldest first)
    res.json(messages.reverse());
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ error: 'Failed to fetch messages', message: error.message });
  }
});

// POST create new conversation
router.post('/conversations', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { type, userIds, projectId, name, createdBy } = req.body;

    if (!type || !userIds || !Array.isArray(userIds) || userIds.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'type and userIds array are required' });
    }

    // Get company_id from the first user (all participants should be from same company)
    const userResult = await client.query(
      'SELECT company_id FROM users WHERE id = $1',
      [userIds[0]]
    );
    const companyId = userResult.rows[0]?.company_id;

    // For direct messages, check if conversation already exists
    if (type === 'direct' && userIds.length === 2) {
      const existingConv = await client.query(
        `SELECT c.id
         FROM conversations c
         INNER JOIN conversation_participants cp1 ON c.id = cp1.conversation_id
         INNER JOIN conversation_participants cp2 ON c.id = cp2.conversation_id
         WHERE c.type = 'direct'
         AND cp1.user_id = $1 AND cp2.user_id = $2
         AND cp1.user_id != cp2.user_id`,
        [userIds[0], userIds[1]]
      );

      if (existingConv.rows.length > 0) {
        const existingId = existingConv.rows[0].id;
        // Get full conversation details to return
        const existingConvDetails = await client.query(
          `SELECT id, type, name, project_id, company_id, created_by, created_at, updated_at
           FROM conversations WHERE id = $1`,
          [existingId]
        );
        const conv = existingConvDetails.rows[0];
        
        // Get participant IDs
        const participantsResult = await client.query(
          `SELECT user_id FROM conversation_participants WHERE conversation_id = $1`,
          [existingId]
        );
        
        await client.query('ROLLBACK');
        return res.status(200).json({ 
          id: conv.id,
          type: conv.type,
          name: conv.name,
          projectId: conv.project_id,
          companyId: conv.company_id,
          createdBy: conv.created_by,
          createdAt: conv.created_at.toISOString(),
          updatedAt: conv.updated_at.toISOString(),
          participantIds: participantsResult.rows.map(p => p.user_id),
        });
      }
    }

    // Create conversation
    const convResult = await client.query(
      `INSERT INTO conversations (type, name, project_id, company_id, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, type, name, project_id, company_id, created_by, created_at, updated_at`,
      [type, name || null, projectId || null, companyId, createdBy || null]
    );

    const conversation = convResult.rows[0];

    // Add participants
    for (const userId of userIds) {
      await client.query(
        `INSERT INTO conversation_participants (conversation_id, user_id)
         VALUES ($1, $2)
         ON CONFLICT (conversation_id, user_id) DO NOTHING`,
        [conversation.id, userId]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      id: conversation.id,
      type: conversation.type,
      name: conversation.name,
      projectId: conversation.project_id,
      companyId: conversation.company_id,
      createdBy: conversation.created_by,
      createdAt: conversation.created_at.toISOString(),
      updatedAt: conversation.updated_at.toISOString(),
      participantIds: userIds,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating conversation:', error);
    res.status(500).json({ error: 'Failed to create conversation', message: error.message });
  } finally {
    client.release();
  }
});

// POST send message
router.post('/messages', async (req, res) => {
  try {
    const { conversationId, senderId, messageText, messageType, fileUrl, fileName, fileSize } = req.body;

    if (!conversationId || !senderId || !messageText) {
      return res.status(400).json({ error: 'conversationId, senderId, and messageText are required' });
    }

    // Verify user is participant
    const participantCheck = await pool.query(
      `SELECT user_id FROM conversation_participants 
       WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, senderId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({ error: 'User is not a participant in this conversation' });
    }

    // Insert message
    const messageResult = await pool.query(
      `INSERT INTO messages (conversation_id, sender_id, message_text, message_type, file_url, file_name, file_size)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, conversation_id, sender_id, message_text, message_type, file_url, file_name,
                 file_size, is_edited, is_deleted, created_at`,
      [conversationId, senderId, messageText, messageType || 'text', fileUrl || null, fileName || null, fileSize || null]
    );

    // Update conversation updated_at
    await pool.query(
      `UPDATE conversations SET updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [conversationId]
    );

    // Get sender info
    const senderResult = await pool.query(
      `SELECT first_name, last_name, photo_url FROM users WHERE id = $1`,
      [senderId]
    );

    const sender = senderResult.rows[0];
    const message = messageResult.rows[0];

    const messageData = {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      senderName: `${sender.first_name} ${sender.last_name}`,
      senderPhotoUrl: sender.photo_url || null,
      messageText: message.message_text,
      messageType: message.message_type || 'text',
      fileUrl: message.file_url || null,
      fileName: message.file_name || null,
      fileSize: message.file_size ? parseInt(message.file_size) : null,
      isEdited: message.is_edited || false,
      isDeleted: message.is_deleted || false,
      createdAt: message.created_at.toISOString(),
      readStatus: 'sent', // New messages start as 'sent'
    };

    // Emit to Socket.io if available
    const io = req.app.get('io');
    if (io) {
      // Emit to conversation room (users currently viewing this conversation)
      io.to(`conversation-${conversationId}`).emit('new-message', messageData);
      
      // Also emit to each participant's personal room for notifications
      // (this ensures users receive messages even if not viewing the conversation)
      const participantsResult = await pool.query(
        `SELECT user_id FROM conversation_participants WHERE conversation_id = $1`,
        [conversationId]
      );
      
      for (const participant of participantsResult.rows) {
        if (participant.user_id !== senderId) { // Don't send to sender
          io.to(`user-${participant.user_id}`).emit('new-message', messageData);
        }
      }
      
      console.log(`[CHAT] Emitted message ${messageData.id} to conversation ${conversationId} and ${participantsResult.rows.length} participants`);
    }

    res.status(201).json(messageData);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ error: 'Failed to send message', message: error.message });
  }
});

// PUT mark conversation as read
router.put('/conversations/:conversationId/read', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required in request body' });
    }

    // Update last_read_at
    await pool.query(
      `UPDATE conversation_participants 
       SET last_read_at = CURRENT_TIMESTAMP 
       WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    // Mark all messages in this conversation as read by this user
    await pool.query(
      `INSERT INTO message_reads (message_id, user_id, read_at)
       SELECT m.id, $2, CURRENT_TIMESTAMP
       FROM messages m
       WHERE m.conversation_id = $1 
         AND m.sender_id != $2 
         AND m.is_deleted = FALSE
         AND NOT EXISTS (
           SELECT 1 FROM message_reads mr 
           WHERE mr.message_id = m.id AND mr.user_id = $2
         )
       ON CONFLICT (message_id, user_id) DO NOTHING`,
      [conversationId, userId]
    );

    // Emit read receipts update
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation-${conversationId}`).emit('messages-read', {
        conversationId,
        userId,
      });
    }

    res.json({ success: true, message: 'Conversation marked as read' });
  } catch (error) {
    console.error('Error marking conversation as read:', error);
    res.status(500).json({ error: 'Failed to mark conversation as read', message: error.message });
  }
});

// GET conversation by ID with participants
router.get('/conversations/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;

    const convResult = await pool.query(
      `SELECT id, type, name, project_id, company_id, created_by, created_at, updated_at
       FROM conversations
       WHERE id = $1`,
      [conversationId]
    );

    if (convResult.rows.length === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    const conversation = convResult.rows[0];

    // Get participants
    const participantsResult = await pool.query(
      `SELECT cp.user_id, u.first_name, u.last_name, u.photo_url, u.email
       FROM conversation_participants cp
       INNER JOIN users u ON cp.user_id = u.id
       WHERE cp.conversation_id = $1`,
      [conversationId]
    );

    res.json({
      id: conversation.id,
      type: conversation.type,
      name: conversation.name,
      projectId: conversation.project_id,
      companyId: conversation.company_id,
      createdBy: conversation.created_by,
      createdAt: conversation.created_at.toISOString(),
      updatedAt: conversation.updated_at.toISOString(),
      participants: participantsResult.rows.map(p => ({
        userId: p.user_id,
        firstName: p.first_name,
        lastName: p.last_name,
        photoUrl: p.photo_url,
        email: p.email,
      })),
    });
  } catch (error) {
    console.error('Error fetching conversation:', error);
    res.status(500).json({ error: 'Failed to fetch conversation', message: error.message });
  }
});

// PUT edit message
router.put('/messages/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    const { messageText, senderId } = req.body;

    if (!messageText || !senderId) {
      return res.status(400).json({ error: 'messageText and senderId are required' });
    }

    // Verify sender owns the message
    const messageCheck = await pool.query(
      `SELECT sender_id, conversation_id FROM messages WHERE id = $1 AND is_deleted = FALSE`,
      [messageId]
    );

    if (messageCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found' });
    }

    if (messageCheck.rows[0].sender_id !== senderId) {
      return res.status(403).json({ error: 'You can only edit your own messages' });
    }

    // Update message
    const result = await pool.query(
      `UPDATE messages 
       SET message_text = $1, is_edited = TRUE, edited_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING id, conversation_id, sender_id, message_text, message_type, file_url, file_name,
                 file_size, is_edited, is_deleted, edited_at, created_at`,
      [messageText, messageId]
    );

    const message = result.rows[0];

    // Get sender info
    const senderResult = await pool.query(
      `SELECT first_name, last_name, photo_url FROM users WHERE id = $1`,
      [senderId]
    );

    const sender = senderResult.rows[0];

    const messageData = {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      senderName: `${sender.first_name} ${sender.last_name}`,
      senderPhotoUrl: sender.photo_url || null,
      messageText: message.message_text,
      messageType: message.message_type || 'text',
      fileUrl: message.file_url || null,
      fileName: message.file_name || null,
      fileSize: message.file_size ? parseInt(message.file_size) : null,
      isEdited: message.is_edited || false,
      isDeleted: message.is_deleted || false,
      editedAt: message.edited_at ? message.edited_at.toISOString() : null,
      createdAt: message.created_at.toISOString(),
    };

    // Emit update to Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation-${message.conversation_id}`).emit('message-updated', messageData);
    }

    res.json(messageData);
  } catch (error) {
    console.error('Error editing message:', error);
    res.status(500).json({ error: 'Failed to edit message', message: error.message });
  }
});

// DELETE message
router.delete('/messages/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    const { senderId } = req.body;

    if (!senderId) {
      return res.status(400).json({ error: 'senderId is required' });
    }

    // Verify sender owns the message
    const messageCheck = await pool.query(
      `SELECT sender_id, conversation_id FROM messages WHERE id = $1`,
      [messageId]
    );

    if (messageCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found' });
    }

    if (messageCheck.rows[0].sender_id !== senderId) {
      return res.status(403).json({ error: 'You can only delete your own messages' });
    }

    // Soft delete message
    const result = await pool.query(
      `UPDATE messages 
       SET is_deleted = TRUE, message_text = '[Message deleted]', updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, conversation_id, sender_id, message_text, message_type, file_url, file_name,
                 file_size, is_edited, is_deleted, edited_at, created_at`,
      [messageId]
    );

    const message = result.rows[0];

    // Get sender info
    const senderResult = await pool.query(
      `SELECT first_name, last_name, photo_url FROM users WHERE id = $1`,
      [senderId]
    );

    const sender = senderResult.rows[0];

    const messageData = {
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      senderName: `${sender.first_name} ${sender.last_name}`,
      senderPhotoUrl: sender.photo_url || null,
      messageText: message.message_text,
      messageType: message.message_type || 'text',
      fileUrl: message.file_url || null,
      fileName: message.file_name || null,
      fileSize: message.file_size ? parseInt(message.file_size) : null,
      isEdited: message.is_edited || false,
      isDeleted: message.is_deleted || false,
      editedAt: message.edited_at ? message.edited_at.toISOString() : null,
      createdAt: message.created_at.toISOString(),
    };

    // Emit update to Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation-${message.conversation_id}`).emit('message-deleted', messageData);
    }

    res.json({ success: true, message: messageData });
  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json({ error: 'Failed to delete message', message: error.message });
  }
});

// DELETE conversation
router.delete('/conversations/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    // Verify user is a participant
    const participantCheck = await pool.query(
      `SELECT user_id FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({ error: 'You are not a participant in this conversation' });
    }

    // Remove user from conversation (soft delete - just remove them as participant)
    await pool.query(
      `DELETE FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    // If no participants left, delete the conversation and all messages
    const remainingParticipants = await pool.query(
      `SELECT COUNT(*) as count FROM conversation_participants WHERE conversation_id = $1`,
      [conversationId]
    );

    if (parseInt(remainingParticipants.rows[0].count) === 0) {
      // Delete all messages
      await pool.query(`DELETE FROM messages WHERE conversation_id = $1`, [conversationId]);
      // Delete conversation
      await pool.query(`DELETE FROM conversations WHERE id = $1`, [conversationId]);
    }

    // Emit to Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation-${conversationId}`).emit('conversation-deleted', { conversationId, userId });
    }

    res.json({ success: true, message: 'Conversation deleted' });
  } catch (error) {
    console.error('Error deleting conversation:', error);
    res.status(500).json({ error: 'Failed to delete conversation', message: error.message });
  }
});

module.exports = router;

