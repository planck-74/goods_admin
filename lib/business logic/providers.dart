import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/add_classification_cubit/add_classification_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/add_location/add_location_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/auth/auth_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/carousel_cubit/carousel_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/controller/controllers_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_client_data/get_client_data_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/image_picker_cubit/image_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/manufacturer_cubit/manufacturer_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/orders_cubit/orders_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/reports_cubit/reports_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/selected_clients_notification_cubit/selected_clients_notification_cubit.dart';
import 'package:goods_admin/repos/manufacturer_repository.dart';
import 'package:goods_admin/repos/orders_repository.dart';
import 'package:goods_admin/repos/product_repository.dart';

List<BlocProvider> buildProviders() {
  return [
    BlocProvider<ControllersCubit>(create: (context) => ControllersCubit()),
    BlocProvider<ImageCubit>(create: (context) => ImageCubit()),
    BlocProvider<FirestoreServicesCubit>(
        create: (context) => FirestoreServicesCubit()),
    BlocProvider<AddClassificationCubit>(
        create: (context) => AddClassificationCubit()),
    BlocProvider<GetClassificationsCubit>(
        create: (context) => GetClassificationsCubit()),
    BlocProvider<FetchProductsCubit>(create: (context) => FetchProductsCubit()),
    BlocProvider<GetClientDataCubit>(create: (context) => GetClientDataCubit()),
    BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
    BlocProvider<AddLocationCubit>(create: (context) => AddLocationCubit()),
    BlocProvider<CarouselCubit>(create: (context) => CarouselCubit()),
    BlocProvider<SelectedClientsCubit>(
        create: (context) => SelectedClientsCubit()),
    BlocProvider<OrdersCubit>(
        create: (context) => OrdersCubit(OrdersRepository())),
    BlocProvider<ReportsCubit>(
        create: (context) => ReportsCubit(OrdersRepository())),
    BlocProvider<ManufacturerCubit>(
        create: (context) => ManufacturerCubit(ManufacturerRepository())),
    BlocProvider<ProductAssignmentCubit>(
        create: (context) => ProductAssignmentCubit(
            ManufacturerRepository(), ProductRepository())),
  ];
}
