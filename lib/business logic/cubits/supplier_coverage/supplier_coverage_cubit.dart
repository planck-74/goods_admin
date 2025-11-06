// lib/business_logic/cubits/supplier_coverage/supplier_coverage_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:goods_admin/data/models/location_model.dart';
import '../../../data/repositories/supplier_repository.dart';
import 'supplier_coverage_state.dart';

class SupplierCoverageCubit extends Cubit<SupplierCoverageState> {
  final SupplierRepository _supplierRepo;
  final LocationRepository _locationRepo;

  SupplierCoverageCubit({
    required SupplierRepository supplierRepo,
    required LocationRepository locationRepo,
  })  : _supplierRepo = supplierRepo,
        _locationRepo = locationRepo,
        super(SupplierCoverageInitial());

  Future<void> loadSupplierCoverage(String supplierId) async {
    try {
      emit(SupplierCoverageLoading());

      final supplier = await _supplierRepo.getSupplier(supplierId);
      if (supplier == null) {
        emit(SupplierCoverageError('المورد غير موجود'));
        return;
      }

      final governments = await _locationRepo.getGovernments();

      emit(SupplierCoverageLoaded(
        supplier: supplier,
        governments: governments,
      ));
    } catch (e) {
      emit(SupplierCoverageError('فشل في تحميل البيانات: ${e.toString()}'));
    }
  }

  Future<void> loadCitiesForGovernment(String government) async {
    final currentState = state;
    if (currentState is! SupplierCoverageLoaded) return;

    try {
      // تحقق من الـ cache
      if (currentState.citiesByGovernment.containsKey(government)) {
        return;
      }

      final cities = await _locationRepo.getCities(government);

      final updatedCache =
          Map<String, List<String>>.from(currentState.citiesByGovernment);
      updatedCache[government] = cities;

      emit(currentState.copyWith(citiesByGovernment: updatedCache));
    } catch (e) {
      // لا نعرض error للمدن، فقط نتجاهل
    }
  }

  Future<void> addFullGovernment(String government) async {
    final currentState = state;
    if (currentState is! SupplierCoverageLoaded) return;

    try {
      // احذف أي مدن محددة من نفس المحافظة (لأن المحافظة كاملة الآن)
      final filteredAreas = currentState.supplier.coverageAreas
          .where((c) => c.government != government)
          .toList();

      final coverage = CoverageAreaModel.fullGovernment(government);

      await _supplierRepo.addCoverageArea(currentState.supplier.id, coverage);

      final updatedSupplier = currentState.supplier.copyWith(
        coverageAreas: [...filteredAreas, coverage],
      );

      emit(currentState.copyWith(supplier: updatedSupplier));
    } catch (e) {
      emit(SupplierCoverageError('فشل في إضافة المحافظة: ${e.toString()}'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> addSpecificCity(String government, String city) async {
    final currentState = state;
    if (currentState is! SupplierCoverageLoaded) return;

    try {
      final coverage = CoverageAreaModel.specificCity(government, city);

      await _supplierRepo.addCoverageArea(currentState.supplier.id, coverage);

      final updatedSupplier = currentState.supplier.copyWith(
        coverageAreas: [...currentState.supplier.coverageAreas, coverage],
      );

      emit(currentState.copyWith(supplier: updatedSupplier));
    } catch (e) {
      emit(SupplierCoverageError('فشل في إضافة المدينة: ${e.toString()}'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> removeCoverageArea(CoverageAreaModel coverage) async {
    final currentState = state;
    if (currentState is! SupplierCoverageLoaded) return;

    try {
      await _supplierRepo.removeCoverageArea(
          currentState.supplier.id, coverage);

      final updatedAreas = currentState.supplier.coverageAreas
          .where((c) => c != coverage)
          .toList();

      final updatedSupplier = currentState.supplier.copyWith(
        coverageAreas: updatedAreas,
      );

      emit(currentState.copyWith(supplier: updatedSupplier));
    } catch (e) {
      emit(SupplierCoverageError('فشل في حذف منطقة التغطية: ${e.toString()}'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  void reset() {
    emit(SupplierCoverageInitial());
  }
}
