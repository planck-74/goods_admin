import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goods_admin/data/models/chat_message.dart';

/// Repository handling all admin chat operations
/// Manages communication with clients through customer service
class AdminChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  AdminChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ==================== Message Operations ====================

  /// Get messages stream for a specific client chat
  Stream<List<ChatMessage>> getMessagesStream({
    required String clientId,
    int limit = 20,
  }) {
    return _firestore
        .collection('chats')
        .doc(clientId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Send text message from customer service to client
  Future<void> sendTextMessage({
    required String clientId,
    required String text,
    String? replyToId,
  }) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) throw Exception('Admin not authenticated');

    final messageData = {
      'sender': adminId,
      'recipientId': clientId,
      'senderId': adminId,
      'isFromClient': false, // CRITICAL: This is from customer service
      'text': text,
      'type': MessageType.text.name,
      'timestamp': FieldValue.serverTimestamp(),
      'status': MessageStatus.sent.name,
      'isEdited': false,
      if (replyToId != null) 'replyToId': replyToId,
    };

    final chatDocRef = _firestore.collection('chats').doc(clientId);
    await chatDocRef.collection('messages').add(messageData);

    // Update last message metadata
    await _updateLastMessage(
      clientId: clientId,
      message: text,
      isFromClient: false,
    );
  }

  /// Send message with file attachment
  Future<void> sendFileMessage({
    required String clientId,
    required File file,
    required String fileName,
    required MessageType type,
    String? replyToId,
    Function(double)? onProgress,
  }) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) throw Exception('Admin not authenticated');

    final chatDocRef = _firestore.collection('chats').doc(clientId);

    // Create temporary message with "sending" status
    final tempMessageRef = await chatDocRef.collection('messages').add({
      'sender': adminId,
      'recipientId': clientId,
      'senderId': adminId,
      'isFromClient': false,
      'fileName': fileName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      'status': MessageStatus.sending.name,
      'uploading': true,
      if (replyToId != null) 'replyToId': replyToId,
    });

    try {
      // Upload file to storage
      final downloadUrl = await _uploadFile(
        file: file,
        fileName: fileName,
        clientId: clientId,
        type: type,
        onProgress: onProgress,
      );

      // Update message with download URL
      await tempMessageRef.update({
        'file': downloadUrl,
        'fileUrl': downloadUrl,
        'uploading': false,
        'status': MessageStatus.sent.name,
      });

      // Update last message
      final lastMessageText = _getLastMessageText(type, fileName);
      await _updateLastMessage(
        clientId: clientId,
        message: lastMessageText,
        isFromClient: false,
      );
    } catch (e) {
      // Mark as failed on error
      await tempMessageRef.update({
        'status': MessageStatus.failed.name,
        'uploading': false,
      });
      rethrow;
    }
  }

  /// Delete a single message
  Future<void> deleteMessage({
    required String clientId,
    required String messageId,
  }) async {
    await _firestore
        .collection('chats')
        .doc(clientId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Delete multiple messages in batch
  Future<void> deleteMessages({
    required String clientId,
    required List<String> messageIds,
  }) async {
    final batch = _firestore.batch();

    for (final messageId in messageIds) {
      final docRef = _firestore
          .collection('chats')
          .doc(clientId)
          .collection('messages')
          .doc(messageId);
      batch.delete(docRef);
    }

    await batch.commit();
  }

  /// Clear entire chat history
  Future<void> clearChat(String clientId) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('chats')
        .doc(clientId)
        .collection('messages')
        .get();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Mark messages as read (admin viewing client messages)
  Future<void> markMessagesAsRead({
    required String clientId,
    required List<ChatMessage> messages,
  }) async {
    final batch = _firestore.batch();
    final adminId = _auth.currentUser?.uid;

    for (final message in messages) {
      // Only mark client messages as read (not admin's own messages)
      if (message.senderId != adminId && message.status != MessageStatus.read) {
        final docRef = _firestore
            .collection('chats')
            .doc(clientId)
            .collection('messages')
            .doc(message.id);
        batch.update(docRef, {'status': MessageStatus.read.name});
      }
    }

    await batch.commit();
  }

  // ==================== Chat Metadata Operations ====================

  /// Reset unread count when admin opens chat
  Future<void> resetUnreadCount(String clientId) async {
    await _firestore
        .collection('chats')
        .doc(clientId)
        .set({'unreadCount': 0}, SetOptions(merge: true));
  }

  /// Update last message metadata
  Future<void> _updateLastMessage({
    required String clientId,
    required String message,
    required bool isFromClient,
  }) async {
    final updateData = {
      'clientId': clientId,
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only increment unread if message is from admin (to client)
    if (!isFromClient) {
      updateData['unreadCount'] = FieldValue.increment(1);
    }

    await _firestore.collection('chats').doc(clientId).set(
          updateData,
          SetOptions(merge: true),
        );
  }

  // ==================== File Upload ====================

  Future<String> _uploadFile({
    required File file,
    required String fileName,
    required String clientId,
    required MessageType type,
    Function(double)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = '${timestamp}_$fileName';
    final folderPath = _getFolderPath(type);
    final storageRef =
        _storage.ref('$folderPath/admin_$clientId/$uniqueFileName');

    final uploadTask = storageRef.putFile(file);

    // Track upload progress
    uploadTask.snapshotEvents.listen((snapshot) {
      if (onProgress != null) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  String _getFolderPath(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'chat_images';
      case MessageType.file:
        return 'chat_files';
      case MessageType.voice:
        return 'chat_voice';
      default:
        return 'chat_files';
    }
  }

  String _getLastMessageText(MessageType type, String fileName) {
    switch (type) {
      case MessageType.image:
        return '📷 صورة';
      case MessageType.file:
        return '📄 $fileName';
      case MessageType.voice:
        return '🎤 رسالة صوتية';
      default:
        return fileName;
    }
  }
}
