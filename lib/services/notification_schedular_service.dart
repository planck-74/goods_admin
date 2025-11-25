import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NotificationSchedulerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _scheduledNotificationsCollection =
      'scheduled_notifications';

  /// Schedule a new notification
  static Future<Map<String, dynamic>> scheduleNotification({
    required String title,
    required String body,
    File? image,
    String? linkUrl,
    String? linkText,
    required DateTime scheduledTime,
    required String recurrence,
    required String targetAudience,
    List<String>? targetClientIds,
    required String notificationType,
    required String priority,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (image != null) {
        imageUrl = await _uploadScheduledNotificationImage(image);
        if (imageUrl == null) {
          throw Exception('فشل في رفع الصورة');
        }
      }

      // Validate scheduled time
      if (scheduledTime.isBefore(DateTime.now())) {
        throw Exception('الوقت المحدد يجب أن يكون في المستقبل');
      }

      // Create document
      final docRef =
          await _firestore.collection(_scheduledNotificationsCollection).add({
        'title': title.trim(),
        'body': body.trim(),
        'imageUrl': imageUrl,
        'linkUrl': linkUrl?.trim(),
        'linkText': linkText?.trim(),
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'recurrence': recurrence,
        'status': 'pending',
        'targetAudience': targetAudience,
        'targetClientIds': targetClientIds,
        'notificationType': notificationType,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
        'sentCount': 0,
        'additionalData': additionalData,
      });

      print('✅ Notification scheduled successfully: ${docRef.id}');
      return {
        'success': true,
        'id': docRef.id,
        'message': 'تم جدولة الإشعار بنجاح',
      };
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Get all scheduled notifications
  static Stream<List<Map<String, dynamic>>> getScheduledNotifications({
    String? statusFilter,
    int? limit,
  }) {
    Query query = _firestore
        .collection(_scheduledNotificationsCollection)
        .orderBy('scheduledTime', descending: false);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Get scheduled notification by ID
  static Future<Map<String, dynamic>?> getScheduledNotificationById(
      String id) async {
    try {
      final doc = await _firestore
          .collection(_scheduledNotificationsCollection)
          .doc(id)
          .get();

      if (!doc.exists) return null;

      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    } catch (e) {
      print('❌ Error fetching scheduled notification: $e');
      return null;
    }
  }

  /// Update scheduled notification
  static Future<Map<String, dynamic>> updateScheduledNotification({
    required String id,
    String? title,
    String? body,
    File? newImage,
    String? linkUrl,
    String? linkText,
    DateTime? scheduledTime,
    String? recurrence,
    String? notificationType,
    String? priority,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title.trim();
      if (body != null) updateData['body'] = body.trim();
      if (linkUrl != null) updateData['linkUrl'] = linkUrl.trim();
      if (linkText != null) updateData['linkText'] = linkText.trim();
      if (scheduledTime != null) {
        if (scheduledTime.isBefore(DateTime.now())) {
          throw Exception('الوقت المحدد يجب أن يكون في المستقبل');
        }
        updateData['scheduledTime'] = Timestamp.fromDate(scheduledTime);
      }
      if (recurrence != null) updateData['recurrence'] = recurrence;
      if (notificationType != null)
        updateData['notificationType'] = notificationType;
      if (priority != null) updateData['priority'] = priority;

      // Upload new image if provided
      if (newImage != null) {
        final imageUrl = await _uploadScheduledNotificationImage(newImage);
        if (imageUrl != null) {
          updateData['imageUrl'] = imageUrl;
        }
      }

      await _firestore
          .collection(_scheduledNotificationsCollection)
          .doc(id)
          .update(updateData);

      print('✅ Notification updated successfully: $id');
      return {
        'success': true,
        'message': 'تم تحديث الإشعار بنجاح',
      };
    } catch (e) {
      print('❌ Error updating notification: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Cancel scheduled notification
  static Future<Map<String, dynamic>> cancelScheduledNotification(
      String id) async {
    try {
      await _firestore
          .collection(_scheduledNotificationsCollection)
          .doc(id)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification cancelled successfully: $id');
      return {
        'success': true,
        'message': 'تم إلغاء الإشعار بنجاح',
      };
    } catch (e) {
      print('❌ Error cancelling notification: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Delete scheduled notification
  static Future<Map<String, dynamic>> deleteScheduledNotification(
      String id) async {
    try {
      // Get notification data first to delete image if exists
      final doc = await _firestore
          .collection(_scheduledNotificationsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data?['imageUrl'] != null) {
          await _deleteNotificationImage(data!['imageUrl']);
        }
      }

      await _firestore
          .collection(_scheduledNotificationsCollection)
          .doc(id)
          .delete();

      print('✅ Notification deleted successfully: $id');
      return {
        'success': true,
        'message': 'تم حذف الإشعار بنجاح',
      };
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Send scheduled notification immediately
  static Future<Map<String, dynamic>> sendNow(String id) async {
    try {
      final doc = await _firestore
          .collection(_scheduledNotificationsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw Exception('الإشعار غير موجود');
      }

      final data = doc.data()!;

      // Call cloud function to send notification
      final HttpsCallable callable = _functions.httpsCallable(
        'sendScheduledNotificationNow',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
      );

      final result = await callable.call({'notificationId': id});
      final response = Map<String, dynamic>.from(result.data);

      print('✅ Notification sent immediately: $id');
      return {
        'success': true,
        'data': response,
        'message': 'تم إرسال الإشعار بنجاح',
      };
    } catch (e) {
      print('❌ Error sending notification immediately: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getErrorMessage(e),
      };
    }
  }

  /// Get statistics
  static Future<Map<String, int>> getScheduleStatistics() async {
    try {
      final snapshot =
          await _firestore.collection(_scheduledNotificationsCollection).get();

      int pending = 0;
      int sent = 0;
      int failed = 0;
      int cancelled = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'sent':
            sent++;
            break;
          case 'failed':
            failed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return {
        'total': snapshot.docs.length,
        'pending': pending,
        'sent': sent,
        'failed': failed,
        'cancelled': cancelled,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'sent': 0,
        'failed': 0,
        'cancelled': 0,
      };
    }
  }

  /// Upload image helper
  static Future<String?> _uploadScheduledNotificationImage(
      File imageFile) async {
    try {
      final String fileName =
          'notifications/scheduled/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'type': 'scheduled_notification',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('❌ Error uploading scheduled notification image: $e');
      return null;
    }
  }

  /// Delete image helper
  static Future<void> _deleteNotificationImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Image deleted successfully');
    } catch (e) {
      print('❌ Error deleting image: $e');
    }
  }

  /// Error message helper
  static String _getErrorMessage(dynamic error) {
    final String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('unauthenticated')) {
      return 'يجب تسجيل الدخول أولاً';
    } else if (errorStr.contains('invalid-argument')) {
      return 'البيانات المدخلة غير صحيحة';
    } else if (errorStr.contains('not-found')) {
      return 'الإشعار غير موجود';
    } else if (errorStr.contains('network')) {
      return 'تحقق من الاتصال بالإنترنت';
    } else if (errorStr.contains('timeout')) {
      return 'انتهت مهلة العملية، حاول مرة أخرى';
    }

    return 'حدث خطأ غير متوقع';
  }
}
