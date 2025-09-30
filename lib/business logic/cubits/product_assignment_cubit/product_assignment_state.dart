// lib/business logic/cubits/product_assignment_cubit/product_assignment_state.dart
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/data/models/product_model.dart';

enum AssignmentMode {
  manufacturerToProducts, // Select products for a manufacturer
  productsToManufacturer, // Select manufacturers for products
}

abstract class ProductAssignmentState {}

class ProductAssignmentInitial extends ProductAssignmentState {}

class ProductAssignmentLoading extends ProductAssignmentState {}

class ProductAssignmentLoaded extends ProductAssignmentState {
  final List<Product> products;
  final Manufacturer? manufacturer;
  final Set<String> selectedProductIds;
  final AssignmentMode assignmentMode;

  ProductAssignmentLoaded({
    required this.products,
    this.manufacturer,
    required this.selectedProductIds,
    required this.assignmentMode,
  });
}

class ManufacturerSelectionLoaded extends ProductAssignmentState {
  final List<Manufacturer> manufacturers;
  final List<Product> selectedProducts;
  final Set<String> selectedManufacturerIds;
  final AssignmentMode assignmentMode;

  ManufacturerSelectionLoaded({
    required this.manufacturers,
    required this.selectedProducts,
    required this.selectedManufacturerIds,
    required this.assignmentMode,
  });
}

class ProductAssignmentSaving extends ProductAssignmentState {}

class ProductAssignmentSuccess extends ProductAssignmentState {}

class ProductAssignmentError extends ProductAssignmentState {
  final String message;

  ProductAssignmentError(this.message);
}
