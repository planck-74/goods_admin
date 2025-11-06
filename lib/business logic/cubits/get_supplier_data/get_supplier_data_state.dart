import 'package:meta/meta.dart';

@immutable
abstract class GetSupplierDataState {}

class GetSupplierDataInitial extends GetSupplierDataState {}

class GetSupplierDataLoading extends GetSupplierDataState {}

class GetSupplierDataSuccess extends GetSupplierDataState {
  final List<Map<String, dynamic>> suppliers;

  GetSupplierDataSuccess(this.suppliers);
}

class GetSupplierDataError extends GetSupplierDataState {
  final String message;

  GetSupplierDataError(this.message);
}
