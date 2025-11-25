import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/scheduled_notification_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateScheduledNotificationScreen extends StatefulWidget {
  const CreateScheduledNotificationScreen({super.key});

  @override
  State<CreateScheduledNotificationScreen> createState() =>
      _CreateScheduledNotificationScreenState();
}

class _CreateScheduledNotificationScreenState
    extends State<CreateScheduledNotificationScreen>
    with TickerProviderStateMixin {
  // Form & Controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _linkTextController = TextEditingController();

  // Date Formatters
  final _fullDateFormatter = DateFormat('EEE، dd MMM yyyy - hh:mm a', 'ar');
  final _dateOnlyFormatter = DateFormat('EEEE، dd MMMM yyyy', 'ar');

  // State Variables
  File? _selectedImage;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  RecurrenceType _recurrenceType = RecurrenceType.once;
  TargetAudience _targetAudience = TargetAudience.all;
  String _notificationType = 'general';
  String _priority = 'normal';
  bool _includeLinkSection = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Timer for live countdown updates
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeDateTime();
    _setupAnimations();
    _startCountdownTimer();
  }

  void _initializeDateTime() {
    final now = DateTime.now();
    final defaultTime = now.add(const Duration(hours: 1));
    _selectedDate = defaultTime;
    _selectedTime =
        TimeOfDay(hour: defaultTime.hour, minute: defaultTime.minute);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkUrlController.dispose();
    _linkTextController.dispose();
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final currentSelection =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final initialDate =
        currentSelection.isBefore(firstDate) ? firstDate : currentSelection;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  // ==================== Custom Time Picker ====================

  Future<void> _pickTime() async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _CustomTimePickerDialog(
        initialTime: _selectedTime,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedTime = result;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          result.hour,
          result.minute,
        );
      });
    }
  }

  // ==================== Image Picker ====================

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ في اختيار الصورة');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryColor),
              title: const Text('معرض الصور'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryColor),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Schedule Notification ====================

  Future<void> _scheduleNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = _scheduledDateTime;

    if (scheduledDateTime.isBefore(DateTime.now())) {
      _showErrorSnackBar('يجب اختيار وقت في المستقبل');
      return;
    }

    final cubit = context.read<NotificationSchedulerCubit>();
    await cubit.scheduleNotification(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      image: _selectedImage,
      linkUrl: _includeLinkSection ? _linkUrlController.text.trim() : null,
      linkText: _includeLinkSection ? _linkTextController.text.trim() : null,
      scheduledTime: scheduledDateTime,
      recurrence: _recurrenceType.value,
      targetAudience: _targetAudience.value,
      notificationType: _notificationType,
      priority: _priority,
    );

    if (mounted) Navigator.pop(context);
  }

  // ==================== UI Helpers ====================

  DateTime get _scheduledDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Duration get _timeUntil => _scheduledDateTime.difference(DateTime.now());

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'وقت خاطئ';

    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return hours > 0
          ? '${duration.inDays} يوم و $hours ساعة'
          : '${duration.inDays} يوم';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return minutes > 0
          ? '${duration.inHours} ساعة و $minutes دقيقة'
          : '${duration.inHours} ساعة';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} دقيقة';
    } else {
      return 'أقل من دقيقة';
    }
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
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== Build Methods ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        const Row(
          children: [
            Icon(Icons.add_alarm, color: whiteColor, size: 24),
            SizedBox(width: 8),
            Text(
              'جدولة إشعار جديد',
              style: TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScheduleInfoCard(),
                  const SizedBox(height: 24),
                  _buildDateTimePicker(),
                  const SizedBox(height: 20),
                  _buildRecurrenceSelector(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      'محتوى الإشعار', Icons.edit_notifications),
                  const SizedBox(height: 16),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildBodyField(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('الجمهور المستهدف', Icons.people),
                  const SizedBox(height: 16),
                  _buildTargetAudienceSelector(),
                  const SizedBox(height: 24),
                  _buildTypeAndPrioritySection(),
                  const SizedBox(height: 24),
                  _buildLinkToggle(),
                  if (_includeLinkSection) ...[
                    const SizedBox(height: 16),
                    _buildLinkSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildImageSection(),
                  const SizedBox(height: 32),
                  _buildScheduleButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule, size: 48, color: primaryColor),
          const SizedBox(height: 12),
          const Text(
            'جدولة إشعار',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              _fullDateFormatter.format(_scheduledDateTime),
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeUntil.isNegative
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _timeUntil.isNegative
                  ? '⚠️ يرجى اختيار وقت في المستقبل'
                  : '✓ سيتم الإرسال بعد ${_formatDuration(_timeUntil)}',
              style: TextStyle(
                color:
                    _timeUntil.isNegative ? Colors.red[700] : Colors.green[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'وقت الإرسال',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _timeUntil.isNegative
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _timeUntil.isNegative ? Icons.warning : Icons.schedule,
                      size: 14,
                      color: _timeUntil.isNegative ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_timeUntil),
                      style: TextStyle(
                        color:
                            _timeUntil.isNegative ? Colors.red : Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التاريخ',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dateOnlyFormatter.format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit,
                            size: 16, color: primaryColor.withOpacity(0.6)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: primaryColor, size: 20),
                            const Spacer(),
                            Icon(Icons.edit,
                                size: 16, color: primaryColor.withOpacity(0.6)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الوقت',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التكرار',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RecurrenceType.values.map((type) {
            final isSelected = _recurrenceType == type;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == RecurrenceType.once ? Icons.event : Icons.repeat,
                    size: 16,
                    color: isSelected ? Colors.white : primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _recurrenceType = type);
              },
              selectedColor: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : primaryColor,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        if (_recurrenceType != RecurrenceType.once)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إرسال هذا الإشعار ${_recurrenceType.displayName}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      maxLength: 50,
      decoration: InputDecoration(
        labelText: 'عنوان الإشعار',
        hintText: 'أدخل عنوان الإشعار...',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال عنوان الإشعار';
        }
        return null;
      },
    );
  }

  Widget _buildBodyField() {
    return TextFormField(
      controller: _bodyController,
      maxLines: 4,
      maxLength: 200,
      decoration: InputDecoration(
        labelText: 'محتوى الإشعار',
        hintText: 'أدخل محتوى الإشعار...',
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال محتوى الإشعار';
        }
        return null;
      },
    );
  }

  Widget _buildTargetAudienceSelector() {
    return Column(
      children: TargetAudience.values.map((audience) {
        final isSelected = _targetAudience == audience;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<TargetAudience>(
            value: audience,
            groupValue: _targetAudience,
            onChanged: (value) {
              if (value != null) setState(() => _targetAudience = value);
            },
            title: Text(audience.displayName),
            subtitle: Text(
              audience == TargetAudience.all
                  ? 'سيتم إرسال الإشعار لجميع العملاء'
                  : 'سيتم اختيار عملاء محددين',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            activeColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected
                ? primaryColor.withOpacity(0.05)
                : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeAndPrioritySection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _notificationType,
            decoration: InputDecoration(
              labelText: 'نوع الإشعار',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('عام')),
              DropdownMenuItem(value: 'update', child: Text('تحديث')),
              DropdownMenuItem(value: 'promotion', child: Text('عرض')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _notificationType = value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _priority,
            decoration: InputDecoration(
              labelText: 'الأولوية',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'normal', child: Text('عادية')),
              DropdownMenuItem(value: 'high', child: Text('عالية')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLinkToggle() {
    return SwitchListTile(
      value: _includeLinkSection,
      onChanged: (value) => setState(() => _includeLinkSection = value),
      title: const Text('إضافة رابط للإشعار'),
      subtitle: const Text('سيفتح الرابط عند الضغط على الإشعار'),
      activeColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildLinkSection() {
    return Column(
      children: [
        TextFormField(
          controller: _linkUrlController,
          decoration: InputDecoration(
            labelText: 'رابط الإشعار',
            hintText: 'https://example.com',
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
          validator: _includeLinkSection
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رابط الإشعار';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'يرجى إدخال رابط صحيح يبدأ بـ http:// أو https://';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _linkTextController,
          decoration: InputDecoration(
            labelText: 'نص الرابط (اختياري)',
            hintText: 'اضغط للفتح',
            prefixIcon: const Icon(Icons.label),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صورة الإشعار (اختيارية)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          height: _selectedImage != null ? 200 : 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _selectedImage = null),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: primaryColor),
                      SizedBox(height: 8),
                      Text(
                        'اضغط لاختيار صورة',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _scheduleNotification,
        icon: const Icon(Icons.schedule_send, size: 24),
        label: const Text(
          'جدولة الإشعار',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}

// ==================== Custom Time Picker Dialog ====================

class _CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CustomTimePickerDialog({required this.initialTime});

  @override
  State<_CustomTimePickerDialog> createState() =>
      _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isPM;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;
    _isPM = widget.initialTime.period == DayPeriod.pm;
  }

  TimeOfDay get _currentTime {
    int hour24 = _selectedHour == 12 ? 0 : _selectedHour;
    if (_isPM) hour24 += 12;
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.access_time, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'اختيار الوقت',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Time Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour
                  _buildTimeUnit(_selectedHour, 'ساعة', (value) {
                    setState(() => _selectedHour = value);
                  }, 1, 12),

                  const Text(
                    ' : ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  // Minute
                  _buildTimeUnit(_selectedMinute, 'دقيقة', (value) {
                    setState(() => _selectedMinute = value);
                  }, 0, 59),

                  const SizedBox(width: 16),

                  // AM/PM Toggle
                  Column(
                    children: [
                      _buildPeriodButton('PM', _isPM, () {
                        setState(() => _isPM = true);
                      }),
                      const SizedBox(height: 8),
                      _buildPeriodButton('AM', !_isPM, () {
                        setState(() => _isPM = false);
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: primaryColor),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _currentTime),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'حفظ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(
    int value,
    String label,
    Function(int) onChanged,
    int min,
    int max,
  ) {
    return Column(
      children: [
        // Increment Button
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: () {
            int newValue = value + 1;
            if (newValue > max) newValue = min;
            onChanged(newValue);
          },
          color: primaryColor,
          iconSize: 28,
        ),

        // Value Display
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Decrement Button
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            int newValue = value - 1;
            if (newValue < min) newValue = max;
            onChanged(newValue);
          },
          color: primaryColor,
          iconSize: 28,
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }
}
