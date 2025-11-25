import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/scheduled_notification_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:intl/intl.dart';

class NotificationSchedulerScreen extends StatefulWidget {
  const NotificationSchedulerScreen({super.key});

  @override
  State<NotificationSchedulerScreen> createState() =>
      _NotificationSchedulerScreenState();
}

class _NotificationSchedulerScreenState
    extends State<NotificationSchedulerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load scheduled notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationSchedulerCubit>().loadScheduledNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationSchedulerCubit, NotificationSchedulerState>(
      listener: (context, state) {
        if (state is SchedulerActionSuccess) {
          _showSuccessSnackBar(state.message);
        } else if (state is SchedulerError) {
          _showErrorSnackBar(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: customAppBar(
            context,
            Row(
              children: [
                const Icon(Icons.schedule, color: whiteColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'جدولة الإشعارات',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: whiteColor),
                  onPressed: () {
                    context.read<NotificationSchedulerCubit>().refresh();
                  },
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Statistics Cards
              if (state is SchedulerLoaded) _buildStatisticsCards(state),

              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 20),
                          SizedBox(width: 8),
                          Text('القادمة'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('المرسلة'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 20),
                          SizedBox(width: 8),
                          Text('الكل'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationsList(state, ScheduleStatus.pending),
                    _buildNotificationsList(state, ScheduleStatus.sent),
                    _buildNotificationsList(state, null),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/CreateScheduledNotification');
            },
            backgroundColor: primaryColor,
            icon: const Icon(Icons.add_alarm, color: whiteColor),
            label: const Text(
              'جدولة جديدة',
              style: TextStyle(color: whiteColor, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards(SchedulerLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'قيد الانتظار',
              count: state.statistics['pending'] ?? 0,
              icon: Icons.schedule,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'تم الإرسال',
              count: state.statistics['sent'] ?? 0,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'فشل',
              count: state.statistics['failed'] ?? 0,
              icon: Icons.error,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    NotificationSchedulerState state,
    ScheduleStatus? filterStatus,
  ) {
    if (state is SchedulerLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (state is SchedulerError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationSchedulerCubit>().refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      );
    }

    if (state is SchedulerLoaded) {
      var notifications = state.notifications;

      // Apply filter if needed
      if (filterStatus != null) {
        notifications =
            notifications.where((n) => n.status == filterStatus).toList();
      }

      if (notifications.isEmpty) {
        return _buildEmptyState(filterStatus);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await context.read<NotificationSchedulerCubit>().refresh();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(notifications[index]);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(ScheduleStatus? filterStatus) {
    String message = 'لا توجد إشعارات';
    IconData icon = Icons.notifications_none;

    if (filterStatus == ScheduleStatus.pending) {
      message = 'لا توجد إشعارات قادمة';
      icon = Icons.schedule;
    } else if (filterStatus == ScheduleStatus.sent) {
      message = 'لا توجد إشعارات مرسلة';
      icon = Icons.check_circle_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/CreateScheduledNotification');
            },
            icon: const Icon(Icons.add_alarm),
            label: const Text('جدولة إشعار جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(ScheduledNotification notification) {
    final timeFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showNotificationDetails(notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(notification.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(notification.status),
                          size: 14,
                          color: _getStatusColor(notification.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(notification.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Recurrence badge
                  if (notification.isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat,
                              size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            notification.recurrence.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Body
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Time and info row
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      timeFormatter.format(notification.scheduledTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  // Target audience badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notification.targetAudience.displayName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Overdue warning
              if (notification.isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'متأخر - ${notification.formattedScheduleTime}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action buttons
              if (notification.canBeCancelled || notification.canBeRescheduled)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (notification.isPending) ...[
                        TextButton.icon(
                          onPressed: () => _sendNotificationNow(notification),
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('إرسال الآن'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (notification.canBeCancelled)
                        TextButton.icon(
                          onPressed: () => _cancelNotification(notification),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('إلغاء'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.pending:
        return Colors.orange;
      case ScheduleStatus.sent:
        return Colors.green;
      case ScheduleStatus.failed:
        return Colors.red;
      case ScheduleStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.pending:
        return Icons.schedule;
      case ScheduleStatus.sent:
        return Icons.check_circle;
      case ScheduleStatus.failed:
        return Icons.error;
      case ScheduleStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showNotificationDetails(ScheduledNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'تفاصيل الإشعار المجدول',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Details here...
              _buildDetailRow('العنوان', notification.title),
              _buildDetailRow('المحتوى', notification.body),
              _buildDetailRow(
                'الوقت المحدد',
                DateFormat('dd/MM/yyyy - hh:mm a', 'ar')
                    .format(notification.scheduledTime),
              ),
              _buildDetailRow('الحالة', notification.status.displayName),
              _buildDetailRow('التكرار', notification.recurrence.displayName),
              _buildDetailRow(
                  'الجمهور المستهدف', notification.targetAudience.displayName),

              if (notification.linkUrl != null)
                _buildDetailRow('الرابط', notification.linkUrl!),

              if (notification.sentCount > 0)
                _buildDetailRow(
                    'عدد مرات الإرسال', '${notification.sentCount}'),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (notification.canBeCancelled) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelNotification(notification);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('إلغاء الإشعار'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('إغلاق'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelNotification(ScheduledNotification notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من إلغاء هذا الإشعار المجدول؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context
          .read<NotificationSchedulerCubit>()
          .cancelScheduledNotification(notification.id);
    }
  }

  Future<void> _sendNotificationNow(ScheduledNotification notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرسال الآن'),
        content: const Text(
            'هل تريد إرسال هذا الإشعار الآن بدلاً من انتظار الوقت المحدد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('نعم، إرسال الآن'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<NotificationSchedulerCubit>().sendNow(notification.id);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
