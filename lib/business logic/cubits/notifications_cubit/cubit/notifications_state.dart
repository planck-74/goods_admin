// Service import
// import 'notification_service.dart'; // تأكد من استيراد الـ service

// States
import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationImageUploading extends NotificationState {}

class NotificationSending extends NotificationState {}

class NotificationSuccess extends NotificationState {
  final Map<String, dynamic> result;

  const NotificationSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class NotificationError extends NotificationState {
  final String message;
  final String? technicalError;

  const NotificationError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class NotificationImageSelected extends NotificationState {
  final File imageFile;

  const NotificationImageSelected(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class NotificationImageRemoved extends NotificationState {}

// Events (for better organization)
abstract class NotificationEvent {}

class SendNotificationEvent extends NotificationEvent {
  final String title;
  final String body;
  final File? image;
  final Map<String, dynamic>? additionalData;

  SendNotificationEvent({
    required this.title,
    required this.body,
    this.image,
    this.additionalData,
  });
}

class SelectImageEvent extends NotificationEvent {
  final File imageFile;

  SelectImageEvent(this.imageFile);
}

class RemoveImageEvent extends NotificationEvent {}

// Cubit
