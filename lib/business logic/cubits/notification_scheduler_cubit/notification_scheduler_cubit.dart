import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_state.dart';
import 'package:goods_admin/data/models/scheduled_notification_model.dart';
import 'package:goods_admin/services/notification_schedular_service.dart';

// Cubit
class NotificationSchedulerCubit extends Cubit<NotificationSchedulerState> {
  NotificationSchedulerCubit() : super(SchedulerInitial());

  String? _currentStatusFilter;

  /// Load scheduled notifications
  Future<void> loadScheduledNotifications({String? statusFilter}) async {
    try {
      emit(SchedulerLoading());
      _currentStatusFilter = statusFilter;

      // Get statistics
      final stats = await NotificationSchedulerService.getScheduleStatistics();

      // Start listening to notifications stream
      NotificationSchedulerService.getScheduledNotifications(
        statusFilter: statusFilter,
      ).listen(
        (notificationsList) {
          final notifications = notificationsList.map((data) {
            return ScheduledNotification.fromMap(data['id'], data);
          }).toList();

          // Sort by scheduled time
          notifications.sort((a, b) {
            if (a.isPending && !b.isPending) return -1;
            if (!a.isPending && b.isPending) return 1;
            return a.scheduledTime.compareTo(b.scheduledTime);
          });

          emit(SchedulerLoaded(
            notifications: notifications,
            statistics: stats,
            filterStatus: statusFilter,
          ));
        },
        onError: (error) {
          emit(SchedulerError(
              'حدث خطأ في تحميل الإشعارات: ${error.toString()}'));
        },
      );
    } catch (e) {
      emit(SchedulerError('حدث خطأ في تحميل الإشعارات: ${e.toString()}'));
    }
  }

  /// Schedule a new notification
  Future<void> scheduleNotification({
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
      emit(SchedulerActionInProgress('جاري جدولة الإشعار...'));

      final result = await NotificationSchedulerService.scheduleNotification(
        title: title,
        body: body,
        image: image,
        linkUrl: linkUrl,
        linkText: linkText,
        scheduledTime: scheduledTime,
        recurrence: recurrence,
        targetAudience: targetAudience,
        targetClientIds: targetClientIds,
        notificationType: notificationType,
        priority: priority,
        additionalData: additionalData,
      );

      if (result['success'] == true) {
        emit(SchedulerActionSuccess(result['message']));
        // Reload notifications
        await loadScheduledNotifications(statusFilter: _currentStatusFilter);
      } else {
        emit(SchedulerError(result['message']));
      }
    } catch (e) {
      emit(SchedulerError('حدث خطأ في جدولة الإشعار: ${e.toString()}'));
    }
  }

  /// Update scheduled notification
  Future<void> updateScheduledNotification({
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
      emit(SchedulerActionInProgress('جاري تحديث الإشعار...'));

      final result =
          await NotificationSchedulerService.updateScheduledNotification(
        id: id,
        title: title,
        body: body,
        newImage: newImage,
        linkUrl: linkUrl,
        linkText: linkText,
        scheduledTime: scheduledTime,
        recurrence: recurrence,
        notificationType: notificationType,
        priority: priority,
      );

      if (result['success'] == true) {
        emit(SchedulerActionSuccess(result['message']));
        await loadScheduledNotifications(statusFilter: _currentStatusFilter);
      } else {
        emit(SchedulerError(result['message']));
      }
    } catch (e) {
      emit(SchedulerError('حدث خطأ في تحديث الإشعار: ${e.toString()}'));
    }
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(String id) async {
    try {
      emit(SchedulerActionInProgress('جاري إلغاء الإشعار...'));

      final result =
          await NotificationSchedulerService.cancelScheduledNotification(id);

      if (result['success'] == true) {
        emit(SchedulerActionSuccess(result['message']));
        await loadScheduledNotifications(statusFilter: _currentStatusFilter);
      } else {
        emit(SchedulerError(result['message']));
      }
    } catch (e) {
      emit(SchedulerError('حدث خطأ في إلغاء الإشعار: ${e.toString()}'));
    }
  }

  /// Delete scheduled notification
  Future<void> deleteScheduledNotification(String id) async {
    try {
      emit(SchedulerActionInProgress('جاري حذف الإشعار...'));

      final result =
          await NotificationSchedulerService.deleteScheduledNotification(id);

      if (result['success'] == true) {
        emit(SchedulerActionSuccess(result['message']));
        await loadScheduledNotifications(statusFilter: _currentStatusFilter);
      } else {
        emit(SchedulerError(result['message']));
      }
    } catch (e) {
      emit(SchedulerError('حدث خطأ في حذف الإشعار: ${e.toString()}'));
    }
  }

  /// Send scheduled notification immediately
  Future<void> sendNow(String id) async {
    try {
      emit(SchedulerActionInProgress('جاري إرسال الإشعار...'));

      final result = await NotificationSchedulerService.sendNow(id);

      if (result['success'] == true) {
        emit(SchedulerActionSuccess('تم إرسال الإشعار بنجاح'));
        await loadScheduledNotifications(statusFilter: _currentStatusFilter);
      } else {
        emit(SchedulerError(result['message']));
      }
    } catch (e) {
      emit(SchedulerError('حدث خطأ في إرسال الإشعار: ${e.toString()}'));
    }
  }

  /// Apply status filter
  Future<void> applyStatusFilter(String? status) async {
    _currentStatusFilter = status;
    await loadScheduledNotifications(statusFilter: status);
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadScheduledNotifications(statusFilter: _currentStatusFilter);
  }

  /// Get upcoming notifications count
  int getUpcomingCount(List<ScheduledNotification> notifications) {
    return notifications.where((n) => n.isPending && !n.isOverdue).length;
  }

  /// Get overdue notifications count
  int getOverdueCount(List<ScheduledNotification> notifications) {
    return notifications.where((n) => n.isOverdue).length;
  }

  /// Get today's notifications
  List<ScheduledNotification> getTodayNotifications(
      List<ScheduledNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return notifications.where((n) {
      return n.scheduledTime.isAfter(today) &&
          n.scheduledTime.isBefore(tomorrow);
    }).toList();
  }

  /// Get this week's notifications
  List<ScheduledNotification> getWeekNotifications(
      List<ScheduledNotification> notifications) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return notifications.where((n) {
      return n.scheduledTime.isAfter(weekStart) &&
          n.scheduledTime.isBefore(weekEnd);
    }).toList();
  }
}
