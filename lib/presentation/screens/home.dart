import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/carousel_cubit/carousel_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_supplier_data/get_supplier_data_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_state.dart';
import 'package:goods_admin/business%20logic/cubits/reports_cubit/reports_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class AppColors {
  static const primaryRed = Color.fromARGB(255, 190, 30, 19);
  static const primaryRedLight = Color.fromARGB(255, 220, 60, 49);
  static const primaryRedDark = Color.fromARGB(255, 150, 20, 10);

  // Complementary colors
  static const deepOrange = Color.fromARGB(255, 230, 90, 50);
  static const warmOrange = Color.fromARGB(255, 255, 140, 80);
  static const coral = Color.fromARGB(255, 255, 100, 90);

  // Accent colors
  static const burgundy = Color.fromARGB(255, 130, 20, 30);
  static const crimson = Color.fromARGB(255, 180, 40, 50);
  static const rose = Color.fromARGB(255, 240, 80, 100);

  // Neutral colors
  static const darkGrey = Color.fromARGB(255, 60, 60, 60);
  static const mediumGrey = Color.fromARGB(255, 120, 120, 120);
  static const lightGrey = Color.fromARGB(255, 240, 240, 240);

  // Gradient definitions
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primaryRed, primaryRedLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get warmGradient => LinearGradient(
        colors: [primaryRed, deepOrange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get sunsetGradient => LinearGradient(
        colors: [primaryRed, warmOrange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get deepGradient => LinearGradient(
        colors: [burgundy, primaryRed],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get coralGradient => LinearGradient(
        colors: [coral, rose],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get crimsonGradient => LinearGradient(
        colors: [crimson, primaryRedLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _loadData() {
    context.read<GetClassificationsCubit>().getProductsClassifications();
    context.read<FetchProductsCubit>().fetchProducts();
    context.read<CarouselCubit>().loadCarouselImages();
    context.read<OrdersCubit>().loadOrders();
    context.read<ReportsCubit>().loadReports();
    context.read<GetSupplierDataCubit>().getSupplierData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: customAppBar(
        context,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الصفحة الرئيسية',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _showSignOutDialog(context),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(),
                _buildManagementGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, ordersState) {
          return BlocBuilder<FetchProductsCubit, FetchProductsState>(
            builder: (context, productsState) {
              final totalOrders =
                  ordersState is OrdersLoaded ? ordersState.orders.length : 0;
              final pendingOrders = ordersState is OrdersLoaded
                  ? ordersState.orders
                      .where((o) => o.state == 'جاري التاكيد')
                      .length
                  : 0;
              final totalProducts = productsState is FetchProductsLoaded
                  ? productsState.products.length
                  : 0;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'الطلبات الكلية',
                      totalOrders.toString(),
                      Icons.shopping_bag_rounded,
                      AppColors.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'طلبات بانتظار التاكيد',
                      pendingOrders.toString(),
                      Icons.pending_actions_rounded,
                      AppColors.sunsetGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'المنتجات',
                      totalProducts.toString(),
                      Icons.inventory_2_rounded,
                      AppColors.deepGradient,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildManagementListItem(
              context,
              'المنتجات',
              'إدارة وتعديل المنتجات',
              Icons.inventory_2_rounded,
              AppColors.primaryGradient,
              '/ProductsManagement',
            ),
            _buildManagementListItem(
              context,
              'خدمة العملاء',
              'محادثات عملاء التجزئة',
              Icons.chat_outlined,
              AppColors.warmGradient,
              '/ContactScreen',
            ),
            _buildManagementListItem(
              context,
              'التجار',
              'إدارة حسابات التجار',
              Icons.store_rounded,
              AppColors.deepGradient,
              '/SuppliersScreen',
            ),
            _buildManagementListItem(
              context,
              'العملاء',
              'إدارة حسابات العملاء',
              Icons.people_rounded,
              AppColors.warmGradient,
              '/ClientsScreen',
            ),
            _buildManagementListItem(
              context,
              'الطلبات',
              'متابعة وإدارة الطلبات',
              Icons.shopping_cart_rounded,
              AppColors.sunsetGradient,
              '/OrdersManagement',
            ),
            _buildManagementListItem(
              context,
              'المواقع',
              'إدارة مواقع التوصيل',
              Icons.location_on_rounded,
              AppColors.crimsonGradient,
              '/AddLocation',
            ),
            _buildManagementListItem(
              context,
              'المصنعون',
              'إدارة المصنعين',
              Icons.factory_rounded,
              AppColors.warmGradient,
              '/ManufacturersManagement',
            ),
            _buildManagementListItem(
              context,
              'المجلة',
              'تعديل الإعلانات',
              Icons.view_carousel_rounded,
              AppColors.coralGradient,
              '/CarouselAdminScreen',
            ),
            _buildManagementListItem(
              context,
              'الإشعارات',
              'إرسال إشعارات للعملاء',
              Icons.notifications_rounded,
              AppColors.deepGradient,
              '/NotificationsManagement',
            ),
          ],
        )
      ],
    );
  }

  Widget _buildManagementListItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: whiteColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('تسجيل الخروج'),
          ],
        ),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.mediumGrey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _signOut(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushReplacementNamed(context, '/SignIn');
    });
  }
}
