import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/admin_chat_cubit/admin_chat_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/admin_chat_cubit/admin_chat_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:goods_admin/data/models/chat_message.dart';

class AdminChatTextfield extends StatefulWidget {
  final String clientId;
  final ChatMessage? replyToMessage;
  final VoidCallback? onClearReply;

  const AdminChatTextfield({
    super.key,
    required this.clientId,
    this.replyToMessage,
    this.onClearReply,
  });

  @override
  _AdminChatTextfieldState createState() => _AdminChatTextfieldState();
}

class _AdminChatTextfieldState extends State<AdminChatTextfield>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  final List<AttachmentFile> _attachments = [];

  late AnimationController _sendButtonController;
  late AnimationController _attachmentController;
  late Animation<double> _sendButtonAnimation;
  late Animation<double> _attachmentAnimation;
  bool _isSending = false;

  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _setupMessageListener();
  }

  void _setupControllers() {
    _messageController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );
    _attachmentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _attachmentController, curve: Curves.easeInOut),
    );
  }

  void _setupMessageListener() {
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      final hasAttachments = _attachments.isNotEmpty;

      if (hasText || hasAttachments) {
        if (!_sendButtonController.isAnimating) {
          _sendButtonController.forward();
        }
      } else {
        if (!_sendButtonController.isAnimating) {
          _sendButtonController.reverse();
        }
      }
    });
  }

  void _onTextChanged() {
    final text = _messageController.text;
    if (text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      _sendTypingIndicator();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _attachmentController.forward();
    } else {
      _attachmentController.reverse();
    }
  }

  Future<void> _sendTypingIndicator() async {
    // TODO: Implement typing indicator if needed
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (files.isNotEmpty) {
        setState(() {
          for (var file in files) {
            _attachments.add(AttachmentFile(
              path: file.path,
              type: AttachmentType.image,
              name: file.name,
            ));
          }
        });
      }
    } catch (e) {
      _showErrorMessage('خطأ في اختيار الصور: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _attachments.add(AttachmentFile(
                path: file.path!,
                type: AttachmentType.file,
                name: file.name,
                size: file.size,
              ));
            }
          }
        });
      }
    } catch (e) {
      _showErrorMessage('خطأ في اختيار الملفات: $e');
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          _attachments.add(AttachmentFile(
            path: file.path,
            type: AttachmentType.image,
            name: file.name,
          ));
        });
      }
    } catch (e) {
      _showErrorMessage('خطأ في التقاط الصورة: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _sendMessage() async {
    final cubit = context.read<AdminChatCubit>();

    // Check if Cubit is already sending
    if (cubit.state.isSending) {
      print('⚠️ Cubit is already sending, ignoring call');
      return;
    }

    // Check if message is not empty
    if (_messageController.text.trim().isEmpty && _attachments.isEmpty) {
      print('⚠️ Empty message, ignoring');
      return;
    }

    // Prevent duplicate sends locally
    if (_isSending) {
      print('⚠️ Already sending locally, ignoring duplicate call');
      return;
    }

    setState(() => _isSending = true);

    // Store values before clearing
    final textToSend = _messageController.text.trim();
    final attachmentsToSend = List<AttachmentFile>.from(_attachments);

    print('📤 Starting to send message...');
    print('📤 Text: "$textToSend"');
    print('📤 Attachments count: ${attachmentsToSend.length}');

    // Clear inputs immediately for better UX
    _clearInputs();

    try {
      // Send text message if present
      if (textToSend.isNotEmpty) {
        print('📤 Sending text message...');
        await cubit.sendTextMessage(textToSend);
        print('✅ Text message sent successfully');
      }

      // Send attachments
      for (var i = 0; i < attachmentsToSend.length; i++) {
        final attachment = attachmentsToSend[i];
        print(
            '📤 Sending attachment ${i + 1}/${attachmentsToSend.length}: ${attachment.name}');

        await cubit.sendFileMessage(
          file: File(attachment.path),
          fileName: attachment.name,
          type: _convertAttachmentType(attachment.type),
        );

        print('✅ Attachment ${i + 1} sent successfully');
      }

      print('✅ All messages sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      _showErrorMessage('خطأ في إرسال الرسالة: $e');
    } finally {
      // Always unlock
      if (mounted) {
        setState(() => _isSending = false);
      }
      print('🔓 Send operation completed, isSending reset to false');
    }
  }

  MessageType _convertAttachmentType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return MessageType.image;
      case AttachmentType.file:
        return MessageType.file;
      case AttachmentType.voice:
        return MessageType.voice;
    }
  }

  void _clearInputs() {
    _messageController.clear();
    setState(() {
      _attachments.clear();
    });
    widget.onClearReply?.call();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'إرفاق ملف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'معرض الصور',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'ملفات',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFiles();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminChatCubit, AdminChatState>(
      buildWhen: (previous, current) {
        // Only rebuild when isSending or error changes
        return previous.isSending != current.isSending ||
            previous.error != current.error;
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                if (_attachments.isNotEmpty) _buildAttachmentPreview(),
                _buildInputRow(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: attachment.type == AttachmentType.image
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(attachment.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blue[50],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                attachment.type == AttachmentType.file
                                    ? Icons.description
                                    : Icons.mic,
                                color: Colors.blue,
                                size: 30,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                attachment.name.length > 8
                                    ? '${attachment.name.substring(0, 8)}...'
                                    : attachment.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeAttachment(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow(AdminChatState state) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _attachmentAnimation,
          builder: (context, child) => Transform.scale(
            scale: 0.7 + (_attachmentAnimation.value * 0.3),
            child: IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: _isSending ? null : _showAttachmentOptions,
            ),
          ),
        ),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: !_isSending,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالة...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 6,
              minLines: 1,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _sendButtonAnimation,
          builder: (context, child) => Transform.scale(
            scale: _sendButtonAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (_isSending || state.isSending)
                      ? [Colors.grey, Colors.grey[400]!]
                      : [const Color(0xFFFF5722), const Color(0xFFD32F2F)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ((_isSending || state.isSending)
                            ? Colors.grey
                            : Colors.red)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: (_isSending || state.isSending)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed:
                    (_isSending || state.isSending) ? null : _sendMessage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _attachmentController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}

class AttachmentFile {
  final String path;
  final AttachmentType type;
  final String name;
  final int? size;

  AttachmentFile({
    required this.path,
    required this.type,
    required this.name,
    this.size,
  });
}

enum AttachmentType { image, file, voice }
