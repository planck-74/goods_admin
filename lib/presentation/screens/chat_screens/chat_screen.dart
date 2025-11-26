import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/admin_chat_cubit/admin_chat_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/admin_chat_cubit/admin_chat_state.dart';
import 'package:goods_admin/data/functions/open_google_maps.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/chat_message.dart';
import 'package:goods_admin/data/models/client_model.dart';
import 'package:goods_admin/data/repositories/admin_chat_repo.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/screens/chat_screens/chat_textfield.dart';
import 'package:goods_admin/presentation/screens/chat_screens/full_screen_image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _setupAnimations();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 0) {
        context.read<AdminChatCubit>().loadMoreMessages();
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showClientProfile(
      String clientId, Map<String, dynamic> clientData) async {
    // Fetch full client data
    try {
      final clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .get();

      if (!clientDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على بيانات العميل')),
        );
        return;
      }

      final client = ClientModel.fromDocumentSnapshot(clientDoc);

      // Fetch client note
      final noteDoc = await FirebaseFirestore.instance
          .collection('admin_data')
          .doc('client_notes')
          .get();

      String? clientNote;
      if (noteDoc.exists) {
        final notes = noteDoc.data();
        clientNote = notes?[clientId];
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ClientProfileSheet(
          client: client,
          clientNote: clientNote,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final String clientId = arguments['clientId'];
    final Map<String, dynamic> clientData = arguments['clientData'];

    return BlocProvider(
      create: (context) => AdminChatCubit(
        repository: AdminChatRepository(),
        clientId: clientId,
      ),
      child: BlocConsumer<AdminChatCubit, AdminChatState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<AdminChatCubit>().clearError();
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: _buildAppBar(context, state, clientData, clientId),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE3F2FD),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: _buildChatContent(context, state, clientId),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AdminChatState state,
    Map<String, dynamic>? clientData,
    String clientId,
  ) {
    if (state.isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.read<AdminChatCubit>().exitSelectionMode(),
        ),
        title: Text(
          '${state.selectedMessageIds.length} محدد',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () {
              final text =
                  context.read<AdminChatCubit>().getSelectedMessagesText();
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ الرسائل')),
              );
              context.read<AdminChatCubit>().exitSelectionMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () =>
                context.read<AdminChatCubit>().deleteSelectedMessages(),
          ),
        ],
      );
    }

    return customAppBar(
      context,
      GestureDetector(
        onTap: () => _showClientProfile(clientId, clientData ?? {}),
        child: Row(
          children: [
            if (clientData != null)
              Hero(
                tag: 'client_avatar_$clientId',
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: clientData['imageUrl'] != null &&
                            clientData['imageUrl'].toString().isNotEmpty
                        ? DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(clientData['imageUrl']),
                          )
                        : null,
                  ),
                  child: clientData['imageUrl'] == null ||
                          clientData['imageUrl'].toString().isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    clientData?['businessName'] ?? 'العميل',
                    style: const TextStyle(
                      color: whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'اضغط للمزيد من المعلومات',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () =>
                  context.read<AdminChatCubit>().toggleSearchMode(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showMoreOptions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(
      BuildContext context, AdminChatState state, String clientId) {
    return Column(
      children: [
        if (state.isSearchMode) _buildSearchBar(context, state),
        if (state.replyToMessage != null)
          _buildReplyPreview(context, state.replyToMessage!),
        Expanded(child: _buildMessagesList(context, state)),
        AdminChatTextfield(
          clientId: clientId,
          replyToMessage: state.replyToMessage,
          onClearReply: () => context.read<AdminChatCubit>().clearReply(),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, AdminChatState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: TextField(
        decoration: InputDecoration(
          hintText: 'البحث في الرسائل...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.read<AdminChatCubit>().toggleSearchMode(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) =>
            context.read<AdminChatCubit>().updateSearchQuery(value),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, ChatMessage replyMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرد على:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  replyMessage.text ?? '[مرفق]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => context.read<AdminChatCubit>().clearReply(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, AdminChatState state) {
    if (state.isLoading) {
      return const ChatMessagesSkeleton();
    }

    final messages = context.read<AdminChatCubit>().filteredMessages;

    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        reverse: true,
        padding: const EdgeInsets.only(bottom: 8, top: 10),
        itemCount: messages.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && state.isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildMessageItem(context, messages[index], index, messages);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد رسائل بعد',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ المحادثة مع العميل',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ChatMessage message,
    int index,
    List<ChatMessage> messages,
  ) {
    final cubit = context.read<AdminChatCubit>();
    final state = context.watch<AdminChatCubit>().state;

    final bool isMe = message.senderId != cubit.clientId;
    final bool isSelected = state.selectedMessageIds.contains(message.id);

    bool showDateHeader = false;
    if (index == messages.length - 1) {
      showDateHeader = true;
    } else {
      final currentDate = DateFormat('yyyy-MM-dd').format(message.timestamp);
      final previousDate =
          DateFormat('yyyy-MM-dd').format(messages[index + 1].timestamp);
      showDateHeader = currentDate != previousDate;
    }

    return Column(
      children: [
        if (showDateHeader) _buildDateHeader(message.timestamp),
        GestureDetector(
          onLongPress: () => cubit.toggleMessageSelection(message.id),
          onTap: state.isSelectionMode
              ? () => cubit.toggleMessageSelection(message.id)
              : null,
          child: Container(
            color: isSelected ? Colors.red.withOpacity(0.1) : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _buildMessageBubble(context, message, isMe),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            DateFormat.yMMMMd('ar').format(date),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    bool isMe,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context, message),
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 50 : 0,
            right: isMe ? 0 : 50,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyToId != null) _buildReplyIndicator(message),
              _buildMessageContent(context, message, isMe),
              const SizedBox(height: 4),
              _buildMessageFooter(message, isMe),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyIndicator(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'رد على رسالة',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, ChatMessage message, bool isMe) {
    final contentPadding =
        (message.type == MessageType.image && message.fileUrl != null)
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe
              ? [const Color(0xFFFF5722), const Color(0xFFD32F2F)]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.type == MessageType.image && message.fileUrl != null)
            _buildImageMessage(context, message),
          if (message.text != null && message.text!.trim().isNotEmpty)
            Text(
              message.text!,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.3,
              ),
            ),
          if (message.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'تم التعديل',
                style: TextStyle(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context, ChatMessage message) {
    final heroTag = 'image_${message.id}';

    return Container(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(
                imageUrl: message.fileUrl!,
                clientName: '',
              ),
            ),
          );
        },
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.fileUrl!,
              width: 240,
              height: 240,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 8),
                      Text('فشل التحميل', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageFooter(ChatMessage message, bool isMe) {
    String formattedTime = DateFormat('hh:mm a').format(message.timestamp);
    formattedTime =
        formattedTime.replaceAll('AM', 'صباحاً').replaceAll('PM', 'مساءً');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildMessageStatusIcon(message.status),
        ],
      ],
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final cubit = context.read<AdminChatCubit>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(context);
                cubit.setReplyMessage(message);
              },
            ),
            if (message.text != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('نسخ'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ النص')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                cubit.deleteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final cubit = context.read<AdminChatCubit>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('مسح المحادثة'),
              onTap: () {
                Navigator.pop(context);
                cubit.clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('حظر'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ClientProfileSheet extends StatefulWidget {
  final ClientModel client;
  final String? clientNote;

  const ClientProfileSheet({
    super.key,
    required this.client,
    this.clientNote,
  });

  @override
  State<ClientProfileSheet> createState() => _ClientProfileSheetState();
}

class _ClientProfileSheetState extends State<ClientProfileSheet> {
  late TextEditingController _noteController;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.clientNote ?? '');
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSavingNote = true;
    });

    try {
      final noteText = _noteController.text.trim();

      if (noteText.isEmpty) {
        await FirebaseFirestore.instance
            .collection('admin_data')
            .doc('client_notes')
            .update({widget.client.uid: FieldValue.delete()});
      } else {
        await FirebaseFirestore.instance
            .collection('admin_data')
            .doc('client_notes')
            .set(
          {widget.client.uid: noteText},
          SetOptions(merge: true),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملاحظة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الملاحظة: $e')),
      );
    } finally {
      setState(() {
        _isSavingNote = false;
      });
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'غير متوفر';
    return DateFormat('dd/MM/yyyy hh:mm a', 'ar').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Hero(
                        tag: 'client_avatar_${widget.client.uid}',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 3),
                            image: widget.client.imageUrl != null &&
                                    widget.client.imageUrl!.isNotEmpty
                                ? DecorationImage(
                                    fit: BoxFit.cover,
                                    image:
                                        NetworkImage(widget.client.imageUrl!),
                                  )
                                : null,
                          ),
                          child: widget.client.imageUrl == null ||
                                  widget.client.imageUrl!.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        widget.client.businessName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.client.category,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoSection(
                      'معلومات الاتصال',
                      [
                        _buildInfoRow(Icons.phone, 'الهاتف الأول',
                            widget.client.phoneNumber),
                        if (widget.client.secondPhoneNumber!.isNotEmpty)
                          _buildInfoRow(Icons.phone, 'الهاتف الثاني',
                              widget.client.secondPhoneNumber ?? ""),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      'العنوان',
                      [
                        _buildInfoRow(Icons.location_city, 'المحافظة',
                            widget.client.government),
                        _buildInfoRow(
                            Icons.location_on, 'المدينة', widget.client.town),
                        _buildInfoRow(
                            Icons.place, 'المنطقة', widget.client.area),
                        if (widget.client.addressTyped.isNotEmpty)
                          _buildInfoRow(Icons.edit_location, 'العنوان التفصيلي',
                              widget.client.addressTyped),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.client.geoLocation != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          openMap(
                            widget.client.geoLocation!.latitude,
                            widget.client.geoLocation!.longitude,
                          );
                        },
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text('عرض الموقع على الخريطة',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      'التقارير',
                      [
                        _buildInfoRow(Icons.calendar_today, 'تاريخ الانضمام',
                            _formatDateTime(widget.client.dateCreated)),
                        _buildInfoRow(Icons.access_time, 'آخر نشاط',
                            _formatDateTime(widget.client.lastTokenUpdate)),
                        _buildInfoRow(
                            Icons.shopping_cart,
                            'حالة العربة',
                            widget.client.fullCart == true
                                ? 'ممتلئة'
                                : 'فارغة'),
                        _buildInfoRow(Icons.devices, 'عدد الأجهزة',
                            widget.client.totalDevices?.toString() ?? '0'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'ملاحظات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'أضف ملاحظاتك حول هذا العميل...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSavingNote ? null : _saveNote,
                              icon: _isSavingNote
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save, color: Colors.white),
                              label: Text(
                                _isSavingNote
                                    ? 'جاري الحفظ...'
                                    : 'حفظ الملاحظة',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: 8,
        itemBuilder: (context, index) {
          final bool isMe = index % 2 == 0;
          final bool hasImage = index % 3 == 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(
                  left: isMe ? 50 : 0,
                  right: isMe ? 0 : 50,
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (hasImage)
                      Container(
                        width: 200,
                        height: 150,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.red[100] : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
