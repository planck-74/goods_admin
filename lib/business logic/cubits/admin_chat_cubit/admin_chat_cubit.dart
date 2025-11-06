import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/admin_chat_cubit/admin_chat_state.dart';
import 'package:goods_admin/data/models/chat_message.dart';
import 'package:goods_admin/data/repositories/admin_chat_repo.dart';

/// Cubit managing admin chat state and business logic
/// Handles conversation between customer service and clients
class AdminChatCubit extends Cubit<AdminChatState> {
  final AdminChatRepository _repository;
  final String clientId;

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  AdminChatCubit({
    required AdminChatRepository repository,
    required this.clientId,
  })  : _repository = repository,
        super(const AdminChatState()) {
    _init();
  }

  void _init() {
    _loadMessages();
    _resetUnreadCount();
  }

  // ==================== Message Loading ====================

  void _loadMessages() {
    emit(state.copyWith(isLoading: true));

    _messagesSubscription = _repository
        .getMessagesStream(clientId: clientId, limit: state.messageLimit)
        .listen(
      (messages) {
        emit(state.copyWith(
          messages: messages,
          isLoading: false,
        ));
        _markMessagesAsRead(messages);
      },
      onError: (error) {
        emit(state.copyWith(
          isLoading: false,
          error: () => error.toString(),
        ));
      },
    );
  }

  void loadMoreMessages() {
    if (state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    // Cancel current subscription
    _messagesSubscription?.cancel();

    // Increase limit and reload
    final newLimit = state.messageLimit + 20;
    _messagesSubscription = _repository
        .getMessagesStream(clientId: clientId, limit: newLimit)
        .listen(
      (messages) {
        emit(state.copyWith(
          messages: messages,
          messageLimit: newLimit,
          isLoadingMore: false,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          isLoadingMore: false,
          error: () => error.toString(),
        ));
      },
    );
  }

  // ==================== Sending Messages ====================

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    // Prevent duplicate sends
    if (state.isSending) {
      return;
    }

    emit(state.copyWith(
      isSending: true,
      error: () => null,
    ));

    try {
      await _repository.sendTextMessage(
        clientId: clientId,
        text: text.trim(),
        replyToId: state.replyToMessage?.id,
      );

      // Clear reply and stop sending
      emit(state.copyWith(
        isSending: false,
        replyToMessage: () => null,
        error: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        error: () => 'فشل إرسال الرسالة: $e',
      ));
    }
  }

  Future<void> sendFileMessage({
    required File file,
    required String fileName,
    required MessageType type,
    Function(double)? onProgress,
  }) async {
    // Prevent duplicate sends
    if (state.isSending) {
      return;
    }

    emit(state.copyWith(
      isSending: true,
      error: () => null,
    ));

    try {
      await _repository.sendFileMessage(
        clientId: clientId,
        file: file,
        fileName: fileName,
        type: type,
        replyToId: state.replyToMessage?.id,
        onProgress: onProgress,
      );

      emit(state.copyWith(
        isSending: false,
        replyToMessage: () => null,
        error: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        error: () => 'فشل إرسال الملف: $e',
      ));
    }
  }

  // ==================== Message Actions ====================

  Future<void> deleteMessage(String messageId) async {
    try {
      await _repository.deleteMessage(
        clientId: clientId,
        messageId: messageId,
      );
    } catch (e) {
      emit(state.copyWith(
        error: () => 'فشل حذف الرسالة: $e',
      ));
    }
  }

  Future<void> deleteSelectedMessages() async {
    if (state.selectedMessageIds.isEmpty) return;

    try {
      await _repository.deleteMessages(
        clientId: clientId,
        messageIds: state.selectedMessageIds.toList(),
      );

      // Exit selection mode
      exitSelectionMode();
    } catch (e) {
      emit(state.copyWith(
        error: () => 'فشل حذف الرسائل: $e',
      ));
    }
  }

  Future<void> clearChat() async {
    try {
      await _repository.clearChat(clientId);
    } catch (e) {
      emit(state.copyWith(
        error: () => 'فشل مسح المحادثة: $e',
      ));
    }
  }

  // ==================== Selection Mode ====================

  void toggleMessageSelection(String messageId) {
    final selectedIds = Set<String>.from(state.selectedMessageIds);

    if (selectedIds.contains(messageId)) {
      selectedIds.remove(messageId);
    } else {
      selectedIds.add(messageId);
    }

    emit(state.copyWith(
      selectedMessageIds: selectedIds,
      isSelectionMode: selectedIds.isNotEmpty,
    ));
  }

  void exitSelectionMode() {
    emit(state.copyWith(
      selectedMessageIds: {},
      isSelectionMode: false,
    ));
  }

  String getSelectedMessagesText() {
    final selectedMessages = state.messages
        .where((msg) => state.selectedMessageIds.contains(msg.id))
        .map((msg) => msg.text ?? '[مرفق]')
        .join('\n');
    return selectedMessages;
  }

  // ==================== Reply ====================

  void setReplyMessage(ChatMessage message) {
    emit(state.copyWith(
      replyToMessage: () => message,
    ));
  }

  void clearReply() {
    emit(state.copyWith(
      replyToMessage: () => null,
    ));
  }

  // ==================== Search ====================

  void toggleSearchMode() {
    emit(state.copyWith(
      isSearchMode: !state.isSearchMode,
      searchQuery: '', // Clear search when toggling
    ));
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  List<ChatMessage> get filteredMessages {
    if (state.searchQuery.isEmpty) return state.messages;

    return state.messages.where((message) {
      return message.text
              ?.toLowerCase()
              .contains(state.searchQuery.toLowerCase()) ??
          false;
    }).toList();
  }

  // ==================== Private Methods ====================

  Future<void> _markMessagesAsRead(List<ChatMessage> messages) async {
    try {
      await _repository.markMessagesAsRead(
        clientId: clientId,
        messages: messages,
      );
    } catch (e) {
      // Silent fail - don't disrupt user experience
    }
  }

  Future<void> _resetUnreadCount() async {
    try {
      await _repository.resetUnreadCount(clientId);
    } catch (e) {
      // Silent fail
    }
  }

  void clearError() {
    emit(state.copyWith(
      error: () => null,
    ));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
