import 'dart:io';
import 'package:flutter/material.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum NotificationType {
  general('general'),
  update('update'),
  promotion('promotion'),
  news('news'),
  social('social');

  const NotificationType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'عام';
      case NotificationType.update:
        return 'تحديث التطبيق';
      case NotificationType.promotion:
        return 'عروض وخصومات';
      case NotificationType.news:
        return 'أخبار';
      case NotificationType.social:
        return 'وسائل التواصل';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.general:
        return '📢';
      case NotificationType.update:
        return '🔄';
      case NotificationType.promotion:
        return '🎯';
      case NotificationType.news:
        return '📰';
      case NotificationType.social:
        return '🌐';
    }
  }
}

enum NotificationPriority {
  normal('normal'),
  high('high');

  const NotificationPriority(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationPriority.normal:
        return 'عادية';
      case NotificationPriority.high:
        return 'عالية';
    }
  }
}

class SendToAll extends StatefulWidget {
  const SendToAll({super.key});

  @override
  State<SendToAll> createState() => _SendToAllState();
}

class _SendToAllState extends State<SendToAll> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();
  final TextEditingController _linkTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _includeLinkSection = false;

  NotificationType _selectedType = NotificationType.general;
  NotificationPriority _selectedPriority = NotificationPriority.normal;

  late AnimationController _animationController;
  late AnimationController _linkSectionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _linkSectionAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد الرسوم المتحركة
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _linkSectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _linkSectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _linkSectionController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkUrlController.dispose();
    _linkTextController.dispose();
    _animationController.dispose();
    _linkSectionController.dispose();
    super.dispose();
  }

  void _toggleLinkSection(bool value) {
    setState(() {
      _includeLinkSection = value;
    });

    if (value) {
      _linkSectionController.forward();
    } else {
      _linkSectionController.reverse();
      _linkUrlController.clear();
      _linkTextController.clear();
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار الصورة: ${e.toString()}');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اختيار مصدر الصورة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageSourceOption(
              icon: Icons.photo_library,
              title: 'معرض الصور',
              source: ImageSource.gallery,
            ),
            const SizedBox(height: 8),
            _buildImageSourceOption(
              icon: Icons.camera_alt,
              title: 'الكاميرا',
              source: ImageSource.camera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required ImageSource source,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title),
        onTap: () => Navigator.pop(context, source),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      setState(() => _isUploading = true);

      final String fileName =
          'notifications/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'type': 'admin_notification',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // رفع الصورة إذا كانت موجودة
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          _showErrorSnackBar('فشل في رفع الصورة');
          return;
        }
      }

      // إعداد البيانات للإرسال
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'notificationType': _selectedType.value,
        'priority': _selectedPriority.value,
        'data': {
          'source': 'admin_app',
          'category': _selectedType.value,
        },
      };

      // إضافة بيانات الرابط إذا كان مفعلاً
      if (_includeLinkSection && _linkUrlController.text.trim().isNotEmpty) {
        data['linkUrl'] = _linkUrlController.text.trim();
        if (_linkTextController.text.trim().isNotEmpty) {
          data['linkText'] = _linkTextController.text.trim();
        }
      }

      // اختيار الدالة المناسبة
      final String functionName =
          _includeLinkSection && _linkUrlController.text.trim().isNotEmpty
              ? 'sendNotificationWithLink'
              : 'sendAdminNotificationToAllClients';

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        functionName,
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 2),
        ),
      );

      final HttpsCallableResult result = await callable.call(data);
      final Map<String, dynamic> response =
          Map<String, dynamic>.from(result.data);

      // مسح النموذج بعد النجاح
      _titleController.clear();
      _bodyController.clear();
      _linkUrlController.clear();
      _linkTextController.clear();
      _selectedImage = null;
      _includeLinkSection = false;
      _linkSectionController.reset();

      _showSuccessSnackBar(
        'تم إرسال الإشعار بنجاح إلى ${response['sent']} جهاز من أصل ${response['totalTokens']}',
      );
    } catch (e) {
      _showErrorSnackBar(_getErrorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('unauthenticated')) {
      return 'يجب تسجيل الدخول أولاً';
    } else if (errorStr.contains('invalid-argument')) {
      return 'البيانات المدخلة غير صحيحة';
    } else if (errorStr.contains('not-found')) {
      return 'لا توجد عملاء لإرسال الإشعار إليهم';
    } else if (errorStr.contains('network')) {
      return 'تحقق من الاتصال بالإنترنت';
    } else if (errorStr.contains('timeout')) {
      return 'انتهت مهلة الإرسال، حاول مرة أخرى';
    }

    return 'حدث خطأ في إرسال الإشعار';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getLinkTypeIcon(String url) {
    final urlLower = url.toLowerCase();

    if (urlLower.contains('play.google.com') ||
        urlLower.contains('market://')) {
      return '📱';
    } else if (urlLower.contains('apps.apple.com') ||
        urlLower.contains('itunes.apple.com')) {
      return '🍎';
    } else if (urlLower.contains('youtube.com') ||
        urlLower.contains('youtu.be')) {
      return '📺';
    } else if (urlLower.contains('facebook.com') ||
        urlLower.contains('fb.com')) {
      return '📘';
    } else if (urlLower.contains('instagram.com')) {
      return '📷';
    } else if (urlLower.contains('whatsapp.com') ||
        urlLower.contains('wa.me')) {
      return '💬';
    } else {
      return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            Icon(
              _selectedType == NotificationType.general
                  ? Icons.notifications_active
                  : _selectedType == NotificationType.update
                      ? Icons.system_update
                      : Icons.campaign,
              color: whiteColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'إرسال إشعار للجميع',
              style: TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBody(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Notification Type & Priority
            _buildTypeAndPrioritySection(),
            const SizedBox(height: 20),

            // Title Field
            _buildTitleField(),
            const SizedBox(height: 20),

            // Body Field
            _buildBodyField(),
            const SizedBox(height: 24),

            // Link Section Toggle
            _buildLinkToggle(),
            const SizedBox(height: 16),

            // Link Section (Animated)
            AnimatedBuilder(
              animation: _linkSectionAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _linkSectionAnimation,
                  child: FadeTransition(
                    opacity: _linkSectionAnimation,
                    child: _buildLinkSection(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Image Section
            _buildImageSection(),
            const SizedBox(height: 32),

            // Send Button
            _buildSendButton(),

            // Loading Indicator
            if (_isLoading || _isUploading) ...[
              const SizedBox(height: 20),
              _buildLoadingIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            _selectedType.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'إرسال إعلان لجميع العملاء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إرسال الإشعار لجميع العملاء المسجلين في التطبيق',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndPrioritySection() {
    return Row(
      children: [
        // Notification Type
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نوع الإشعار',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<NotificationType>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Text(type.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Priority
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الأولوية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<NotificationPriority>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: NotificationPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          priority == NotificationPriority.high
                              ? Icons.priority_high
                              : Icons.low_priority,
                          color: priority == NotificationPriority.high
                              ? Colors.red
                              : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(priority.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.title, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'عنوان الإشعار',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'أدخل عنوان الإشعار...',
            prefixIcon:
                Icon(Icons.text_fields, color: primaryColor.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            counterStyle: TextStyle(color: Colors.grey[600]),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال عنوان الإشعار';
            }
            if (value.trim().length < 3) {
              return 'العنوان قصير جداً';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBodyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'محتوى الإشعار',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bodyController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'أدخل محتوى الإشعار الذي تريد إرساله...',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Icon(Icons.message, color: primaryColor.withOpacity(0.7)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            counterStyle: TextStyle(color: Colors.grey[600]),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال محتوى الإشعار';
            }
            if (value.trim().length < 10) {
              return 'المحتوى قصير جداً';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLinkToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إضافة رابط للإشعار',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سيتم فتح الرابط عند الضغط على الإشعار',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _includeLinkSection,
            onChanged: _toggleLinkSection,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection() {
    if (!_includeLinkSection) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Link URL Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'رابط الإشعار',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                if (_linkUrlController.text.isNotEmpty)
                  Text(
                    _getLinkTypeIcon(_linkUrlController.text),
                    style: const TextStyle(fontSize: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _linkUrlController,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                prefixIcon:
                    Icon(Icons.language, color: primaryColor.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (_includeLinkSection &&
                    (value == null || value.trim().isEmpty)) {
                  return 'يرجى إدخال الرابط';
                }
                if (value != null &&
                    value.trim().isNotEmpty &&
                    !_isValidUrl(value.trim())) {
                  return 'يرجى إدخال رابط صحيح';
                }
                return null;
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Link Text Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'نص الرابط (اختياري)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _linkTextController,
              decoration: InputDecoration(
                hintText: 'مثال: اضغط للتحديث، زيارة الموقع، المزيد...',
                prefixIcon:
                    Icon(Icons.label, color: primaryColor.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Link Preview
        if (_linkUrlController.text.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Text(
                  _getLinkTypeIcon(_linkUrlController.text),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة الرابط:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _linkUrlController.text.trim(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'صورة الإشعار (اختيارية)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'يمكنك إضافة صورة لجعل الإشعار أكثر جاذبية',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _selectedImage != null ? 200 : 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _selectedImage != null
                ? Colors.transparent
                : Colors.grey.shade50,
            border: Border.all(
              color: _selectedImage != null
                  ? primaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
              width: _selectedImage != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _selectedImage != null
              ? _buildImagePreview()
              : _buildImagePicker(),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: _removeImage,
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'اضغط لتغيير الصورة',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickImage,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickImage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                size: 32,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'اضغط لاختيار صورة',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG - حجم أقصى 5 ميجا',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final bool isDisabled = _isLoading || _isUploading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isDisabled
            ? LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade300],
              )
            : LinearGradient(
                colors: [
                  primaryColor,
                  _selectedPriority == NotificationPriority.high
                      ? const Color.fromARGB(255, 180, 0, 0)
                      : const Color.fromARGB(255, 138, 12, 12)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isDisabled ? null : _sendNotification,
          child: Center(
            child: isDisabled
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isUploading ? 'جاري رفع الصورة...' : 'جاري الإرسال...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _includeLinkSection &&
                                _linkUrlController.text.trim().isNotEmpty
                            ? Icons.link
                            : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _includeLinkSection &&
                                _linkUrlController.text.trim().isNotEmpty
                            ? 'إرسال الإشعار مع الرابط'
                            : 'إرسال الإشعار',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedPriority == NotificationPriority.high
            ? Colors.orange.shade50
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPriority == NotificationPriority.high
              ? Colors.orange.shade200
              : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _selectedPriority == NotificationPriority.high
                    ? Colors.orange
                    : primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isUploading
                      ? 'جاري رفع الصورة...'
                      : _includeLinkSection &&
                              _linkUrlController.text.trim().isNotEmpty
                          ? 'جاري إرسال الإشعار مع الرابط...'
                          : 'جاري إرسال الإشعار...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _selectedPriority == NotificationPriority.high
                        ? Colors.orange
                        : primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'يرجى الانتظار - ${_selectedType.displayName} | ${_selectedPriority.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_selectedPriority == NotificationPriority.high) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.priority_high,
                        size: 14,
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
