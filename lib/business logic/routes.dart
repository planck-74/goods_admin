import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/notification_scheduler_cubit/notification_scheduler_cubit.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/presentation/screens/add_location/add_area.dart';
import 'package:goods_admin/presentation/screens/add_location/add_city.dart';
import 'package:goods_admin/presentation/screens/add_location/add_government.dart';
import 'package:goods_admin/presentation/screens/add_location/add_location.dart';
import 'package:goods_admin/presentation/screens/add_location/locations.dart';
import 'package:goods_admin/presentation/screens/add_location/suppliers_screen.dart';
import 'package:goods_admin/presentation/screens/add_product.dart';
import 'package:goods_admin/presentation/screens/auth_screens/sign_in.dart';
import 'package:goods_admin/presentation/screens/carousel_admin_screen.dart';
import 'package:goods_admin/presentation/screens/chat_screens/chat_screen.dart';
import 'package:goods_admin/presentation/screens/chat_screens/contact_screen.dart';
import 'package:goods_admin/presentation/screens/edit_clients.dart';
import 'package:goods_admin/presentation/screens/edit_products.dart';
import 'package:goods_admin/presentation/screens/edit_products_classification.dart';
import 'package:goods_admin/presentation/screens/home.dart';
import 'package:goods_admin/presentation/screens/manufracturer_management/manufacturers_management.dart';
import 'package:goods_admin/presentation/screens/manufracturer_management/manufacturers_screen.dart';
import 'package:goods_admin/presentation/screens/manufracturer_management/product_assignment_screen.dart';
import 'package:goods_admin/presentation/screens/notification_management/create_scheduled_notification_screen.dart';
import 'package:goods_admin/presentation/screens/notification_management/notification_scheduler_screen.dart';
import 'package:goods_admin/presentation/screens/notification_management/notifications_management.dart';
import 'package:goods_admin/presentation/screens/notification_management/send_to_all.dart';
import 'package:goods_admin/presentation/screens/notification_management/send_to_selected.dart';
import 'package:goods_admin/presentation/screens/orders_management/orders_management.dart';
import 'package:goods_admin/presentation/screens/orders_management/orders_screen.dart';
import 'package:goods_admin/presentation/screens/orders_management/reports_screen.dart';
import 'package:goods_admin/presentation/screens/products_management.dart';
import 'package:goods_admin/test.dart';

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
  '/ProductsManagement': (context) => const ProductsManagement(),
  '/NotificationsManagement': (context) => const NotificationsManagement(),
  '/SendToAll': (context) => const SendToAll(),
  '/OrdersScreen': (context) => const OrdersScreen(),
  '/ReportsScreen': (context) => const ReportsScreen(),
  '/OrdersManagement': (context) => const OrdersManagement(),
  '/ManufacturersScreen': (context) => ManufacturersScreen(),
  '/ProductAssignmentScreen': (context) => ProductAssignmentScreen(
      manufacturer: Manufacturer(
          id: '', name: '', imageUrl: '', productsIds: [], number: 0)),
  '/ManufacturersManagement': (context) => ManufacturersManagement(),
  '/ManufacturerSelectionScreen': (context) => ManufacturerSelectionScreen(
        selectedProducts: [],
      ),
  '/SendToSelectedClientsScreen': (context) =>
      const SendToSelectedClientsScreen(),
  '/SuppliersScreen': (context) => const SuppliersScreen(),
  '/ContactScreen': (context) => const ContactScreen(),
  '/ChatScreen': (context) => const ChatScreen(),
  '/NotificationScheduler': (context) => BlocProvider(
        create: (context) => NotificationSchedulerCubit(),
        child: const NotificationSchedulerScreen(),
      ),
  '/CreateScheduledNotification': (context) =>
      const CreateScheduledNotificationScreen(),
};
