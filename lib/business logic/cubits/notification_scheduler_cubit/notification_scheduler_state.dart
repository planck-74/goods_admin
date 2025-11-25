import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/data/models/scheduled_notification_model.dart';

// States
abstract class NotificationSchedulerState {}

class SchedulerInitial extends NotificationSchedulerState {}

class SchedulerLoading extends NotificationSchedulerState {}

class SchedulerLoaded extends NotificationSchedulerState {
  final List<ScheduledNotification> notifications;
  final Map<String, int> statistics;
  final String? filterStatus;

  SchedulerLoaded({
    required this.notifications,
    required this.statistics,
    this.filterStatus,
  });
}

class SchedulerError extends NotificationSchedulerState {
  final String message;
  SchedulerError(this.message);
}

class SchedulerActionInProgress extends NotificationSchedulerState {
  final String message;
  SchedulerActionInProgress(this.message);
}

class SchedulerActionSuccess extends NotificationSchedulerState {
  final String message;
  SchedulerActionSuccess(this.message);
}
