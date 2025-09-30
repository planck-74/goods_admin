// lib/screens/manufacturers_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'product_selection_for_manufacturer_screen.dart';

class ManufacturersManagement extends StatefulWidget {
  const ManufacturersManagement({super.key});

  @override
  State<ManufacturersManagement> createState() =>
      _ManufacturersManagementState();
}

class _ManufacturersManagementState extends State<ManufacturersManagement> {
  @override
  void initState() {
    super.initState();
    context.read<GetClassificationsCubit>().getProductsClassifications();
    context.read<FetchProductsCubit>().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        const Row(
          children: [
            Text('إدارة المصانع والمنتجات',
                style: TextStyle(color: whiteColor)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context
              .read<GetClassificationsCubit>()
              .getProductsClassifications();
          await context.read<FetchProductsCubit>().fetchProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.factory,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'إدارة المصانع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'قم بإضافة المصانع وتعيين المنتجات لها',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                _ActionButton(
                  icon: Icons.add_business,
                  title: 'إضافة مصنع جديد',
                  subtitle: 'إضافة مصنع إلى القائمة',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushNamed(context, '/ManufacturersScreen')
                        .then((_) {
                      context.read<FetchProductsCubit>().fetchProducts();
                    });
                  },
                ),

                const SizedBox(height: 12),

                _ActionButton(
                  icon: Icons.assignment_turned_in,
                  title: 'تعيين منتجات لمصنع',
                  subtitle: 'اختر منتجات وعينها للمصانع',
                  color: Theme.of(context).primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<FetchProductsCubit>(),
                          child: const ProductSelectionForManufacturerScreen(),
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        context.read<FetchProductsCubit>().fetchProducts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم تحديث التعيينات بنجاح',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Info card
                Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'يمكنك تعيين منتجات متعددة لأكثر من مصنع في نفس الوقت',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
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
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
