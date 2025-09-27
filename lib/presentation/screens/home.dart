import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/carousel_cubit/carousel_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/selected_clients_notification_cubit/selected_clients_notification_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/buttons/main_button.dart';
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
    context.read<CarouselCubit>().loadCarouselImages();
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
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'إدارة المنتجات',
                routeName: '/ProductsManagement',
              ),
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'إدارة العملاء',
                routeName: '/EditClients',
              ),
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'إدارة المواقع',
                routeName: '/AddLocation',
              ),
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'إدارة البانر دعائي',
                routeName: '/CarouselAdminScreen',
              ),
              mainButton(
                context: context,
                screenWidth: screenWidth,
                text: 'إدارة الإشعارات',
                routeName: '/NotificationsManagement',
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
}
