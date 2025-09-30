// lib/business logic/cubits/product_assignment_cubit/product_assignment_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/product_assignment_cubit/product_assignment_state.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/repos/manufacturer_repository.dart';
import 'package:goods_admin/repos/product_repository.dart';

class ProductAssignmentCubit extends Cubit<ProductAssignmentState> {
  final ManufacturerRepository _manufacturerRepository;
  final ProductRepository _productRepository;

  ProductAssignmentCubit(this._manufacturerRepository, this._productRepository)
      : super(ProductAssignmentInitial());

  /// Load products for a specific manufacturer (existing flow)
  Future<void> loadProductsForManufacturer(Manufacturer manufacturer) async {
    try {
      emit(ProductAssignmentLoading());

      final products = await _productRepository.getProductsList();
      final selectedProductIds = Set<String>.from(manufacturer.productsIds);

      emit(ProductAssignmentLoaded(
        products: products,
        manufacturer: manufacturer.copyWith(id: manufacturer.name),
        selectedProductIds: selectedProductIds,
        assignmentMode: AssignmentMode.manufacturerToProducts,
      ));
    } catch (e) {
      emit(ProductAssignmentError(e.toString()));
    }
  }

  /// Load manufacturers for specific products (new flow)
  Future<void> loadManufacturersForProducts(
      List<Product> selectedProducts) async {
    try {
      emit(ProductAssignmentLoading());

      final manufacturers =
          await _manufacturerRepository.getManufacturers().first;
      final selectedProductIds =
          selectedProducts.map((p) => p.productId).toSet();

      // Find which manufacturers already have these products
      final preSelectedManufacturers = <String>{};
      for (var manufacturer in manufacturers) {
        // Check if manufacturer has ANY of the selected products
        if (manufacturer.productsIds
            .any((id) => selectedProductIds.contains(id))) {
          preSelectedManufacturers.add(manufacturer.name);
        }
      }

      emit(ManufacturerSelectionLoaded(
        manufacturers: manufacturers,
        selectedProducts: selectedProducts,
        selectedManufacturerIds: preSelectedManufacturers,
        assignmentMode: AssignmentMode.productsToManufacturer,
      ));
    } catch (e) {
      emit(ProductAssignmentError(e.toString()));
    }
  }

  /// Toggle product selection (for manufacturer → products flow)
  void toggleProductSelection(String productId) {
    if (state is ProductAssignmentLoaded) {
      final currentState = state as ProductAssignmentLoaded;
      final newSelectedIds = Set<String>.from(currentState.selectedProductIds);

      if (newSelectedIds.contains(productId)) {
        newSelectedIds.remove(productId);
      } else {
        newSelectedIds.add(productId);
      }

      emit(ProductAssignmentLoaded(
        products: currentState.products,
        manufacturer: currentState.manufacturer,
        selectedProductIds: newSelectedIds,
        assignmentMode: currentState.assignmentMode,
      ));
    }
  }

  /// Toggle manufacturer selection (for products → manufacturer flow)
  void toggleManufacturerSelection(String manufacturerId) {
    if (state is ManufacturerSelectionLoaded) {
      final currentState = state as ManufacturerSelectionLoaded;
      final newSelectedIds =
          Set<String>.from(currentState.selectedManufacturerIds);

      if (newSelectedIds.contains(manufacturerId)) {
        newSelectedIds.remove(manufacturerId);
      } else {
        newSelectedIds.add(manufacturerId);
      }

      emit(ManufacturerSelectionLoaded(
        manufacturers: currentState.manufacturers,
        selectedProducts: currentState.selectedProducts,
        selectedManufacturerIds: newSelectedIds,
        assignmentMode: currentState.assignmentMode,
      ));
    }
  }

  /// Save product assignments to a manufacturer
  Future<void> saveProductAssignments() async {
    if (state is ProductAssignmentLoaded) {
      try {
        final currentState = state as ProductAssignmentLoaded;

        // Validation: Check if manufacturer exists
        if (currentState.manufacturer == null) {
          emit(ProductAssignmentError('لا يوجد مصنع محدد'));
          // Restore the previous state
          emit(currentState);
          return;
        }

        final manufacturerId = currentState.manufacturer!.name;

        // Additional validation: Check if manufacturer ID is valid
        if (manufacturerId.isEmpty) {
          emit(ProductAssignmentError('معرف المصنع غير صالح'));
          emit(currentState);
          return;
        }

        emit(ProductAssignmentSaving());

        await _manufacturerRepository.updateProductAssignments(
          manufacturerId,
          currentState.selectedProductIds.toList(),
        );

        emit(ProductAssignmentSuccess());
      } catch (e) {
        emit(ProductAssignmentError('فشل في حفظ التعيين: ${e.toString()}'));
      }
    }
  }

  /// Save manufacturer assignments for products
  Future<void> saveManufacturerAssignments() async {
    if (state is ManufacturerSelectionLoaded) {
      try {
        final currentState = state as ManufacturerSelectionLoaded;

        // CRITICAL VALIDATION: Check if any manufacturers are selected
        if (currentState.selectedManufacturerIds.isEmpty) {
          emit(ProductAssignmentError('يجب اختيار مصنع واحد على الأقل'));
          // Restore the previous state
          emit(currentState);
          return;
        }

        // Validation: Check if products exist
        if (currentState.selectedProducts.isEmpty) {
          emit(ProductAssignmentError('لا توجد منتجات محددة'));
          emit(currentState);
          return;
        }

        emit(ProductAssignmentSaving());

        final selectedProductIds =
            currentState.selectedProducts.map((p) => p.productId).toList();

        // Update each selected manufacturer with the products
        for (var manufacturerId in currentState.selectedManufacturerIds) {
          final manufacturer = currentState.manufacturers
              .firstWhere((m) => m.name == manufacturerId);

          // Merge existing product IDs with new ones (avoid duplicates)
          final updatedProductIds = {
            ...manufacturer.productsIds,
            ...selectedProductIds,
          }.toList();

          await _manufacturerRepository.updateProductAssignments(
            manufacturerId,
            updatedProductIds,
          );
        }

        // Remove these products from non-selected manufacturers that had them
        for (var manufacturer in currentState.manufacturers) {
          if (!currentState.selectedManufacturerIds
              .contains(manufacturer.name)) {
            // Check if this manufacturer has any of the selected products
            final hasProducts = manufacturer.productsIds
                .any((id) => selectedProductIds.contains(id));

            if (hasProducts) {
              // Remove the selected products from this manufacturer
              final updatedProductIds = manufacturer.productsIds
                  .where((id) => !selectedProductIds.contains(id))
                  .toList();

              await _manufacturerRepository.updateProductAssignments(
                manufacturer.name,
                updatedProductIds,
              );
            }
          }
        }

        emit(ProductAssignmentSuccess());
      } catch (e) {
        emit(ProductAssignmentError('فشل في حفظ التعيين: ${e.toString()}'));
      }
    }
  }

  /// Save based on current mode with validation
  Future<void> save() async {
    if (state is ProductAssignmentLoaded) {
      await saveProductAssignments();
    } else if (state is ManufacturerSelectionLoaded) {
      await saveManufacturerAssignments();
    } else {
      emit(ProductAssignmentError('حالة غير صالحة للحفظ'));
    }
  }
}
