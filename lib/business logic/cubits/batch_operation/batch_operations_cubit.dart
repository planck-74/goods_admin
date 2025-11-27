import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';

part 'batch_operations_state.dart';

class BatchOperationsCubit extends Cubit<BatchOperationsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreServicesCubit _firestoreServicesCubit;

  BatchOperationsCubit(this._firestoreServicesCubit)
      : super(BatchOperationsInitial());

  /// Update static fields with store sync
  Future<void> batchUpdateProducts({
    required List<Product> products,
    required Map<String, dynamic> updates,
    required BuildContext context,
  }) async {
    if (products.isEmpty || updates.isEmpty) {
      debugPrint('❌ batchUpdateProducts: No products or updates to process');
      emit(BatchOperationsError('لا توجد منتجات أو تحديثات للمعالجة'));
      return;
    }

    debugPrint(
        '🔄 batchUpdateProducts: Starting update for ${products.length} products');
    debugPrint('📝 Updates to apply: $updates');

    emit(BatchOperationsLoading());

    try {
      final batch = _firestore.batch();

      // Update main products collection
      debugPrint('📦 Updating main products collection...');
      for (final product in products) {
        final docRef = _firestore.collection('products').doc(product.productId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
            '  ✓ Queued update for product: ${product.name} (${product.productId})');
      }

      await batch.commit();
      debugPrint('✅ Main products collection updated successfully');

      // Sync to all stores
      debugPrint('🔄 Starting sync to stores...');
      final productsStaticData = <String, Map<String, dynamic>>{};
      for (final product in products) {
        productsStaticData[product.productId] = {
          'name': product.name,
          'classification': updates['classification'] ?? product.classification,
          'imageUrl': updates['imageUrl'] ?? product.imageUrl,
          'manufacturer': updates['manufacturer'] ?? product.manufacturer,
          'size': updates['size'] ?? product.size,
          'package': updates['package'] ?? product.package,
          'note': updates['note'] ?? product.note,
        };
        debugPrint('  📋 Prepared static data for: ${product.name}');
        debugPrint(
            '     - Classification: ${productsStaticData[product.productId]!['classification']}');
        debugPrint(
            '     - Size: ${productsStaticData[product.productId]!['size']}');
        debugPrint(
            '     - Package: ${productsStaticData[product.productId]!['package']}');
      }

      final syncResult =
          await _firestoreServicesCubit.syncMultipleProductsToAllStores(
        products.map((p) => p.productId).toList(),
        productsStaticData,
      );

      if (syncResult.success) {
        debugPrint('✅ Sync completed successfully!');
        debugPrint('   Total updates in stores: ${syncResult.totalUpdates}');
        debugPrint('   Updates per product: ${syncResult.productUpdateCounts}');
        emit(BatchOperationsSuccess(
          message:
              'تم تحديث ${products.length} منتج وتمت المزامنة مع ${syncResult.totalUpdates} منتج في المتاجر',
          affectedCount: products.length,
        ));
      } else {
        debugPrint('⚠️ Sync failed: ${syncResult.error}');
        emit(BatchOperationsError(
            'تم التحديث لكن فشلت المزامنة: ${syncResult.error}'));
      }
    } catch (e) {
      debugPrint('❌ Error in batchUpdateProducts: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      emit(BatchOperationsError('حدث خطأ أثناء التحديث المجمع: $e'));
    }
  }

  Future<void> batchDeleteProducts({
    required List<Product> products,
    required BuildContext context,
  }) async {
    if (products.isEmpty) {
      debugPrint('❌ batchDeleteProducts: No products to delete');
      emit(BatchOperationsError('لا توجد منتجات للحذف'));
      return;
    }

    debugPrint(
        '🗑️ batchDeleteProducts: Starting deletion for ${products.length} products');
    emit(BatchOperationsLoading());

    try {
      final batch = _firestore.batch();

      // Delete from main collection
      debugPrint('📦 Deleting from main products collection...');
      for (final product in products) {
        final docRef = _firestore.collection('products').doc(product.productId);
        batch.delete(docRef);
        debugPrint(
            '  ✓ Queued deletion for: ${product.name} (${product.productId})');
      }

      await batch.commit();
      debugPrint('✅ Main products collection deletion completed');

      // Get store IDs from admin_data
      debugPrint('🔍 Fetching store IDs from admin_data/storesIDs...');
      final storesIDsDoc =
          await _firestore.collection('admin_data').doc('storesIDs').get();

      if (!storesIDsDoc.exists || storesIDsDoc.data()?['storesIDs'] == null) {
        debugPrint('⚠️ No store IDs found, skipping store deletion');
        emit(BatchOperationsSuccess(
          message: 'تم حذف ${products.length} منتج من المجموعة الرئيسية',
          affectedCount: products.length,
        ));
        return;
      }

      final List<String> storeIDs =
          List<String>.from(storesIDsDoc.data()!['storesIDs']);
      debugPrint('✅ Found ${storeIDs.length} store IDs');

      // Delete from all stores
      debugPrint('🏪 Starting deletion from stores...');
      int totalDeleted = 0;

      for (String storeId in storeIDs) {
        debugPrint('  🏪 Processing store: $storeId');

        WriteBatch storeBatch = _firestore.batch();
        int storeDeleteCount = 0;

        for (final product in products) {
          final storeProductsRef = _firestore
              .collection('stores')
              .doc(storeId)
              .collection('products');

          final productsSnapshot = await storeProductsRef
              .where('productId', isEqualTo: product.productId)
              .get();

          debugPrint(
              '     Found ${productsSnapshot.docs.length} instances of ${product.name} in store $storeId');

          for (var doc in productsSnapshot.docs) {
            storeBatch.delete(doc.reference);
            storeDeleteCount++;
            totalDeleted++;
            debugPrint('       ✓ Queued deletion: ${doc.id}');
          }
        }

        if (storeDeleteCount > 0) {
          await storeBatch.commit();
          debugPrint(
              '  ✅ Deleted $storeDeleteCount products from store $storeId');
        } else {
          debugPrint('  ℹ️ No products found in store $storeId');
        }
      }

      debugPrint(
          '✅ Batch deletion completed! Total deleted from stores: $totalDeleted');
      emit(BatchOperationsSuccess(
        message: 'تم حذف ${products.length} منتج من جميع المتاجر بنجاح',
        affectedCount: products.length,
      ));
    } catch (e) {
      debugPrint('❌ Error in batchDeleteProducts: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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

  /// Bulk price update - ONLY updates stores, not main products collection
  Future<void> bulkPriceUpdate({
    required List<Product> products,
    required double multiplier,
    required BuildContext context,
  }) async {
    if (products.isEmpty || multiplier <= 0) {
      debugPrint(
          '❌ bulkPriceUpdate: Invalid input - products: ${products.length}, multiplier: $multiplier');
      emit(BatchOperationsError('المدخلات غير صحيحة'));
      return;
    }

    debugPrint(
        '💰 bulkPriceUpdate: Starting price update for ${products.length} products with multiplier $multiplier');
    emit(BatchOperationsLoading());

    try {
      // Get store IDs from admin_data
      debugPrint('🔍 Fetching store IDs from admin_data/storesIDs...');
      final storesIDsDoc =
          await _firestore.collection('admin_data').doc('storesIDs').get();

      if (!storesIDsDoc.exists || storesIDsDoc.data()?['storesIDs'] == null) {
        debugPrint('⚠️ No store IDs found');
        emit(BatchOperationsError('لا توجد متاجر لتحديث الأسعار'));
        return;
      }

      final List<String> storeIDs =
          List<String>.from(storesIDsDoc.data()!['storesIDs']);
      debugPrint('🏪 Found ${storeIDs.length} stores to update');

      int totalUpdated = 0;

      for (String storeId in storeIDs) {
        debugPrint('  🏪 Processing store: $storeId');

        WriteBatch batch = _firestore.batch();
        int batchCount = 0;

        for (final product in products) {
          final storeProductsRef = _firestore
              .collection('stores')
              .doc(storeId)
              .collection('products');

          final productsSnapshot = await storeProductsRef
              .where('productId', isEqualTo: product.productId)
              .get();

          debugPrint(
              '     Found ${productsSnapshot.docs.length} instances of ${product.name} in store $storeId');

          for (var doc in productsSnapshot.docs) {
            final currentPrice = (doc.data()['price'] ?? 0).toDouble();
            final newPrice = (currentPrice * multiplier).round();

            debugPrint(
                '       Updating price: $currentPrice → $newPrice (${doc.id})');

            batch.update(doc.reference, {
              'price': newPrice,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            totalUpdated++;
            batchCount++;

            if (batchCount >= 500) {
              await batch.commit();
              debugPrint(
                  '     ✅ Committed batch of $batchCount updates in store $storeId');
              batch = _firestore.batch();
              batchCount = 0;
            }
          }
        }

        if (batchCount > 0) {
          await batch.commit();
          debugPrint(
              '  ✅ Committed final batch of $batchCount updates in store $storeId');
        }
      }

      debugPrint('✅ Bulk price update completed! Total updated: $totalUpdated');
      emit(BatchOperationsSuccess(
        message: 'تم تحديث أسعار $totalUpdated منتج في المتاجر بنجاح',
        affectedCount: totalUpdated,
      ));
    } catch (e) {
      debugPrint('❌ Error in bulkPriceUpdate: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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
