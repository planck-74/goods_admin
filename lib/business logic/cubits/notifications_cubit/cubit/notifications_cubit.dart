import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/notifications_cubit/cubit/notifications_state.dart';
import 'package:goods_admin/services/notifications_service.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());

  File? _selectedImage;

  // Getters
  File? get selectedImage => _selectedImage;
  bool get hasImage => _selectedImage != null;
  bool get isLoading =>
      state is NotificationLoading ||
      state is NotificationImageUploading ||
      state is NotificationSending;

  /// تحديد صورة للإشعار
  void selectImage(File imageFile) {
    _selectedImage = imageFile;
    emit(NotificationImageSelected(imageFile));
  }

  /// إزالة الصورة المحددة
  void removeImage() {
    _selectedImage = null;
    emit(NotificationImageRemoved());
  }

  /// إرسال إشعار عادي
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      emit(const NotificationError('يرجى إدخال العنوان والمحتوى'));
      return;
    }

    try {
      emit(NotificationSending());

      final result = await NotificationService.sendNotificationToAllClients(
        title: title,
        body: body,
        image: _selectedImage,
        additionalData: additionalData,
      );

      if (result['success'] == true) {
        final Map<String, dynamic> data = result['data'];

        // إعادة تعيين الحالة بعد النجاح
        _selectedImage = null;

        emit(NotificationSuccess(data));

        // العودة للحالة الأولية بعد فترة قصيرة
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) emit(NotificationInitial());
        });
      } else {
        emit(NotificationError(
          result['message'] ?? 'حدث خطأ في إرسال الإشعار',
          technicalError: result['error'],
        ));
      }
    } catch (e) {
      emit(NotificationError(
        'حدث خطأ غير متوقع',
        technicalError: e.toString(),
      ));
    }
  }

  /// إرسال إشعار مع رابط
  Future<void> sendNotificationWithLink({
    required String title,
    required String body,
    String? linkUrl,
    String? linkText,
    NotificationType notificationType = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? additionalData,
  }) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      emit(const NotificationError('يرجى إدخال العنوان والمحتوى'));
      return;
    }

    // التحقق من الرابط إذا كان موجوداً
    if (linkUrl != null && linkUrl.isNotEmpty) {
      if (!_isValidUrl(linkUrl)) {
        emit(const NotificationError('يرجى إدخال رابط صحيح'));
        return;
      }
    }

    try {
      emit(NotificationSending());

      final result = await NotificationService.sendNotificationWithLink(
        title: title,
        body: body,
        linkUrl: linkUrl,
        linkText: linkText,
        image: _selectedImage,
        notificationType: notificationType,
        priority: priority,
        additionalData: additionalData,
      );

      if (result['success'] == true) {
        final Map<String, dynamic> data = result['data'];

        // إعادة تعيين الحالة بعد النجاح
        _selectedImage = null;

        emit(NotificationSuccess(data));

        // العودة للحالة الأولية بعد فترة قصيرة
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) emit(NotificationInitial());
        });
      } else {
        emit(NotificationError(
          result['message'] ?? 'حدث خطأ في إرسال الإشعار',
          technicalError: result['error'],
        ));
      }
    } catch (e) {
      emit(NotificationError(
        'حدث خطأ غير متوقع',
        technicalError: e.toString(),
      ));
    }
  }

  /// التحقق من صحة الرابط
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  /// إعادة تعيين الحالة
  void reset() {
    _selectedImage = null;
    emit(NotificationInitial());
  }

  /// التحقق من صحة البيانات
  bool validateInput(String title, String body) {
    return title.trim().isNotEmpty && body.trim().isNotEmpty;
  }

  /// الحصول على معلومات الحالة الحالية
  String getStateMessage() {
    if (state is NotificationLoading) {
      return 'جاري التحضير...';
    } else if (state is NotificationImageUploading) {
      return 'جاري رفع الصورة...';
    } else if (state is NotificationSending) {
      return 'جاري إرسال الإشعار...';
    } else if (state is NotificationSuccess) {
      final result = (state as NotificationSuccess).result;
      return 'تم الإرسال بنجاح إلى ${result['sent']} جهاز';
    } else if (state is NotificationError) {
      return (state as NotificationError).message;
    }
    return '';
  }
}
