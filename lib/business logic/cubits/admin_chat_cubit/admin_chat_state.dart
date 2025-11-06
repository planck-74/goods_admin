import 'package:goods_admin/data/models/chat_message.dart';

/// State class for admin chat management
class AdminChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final String? error;
  final int messageLimit;

  // Selection mode
  final Set<String> selectedMessageIds;
  final bool isSelectionMode;

  // Reply functionality
  final ChatMessage? replyToMessage;

  // Search functionality
  final bool isSearchMode;
  final String searchQuery;

  const AdminChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.error,
    this.messageLimit = 20,
    this.selectedMessageIds = const {},
    this.isSelectionMode = false,
    this.replyToMessage,
    this.isSearchMode = false,
    this.searchQuery = '',
  });

  AdminChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    String? Function()? error,
    int? messageLimit,
    Set<String>? selectedMessageIds,
    bool? isSelectionMode,
    ChatMessage? Function()? replyToMessage,
    bool? isSearchMode,
    String? searchQuery,
  }) {
    return AdminChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      error: error != null ? error() : this.error,
      messageLimit: messageLimit ?? this.messageLimit,
      selectedMessageIds: selectedMessageIds ?? this.selectedMessageIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      replyToMessage:
          replyToMessage != null ? replyToMessage() : this.replyToMessage,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
