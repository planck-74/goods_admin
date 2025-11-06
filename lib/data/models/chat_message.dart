import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file, voice }

enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final bool isFromClient; // CRITICAL: Determines message direction
  final String? text;
  final String? fileUrl;
  final String? fileName;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToId;
  final bool isEdited;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.isFromClient,
    this.text,
    this.fileUrl,
    this.fileName,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.isEdited = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? data['sender'] ?? '',
      recipientId: data['recipientId'] ?? '',
      isFromClient: data['isFromClient'] ?? true, // Default to client message
      text: data['text'],
      fileUrl: data['fileUrl'] ?? data['file'],
      fileName: data['fileName'],
      type: _parseMessageType(data['type']),
      timestamp: _parseTimestamp(data['timestamp']),
      status: _parseMessageStatus(data['status']),
      replyToId: data['replyToId'],
      isEdited: data['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'isFromClient': isFromClient,
      if (text != null) 'text': text,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      if (replyToId != null) 'replyToId': replyToId,
      'isEdited': isEdited,
    };
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;

    try {
      return MessageType.values.firstWhere(
        (e) => e.name == type.toString() || e.toString() == 'MessageType.$type',
        orElse: () => MessageType.text,
      );
    } catch (e) {
      return MessageType.text;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    }

    return DateTime.now();
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;

    try {
      return MessageStatus.values.firstWhere(
        (e) =>
            e.name == status.toString() ||
            e.toString() == 'MessageStatus.$status',
        orElse: () => MessageStatus.sent,
      );
    } catch (e) {
      return MessageStatus.sent;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    bool? isFromClient,
    String? text,
    String? fileUrl,
    String? fileName,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToId,
    bool? isEdited,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      isFromClient: isFromClient ?? this.isFromClient,
      text: text ?? this.text,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
