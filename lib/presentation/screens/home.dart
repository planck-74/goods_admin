import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_container.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
            GestureDetector(
              onTap: () async {},
              child: const Text('إدارة تطبيقات بضائع',
                  style: TextStyle(color: whiteColor)),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.exit_to_app_sharp),
            ),
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
              _buildCustomContainer(
                context: context,
                screenWidth: screenWidth,
                text: 'إضافة منتج',
                routeName: '/AddProduct',
              ),
              _buildCustomContainer(
                context: context,
                screenWidth: screenWidth,
                text: 'تعديل المنتجات',
                routeName: '/EditProducts',
              ),
              _buildCustomContainer(
                context: context,
                screenWidth: screenWidth,
                text: 'العملاء',
                routeName: '/EditClients',
              ),
              _buildCustomContainer(
                context: context,
                screenWidth: screenWidth,
                text: 'إضافة موقع',
                routeName: '/AddLocation',
              ),
              _buildCustomContainer(
                context: context,
                screenWidth: screenWidth,
                text: 'إضافة بانر دعائي',
                routeName: '/CarouselAdminScreen',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushReplacementNamed(context, '/SignIn');
    });
  }

  Widget _buildCustomContainer({
    required BuildContext context,
    required double screenWidth,
    required String text,
    required String routeName,
  }) {
    return customContainer(
      context: context,
      onTap: () => Navigator.pushNamed(context, routeName),
      screenWidth: screenWidth,
      text: text,
    );
  }
}
