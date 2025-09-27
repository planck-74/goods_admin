import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// رفع صورة إلى Firebase Storage
  static Future<String?> uploadNotificationImage(File imageFile) async {
    try {
      final String fileName =
          'notifications/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child(fileName);

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

      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// إرسال إشعار عادي لجميع العملاء
  static Future<Map<String, dynamic>> sendNotificationToAllClients({
    required String title,
    required String body,
    File? image,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String? imageUrl;

      if (image != null) {
        imageUrl = await uploadNotificationImage(image);
        if (imageUrl == null) {
          throw Exception('فشل في رفع الصورة');
        }
      }

      final Map<String, dynamic> data = {
        'title': title.trim(),
        'body': body.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (additionalData != null) 'data': additionalData,
      };

      print('📤 Sending notification with data: $data');

      final HttpsCallable callable = _functions.httpsCallable(
        'sendAdminNotificationToAllClients',
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 2),
        ),
      );

      final HttpsCallableResult result = await callable.call(data);
      final Map<String, dynamic> response =
          Map<String, dynamic>.from(result.data);

      print('✅ Notification sent successfully: $response');
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('❌ Error sending notification: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// إرسال إشعار مع رابط لجميع العملاء
  static Future<Map<String, dynamic>> sendNotificationWithLink({
    required String title,
    required String body,
    String? linkUrl,
    String? linkText,
    File? image,
    NotificationType notificationType = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String? imageUrl;

      // رفع الصورة إذا كانت موجودة
      if (image != null) {
        imageUrl = await uploadNotificationImage(image);
        if (imageUrl == null) {
          throw Exception('فشل في رفع الصورة');
        }
      }

      // التحقق من صحة الرابط
      if (linkUrl != null && linkUrl.isNotEmpty && !_isValidUrl(linkUrl)) {
        throw Exception('صيغة الرابط غير صحيحة');
      }

      final Map<String, dynamic> data = {
        'title': title.trim(),
        'body': body.trim(),
        if (linkUrl != null && linkUrl.isNotEmpty) 'linkUrl': linkUrl.trim(),
        if (linkText != null && linkText.isNotEmpty)
          'linkText': linkText.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'notificationType': notificationType.value,
        'priority': priority.value,
        if (additionalData != null) 'data': additionalData,
      };

      print('📤 Sending notification with link: $data');

      final HttpsCallable callable = _functions.httpsCallable(
        'sendNotificationWithLink',
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 2),
        ),
      );

      final HttpsCallableResult result = await callable.call(data);
      final Map<String, dynamic> response =
          Map<String, dynamic>.from(result.data);

      print('✅ Notification with link sent successfully: $response');
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('❌ Error sending notification with link: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// التحقق من صحة الرابط
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  /// ترجمة رسائل الخطأ
  static String _getErrorMessage(dynamic error) {
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

  /// حذف صورة من Storage
  static Future<void> deleteNotificationImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Image deleted successfully');
    } catch (e) {
      print('❌ Error deleting image: $e');
    }
  }

  /// الحصول على أيقونة نوع الرابط
  static String getLinkTypeIcon(String? url) {
    if (url == null || url.isEmpty) return '🔗';

    final urlLower = url.toLowerCase();

    if (urlLower.contains('play.google.com') ||
        urlLower.contains('market://')) {
      return '📱'; // Play Store
    } else if (urlLower.contains('apps.apple.com') ||
        urlLower.contains('itunes.apple.com')) {
      return '🍎'; // App Store
    } else if (urlLower.contains('youtube.com') ||
        urlLower.contains('youtu.be')) {
      return '📺'; // YouTube
    } else if (urlLower.contains('facebook.com') ||
        urlLower.contains('fb.com')) {
      return '📘'; // Facebook
    } else if (urlLower.contains('instagram.com')) {
      return '📷'; // Instagram
    } else if (urlLower.contains('twitter.com') || urlLower.contains('x.com')) {
      return '🐦'; // Twitter/X
    } else if (urlLower.contains('whatsapp.com') ||
        urlLower.contains('wa.me')) {
      return '💬'; // WhatsApp
    } else if (urlLower.contains('telegram.me') || urlLower.contains('t.me')) {
      return '✈️'; // Telegram
    } else {
      return '🌐'; // Website
    }
  }

  /// الحصول على نص وصفي لنوع الرابط
  static String getLinkTypeText(String? url) {
    if (url == null || url.isEmpty) return 'رابط';

    final urlLower = url.toLowerCase();

    if (urlLower.contains('play.google.com') ||
        urlLower.contains('market://')) {
      return 'متجر جوجل بلاي';
    } else if (urlLower.contains('apps.apple.com') ||
        urlLower.contains('itunes.apple.com')) {
      return 'متجر التطبيقات';
    } else if (urlLower.contains('youtube.com') ||
        urlLower.contains('youtu.be')) {
      return 'يوتيوب';
    } else if (urlLower.contains('facebook.com') ||
        urlLower.contains('fb.com')) {
      return 'فيسبوك';
    } else if (urlLower.contains('instagram.com')) {
      return 'إنستغرام';
    } else if (urlLower.contains('twitter.com') || urlLower.contains('x.com')) {
      return 'تويتر';
    } else if (urlLower.contains('whatsapp.com') ||
        urlLower.contains('wa.me')) {
      return 'واتساب';
    } else if (urlLower.contains('telegram.me') || urlLower.contains('t.me')) {
      return 'تليجرام';
    } else {
      return 'موقع ويب';
    }
  }
}

/// أنواع الإشعارات
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

/// أولوية الإشعارات
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
