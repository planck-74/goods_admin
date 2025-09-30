import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/buttons/main_button.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';

class ProductsManagement extends StatefulWidget {
  const ProductsManagement({super.key});

  @override
  State<ProductsManagement> createState() => _ProductsManagementState();
}

class _ProductsManagementState extends State<ProductsManagement> {
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
                text: 'إضافة منتج',
                routeName: '/AddProduct',
              ),
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'تعديل المنتجات',
                routeName: '/EditProducts',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
