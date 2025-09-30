import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/buttons/main_button.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class OrdersManagement extends StatefulWidget {
  const OrdersManagement({super.key});

  @override
  State<OrdersManagement> createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement> {
  @override
  initState() {
    super.initState();
    context.read<GetClassificationsCubit>().getProductsClassifications();
    context.read<FetchProductsCubit>().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Text('إدارة المنتجات', style: TextStyle(color: whiteColor)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return context
              .read<GetClassificationsCubit>()
              .getProductsClassifications();
        },
        child: Center(
          child: Column(
            children: [
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'الطلبات',
                routeName: '/OrdersScreen',
              ),
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'تقارير الطلبات',
                routeName: '/ReportsScreen',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
