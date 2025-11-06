// lib/business_logic/cubits/suppliers/suppliers_state.dart

import 'package:flutter/foundation.dart';
import 'package:goods_admin/data/models/location_model.dart';

@immutable
abstract class SuppliersState {}

class SuppliersInitial extends SuppliersState {}

class SuppliersLoading extends SuppliersState {}

class SuppliersLoaded extends SuppliersState {
  final List<SupplierModel> suppliers;

  SuppliersLoaded(this.suppliers);
}

class SuppliersError extends SuppliersState {
  final String message;

  SuppliersError(this.message);
}
