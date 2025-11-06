// lib/business_logic/cubits/suppliers/suppliers_cubit.dart

import 'package:bloc/bloc.dart';
import '../../../data/repositories/supplier_repository.dart';
import 'suppliers_state.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  final SupplierRepository _repository;

  SuppliersCubit({required SupplierRepository repository})
      : _repository = repository,
        super(SuppliersInitial());

  Future<void> loadSuppliers() async {
    try {
      emit(SuppliersLoading());

      final suppliers = await _repository.getAllSuppliers();

      emit(SuppliersLoaded(suppliers));
    } catch (e) {
      emit(SuppliersError('فشل في تحميل الموردين: ${e.toString()}'));
    }
  }

  Future<void> refreshSuppliers() async {
    await loadSuppliers();
  }
}
