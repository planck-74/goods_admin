import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_state.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class NotificationsManagement extends StatefulWidget {
  const NotificationsManagement({super.key});

  @override
  State<NotificationsManagement> createState() =>
      _NotificationsManagementState();
}

class _NotificationsManagementState extends State<NotificationsManagement>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    context.read<GetClassificationsCubit>().getProductsClassifications();
    context.read<FetchProductsCubit>().fetchProducts();

    // Load scheduled notifications statistics
    context.read<NotificationSchedulerCubit>().loadScheduledNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Icon(Icons.notifications_active, color: whiteColor, size: 24),
            const SizedBox(width: 8),
            const Text(
              'إدارة الإشعارات',
              style: TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context
              .read<GetClassificationsCubit>()
              .getProductsClassifications();
          await context.read<NotificationSchedulerCubit>().refresh();
        },
        child: AnimatedBuilder(
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
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // Quick Actions Section
          _buildSectionTitle('إرسال فوري', Icons.send),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(),
          const SizedBox(height: 32),

          // Scheduled Notifications Section
          _buildSectionTitle('الجدولة والتخطيط', Icons.schedule),
          const SizedBox(height: 16),
          _buildScheduledSection(),
          const SizedBox(height: 32),

          // Statistics Section
          _buildSectionTitle('الإحصائيات', Icons.analytics),
          const SizedBox(height: 16),
          _buildStatisticsSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.campaign,
            size: 56,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'إدارة الإشعارات المتقدمة',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أرسل الإشعارات فوراً أو جدولها للمستقبل',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      children: [
        _buildActionCard(
          title: 'إرسال لجميع العملاء',
          description: 'أرسل إشعار فوري لجميع المستخدمين',
          icon: Icons.group,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/SendToAll'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'إرسال لعملاء محددين',
          description: 'اختر العملاء وأرسل لهم إشعار مخصص',
          icon: Icons.people_outline,
          color: Colors.green,
          onTap: () =>
              Navigator.pushNamed(context, '/SendToSelectedClientsScreen'),
        ),
      ],
    );
  }

  Widget _buildScheduledSection() {
    return Column(
      children: [
        _buildActionCard(
          title: 'جدولة إشعار جديد',
          description: 'حدد وقتاً مستقبلياً لإرسال الإشعار',
          icon: Icons.add_alarm,
          color: Colors.orange,
          onTap: () =>
              Navigator.pushNamed(context, '/CreateScheduledNotification'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'عرض الإشعارات المجدولة',
          description: 'إدارة وتتبع الإشعارات المجدولة',
          icon: Icons.schedule,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, '/NotificationScheduler'),
          trailing: BlocBuilder<NotificationSchedulerCubit,
              NotificationSchedulerState>(
            builder: (context, state) {
              if (state is SchedulerLoaded) {
                final pendingCount = state.statistics['pending'] ?? 0;
                if (pendingCount > 0) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return BlocBuilder<NotificationSchedulerCubit, NotificationSchedulerState>(
      builder: (context, state) {
        if (state is SchedulerLoaded) {
          final stats = state.statistics;
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'قيد الانتظار',
                        stats['pending'] ?? 0,
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'تم الإرسال',
                        stats['sent'] ?? 0,
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'فشل',
                        stats['failed'] ?? 0,
                        Icons.error,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'الإجمالي',
                        stats['total'] ?? 0,
                        Icons.list_alt,
                        primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
