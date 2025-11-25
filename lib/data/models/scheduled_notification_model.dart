import 'package:cloud_firestore/cloud_firestore.dart';

enum ScheduleStatus {
  pending('pending'),
  sent('sent'),
  failed('failed'),
  cancelled('cancelled');

  const ScheduleStatus(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case ScheduleStatus.pending:
        return 'قيد الانتظار';
      case ScheduleStatus.sent:
        return 'تم الإرسال';
      case ScheduleStatus.failed:
        return 'فشل';
      case ScheduleStatus.cancelled:
        return 'ملغي';
    }
  }

  static ScheduleStatus fromString(String value) {
    return ScheduleStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScheduleStatus.pending,
    );
  }
}

enum RecurrenceType {
  once('once'),
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const RecurrenceType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case RecurrenceType.once:
        return 'مرة واحدة';
      case RecurrenceType.daily:
        return 'يومياً';
      case RecurrenceType.weekly:
        return 'أسبوعياً';
      case RecurrenceType.monthly:
        return 'شهرياً';
    }
  }

  static RecurrenceType fromString(String value) {
    return RecurrenceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecurrenceType.once,
    );
  }
}

enum TargetAudience {
  all('all'),
  selected('selected');

  const TargetAudience(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case TargetAudience.all:
        return 'جميع العملاء';
      case TargetAudience.selected:
        return 'عملاء محددين';
    }
  }

  static TargetAudience fromString(String value) {
    return TargetAudience.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TargetAudience.all,
    );
  }
}

class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkText;
  final DateTime scheduledTime;
  final RecurrenceType recurrence;
  final ScheduleStatus status;
  final TargetAudience targetAudience;
  final List<String>? targetClientIds;
  final String notificationType;
  final String priority;
  final DateTime createdAt;
  final DateTime? lastSentAt;
  final int sentCount;
  final String? errorMessage;
  final Map<String, dynamic>? additionalData;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.linkUrl,
    this.linkText,
    required this.scheduledTime,
    this.recurrence = RecurrenceType.once,
    this.status = ScheduleStatus.pending,
    this.targetAudience = TargetAudience.all,
    this.targetClientIds,
    required this.notificationType,
    required this.priority,
    required this.createdAt,
    this.lastSentAt,
    this.sentCount = 0,
    this.errorMessage,
    this.additionalData,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'linkText': linkText,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'recurrence': recurrence.value,
      'status': status.value,
      'targetAudience': targetAudience.value,
      'targetClientIds': targetClientIds,
      'notificationType': notificationType,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSentAt': lastSentAt != null ? Timestamp.fromDate(lastSentAt!) : null,
      'sentCount': sentCount,
      'errorMessage': errorMessage,
      'additionalData': additionalData,
    };
  }

  factory ScheduledNotification.fromMap(String id, Map<String, dynamic> map) {
    Timestamp? createdAtTs =
        map['createdAt'] is Timestamp ? map['createdAt'] : null;
    Timestamp? scheduledTs =
        map['scheduledTime'] is Timestamp ? map['scheduledTime'] : null;
    Timestamp? lastSentTs =
        map['lastSentAt'] is Timestamp ? map['lastSentAt'] : null;

    return ScheduledNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'],
      linkUrl: map['linkUrl'],
      linkText: map['linkText'],

      // safer scheduledTime
      scheduledTime: scheduledTs?.toDate() ?? DateTime.now(),

      recurrence: RecurrenceType.fromString(map['recurrence'] ?? 'once'),
      status: ScheduleStatus.fromString(map['status'] ?? 'pending'),
      targetAudience: TargetAudience.fromString(map['targetAudience'] ?? 'all'),

      targetClientIds: map['targetClientIds'] != null
          ? List<String>.from(map['targetClientIds'])
          : null,

      notificationType: map['notificationType'] ?? 'general',
      priority: map['priority'] ?? 'normal',

      // safer createdAt
      createdAt: createdAtTs?.toDate() ?? DateTime.now(),

      // safer lastSentAt
      lastSentAt: lastSentTs?.toDate(),

      sentCount: map['sentCount'] ?? 0,
      errorMessage: map['errorMessage'],
      additionalData: map['additionalData'],
    );
  }

  // Copy with method
  ScheduledNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? linkUrl,
    String? linkText,
    DateTime? scheduledTime,
    RecurrenceType? recurrence,
    ScheduleStatus? status,
    TargetAudience? targetAudience,
    List<String>? targetClientIds,
    String? notificationType,
    String? priority,
    DateTime? createdAt,
    DateTime? lastSentAt,
    int? sentCount,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      linkText: linkText ?? this.linkText,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrence: recurrence ?? this.recurrence,
      status: status ?? this.status,
      targetAudience: targetAudience ?? this.targetAudience,
      targetClientIds: targetClientIds ?? this.targetClientIds,
      notificationType: notificationType ?? this.notificationType,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      sentCount: sentCount ?? this.sentCount,
      errorMessage: errorMessage ?? this.errorMessage,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper methods
  bool get isPending => status == ScheduleStatus.pending;
  bool get isSent => status == ScheduleStatus.sent;
  bool get isFailed => status == ScheduleStatus.failed;
  bool get isCancelled => status == ScheduleStatus.cancelled;
  bool get isRecurring => recurrence != RecurrenceType.once;
  bool get isOverdue => DateTime.now().isAfter(scheduledTime) && isPending;
  bool get canBeCancelled => isPending;
  bool get canBeRescheduled => isPending || isFailed;

  Duration get timeUntilScheduled => scheduledTime.difference(DateTime.now());

  String get formattedScheduleTime {
    final now = DateTime.now();
    final diff = scheduledTime.difference(now);

    if (diff.isNegative) {
      return 'منذ ${_formatDuration(diff.abs())}';
    } else {
      return 'بعد ${_formatDuration(diff)}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} يوم';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ساعة';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} دقيقة';
    } else {
      return 'أقل من دقيقة';
    }
  }

  DateTime? get nextScheduledTime {
    if (!isRecurring || !isSent) return null;

    switch (recurrence) {
      case RecurrenceType.daily:
        return scheduledTime.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return scheduledTime.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(
          scheduledTime.year,
          scheduledTime.month + 1,
          scheduledTime.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
      case RecurrenceType.once:
        return null;
    }
  }
}
