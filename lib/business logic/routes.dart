import 'package:flutter/material.dart';
import 'package:goods_admin/presentation/screens/add_location/add_area.dart';
import 'package:goods_admin/presentation/screens/add_location/add_city.dart';
import 'package:goods_admin/presentation/screens/add_location/add_government.dart';
import 'package:goods_admin/presentation/screens/add_location/add_location.dart';
import 'package:goods_admin/presentation/screens/add_location/locations.dart';
import 'package:goods_admin/presentation/screens/add_product.dart';
import 'package:goods_admin/presentation/screens/auth_screens/sign_in.dart';
import 'package:goods_admin/presentation/screens/carousel_admin_screen.dart';
import 'package:goods_admin/presentation/screens/edit_clients.dart';
import 'package:goods_admin/presentation/screens/edit_products.dart';
import 'package:goods_admin/presentation/screens/edit_products_classification.dart';
import 'package:goods_admin/presentation/screens/home.dart';

final Map<String, WidgetBuilder> routes = {
  '/SignIn': (context) => const SignIn(),
  '/Home': (context) => const Home(),
  '/AddProduct': (context) => const AddProduct(),
  '/EditProductsClassification': (context) =>
      const EditProductsClassification(),
  '/EditClients': (context) => const EditClients(),
  '/EditProducts': (context) => const EditProducts(),
  '/AddLocation': (context) => const AddLocation(),
  '/AddGovernment': (context) => const AddGovernment(),
  '/AddCity': (context) => const AddCity(),
  '/AddArea': (context) => const AddArea(),
  '/Locations': (context) => const Locations(),
  '/CarouselAdminScreen': (context) => const CarouselAdminScreen(),
};
