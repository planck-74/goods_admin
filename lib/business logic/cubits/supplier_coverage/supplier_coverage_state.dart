// lib/business_logic/cubits/supplier_coverage/supplier_coverage_state.dart

import 'package:flutter/foundation.dart';
import 'package:goods_admin/data/models/location_model.dart';

@immutable
abstract class SupplierCoverageState {}

class SupplierCoverageInitial extends SupplierCoverageState {}

class SupplierCoverageLoading extends SupplierCoverageState {}

class SupplierCoverageLoaded extends SupplierCoverageState {
  final SupplierModel supplier;
  final List<String> governments;
  final Map<String, List<String>> citiesByGovernment; // cache للمدن

  SupplierCoverageLoaded({
    required this.supplier,
    this.governments = const [],
    this.citiesByGovernment = const {},
  });

  SupplierCoverageLoaded copyWith({
    SupplierModel? supplier,
    List<String>? governments,
    Map<String, List<String>>? citiesByGovernment,
  }) {
    return SupplierCoverageLoaded(
      supplier: supplier ?? this.supplier,
      governments: governments ?? this.governments,
      citiesByGovernment: citiesByGovernment ?? this.citiesByGovernment,
    );
  }

  List<String> getCitiesForGovernment(String government) {
    return citiesByGovernment[government] ?? [];
  }
}

class SupplierCoverageError extends SupplierCoverageState {
  final String message;

  SupplierCoverageError(this.message);
}
