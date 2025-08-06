import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';

part 'batch_operations_state.dart';

class BatchOperationsCubit extends Cubit<BatchOperationsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BatchOperationsCubit() : super(BatchOperationsInitial());

  Future<void> batchUpdateProducts({
    required List<Product> products,
    required Map<String, dynamic> updates,
    required BuildContext context,
  }) async {
    if (products.isEmpty || updates.isEmpty) {
      emit(BatchOperationsError('لا توجد منتجات أو تحديثات للمعالجة'));
      return;
    }

    emit(BatchOperationsLoading());

    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final docRef = _firestore.collection('products').doc(product.productId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        syncStoreProductsByIds(context, storeId, [product.productId]);
      }

      await batch.commit();

      emit(BatchOperationsSuccess(
        message: 'تم تحديث ${products.length} منتج بنجاح',
        affectedCount: products.length,
      ));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء التحديث المجمع: $e'));
    }
  }

  Future<void> batchDeleteProducts({
    required List<Product> products,
    required BuildContext context,
  }) async {
    if (products.isEmpty) {
      emit(BatchOperationsError('لا توجد منتجات للحذف'));
      return;
    }

    emit(BatchOperationsLoading());

    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final docRef = _firestore.collection('products').doc(product.productId);
        batch.delete(docRef);
        syncStoreProductsByIds(context, storeId, [product.productId]);
      }

      await batch.commit();

      emit(BatchOperationsSuccess(
        message: 'تم حذف ${products.length} منتج بنجاح',
        affectedCount: products.length,
      ));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء الحذف المجمع: $e'));
    }
  }

  Future<void> applyClassificationToProducts({
    required List<Product> products,
    required String classification,
    required BuildContext context,
  }) async {
    if (products.isEmpty || classification.isEmpty) {
      emit(BatchOperationsError('المدخلات غير صحيحة'));
      return;
    }

    await batchUpdateProducts(
      products: products,
      updates: {'classification': classification},
      context: context,
    );
  }

  Future<void> applyManufacturerToProducts({
    required List<Product> products,
    required String manufacturer,
    required BuildContext context,
  }) async {
    if (products.isEmpty || manufacturer.isEmpty) {
      emit(BatchOperationsError('المدخلات غير صحيحة'));
      return;
    }

    await batchUpdateProducts(
      products: products,
      updates: {'manufacturer': manufacturer},
      context: context,
    );
  }

  Future<void> bulkPriceUpdate({
    required List<Product> products,
    required double multiplier,
    required BuildContext context,
  }) async {
    if (products.isEmpty || multiplier <= 0) {
      emit(BatchOperationsError('المدخلات غير صحيحة'));
      return;
    }

    emit(BatchOperationsLoading());

    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final docRef = _firestore.collection('products').doc(product.productId);

        batch.update(docRef, {
          'updatedAt': FieldValue.serverTimestamp(),
        });
        syncStoreProductsByIds(context, storeId, [product.productId]);
      }

      await batch.commit();

      emit(BatchOperationsSuccess(
        message: 'تم تحديث أسعار ${products.length} منتج بنجاح',
        affectedCount: products.length,
      ));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء تحديث الأسعار: $e'));
    }
  }

  Future<void> exportProductsData({
    required List<Product> products,
    required BuildContext context,
  }) async {
    if (products.isEmpty) {
      emit(BatchOperationsError('لا توجد منتجات للتصدير'));
      return;
    }

    emit(BatchOperationsLoading());

    try {
      emit(BatchOperationsSuccess(
        message: 'تم تحضير بيانات ${products.length} منتج للتصدير',
        affectedCount: products.length,
      ));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء تصدير البيانات: $e'));
    }
  }

  Future<void> duplicateProducts({
    required List<Product> products,
    required String nameSuffix,
    required BuildContext context,
  }) async {
    if (products.isEmpty || nameSuffix.isEmpty) {
      emit(BatchOperationsError('المدخلات غير صحيحة'));
      return;
    }

    emit(BatchOperationsLoading());

    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final newProductId = _firestore.collection('products').doc().id;
        final docRef = _firestore.collection('products').doc(newProductId);

        final duplicatedProduct = Product(
          name: '${product.name} $nameSuffix',
          manufacturer: product.manufacturer,
          size: product.size,
          package: product.package,
          classification: product.classification,
          note: product.note,
          salesCount: 0,
          imageUrl: product.imageUrl,
          productId: newProductId,
        );

        batch.set(docRef, duplicatedProduct.toMap());
        syncStoreProductsByIds(context, storeId, [product.productId]);
      }

      await batch.commit();

      emit(BatchOperationsSuccess(
        message: 'تم نسخ ${products.length} منتج بنجاح',
        affectedCount: products.length,
      ));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء نسخ المنتجات: $e'));
    }
  }

  Future<void> resetFieldForProducts({
    required List<Product> products,
    required String fieldName,
    required dynamic resetValue,
    required BuildContext context,
  }) async {
    if (products.isEmpty || fieldName.isEmpty) {
      emit(BatchOperationsError('المدخلات غير صحيحة'));
      return;
    }

    await batchUpdateProducts(
      products: products,
      updates: {fieldName: resetValue},
      context: context,
    );
  }

  Future<void> getProductsStatistics({
    required List<Product> products,
  }) async {
    if (products.isEmpty) {
      emit(BatchOperationsError('لا توجد منتجات لحساب الإحصائيات'));
      return;
    }

    emit(BatchOperationsLoading());

    try {
      final stats = {
        'totalProducts': products.length,
        'totalSales':
            products.fold<int>(0, (sum, product) => sum + product.salesCount),
        'classifications': _getUniqueValues(products, (p) => p.classification),
        'manufacturers': _getUniqueValues(products, (p) => p.manufacturer),
        'packages': _getUniqueValues(products, (p) => p.package),
        'averageSales': products.isEmpty
            ? 0
            : products.fold<int>(
                    0, (sum, product) => sum + product.salesCount) /
                products.length,
      };

      emit(BatchOperationsStatistics(statistics: stats));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء حساب الإحصائيات: $e'));
    }
  }

  Set<String> _getUniqueValues(
      List<Product> products, String Function(Product) getValue) {
    return products.map(getValue).where((value) => value.isNotEmpty).toSet();
  }

  Future<void> advancedProductSearch({
    required String? name,
    required String? classification,
    required String? manufacturer,
    required int? minSales,
    required int? maxSales,
  }) async {
    emit(const BatchOperationsLoading());

    try {
      Query query = _firestore.collection('products');

      if (name != null && name.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: name)
            .where('name', isLessThanOrEqualTo: '$name\uf8ff');
      }

      if (classification != null && classification.isNotEmpty) {
        query = query.where('classification', isEqualTo: classification);
      }

      if (manufacturer != null && manufacturer.isNotEmpty) {
        query = query.where('manufacturer', isEqualTo: manufacturer);
      }

      if (minSales != null) {
        query = query.where('salesCount', isGreaterThanOrEqualTo: minSales);
      }

      if (maxSales != null) {
        query = query.where('salesCount', isLessThanOrEqualTo: maxSales);
      }

      final querySnapshot = await query.get();
      final products = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      emit(BatchOperationsSearchResults(products: products));
    } catch (e) {
      emit(BatchOperationsError('حدث خطأ أثناء البحث المتقدم: $e'));
    }
  }

  void resetState() {
    emit(const BatchOperationsInitial());
  }
}
