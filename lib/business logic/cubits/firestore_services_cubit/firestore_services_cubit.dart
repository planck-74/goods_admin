import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_state.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';

class FirestoreServicesCubit extends Cubit<FirestoreServicesState> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String collectionPath = 'products';
  final String docRef = '';
  final Map<String, String> classification = {};
  final Map<String, String> manufacturer = {};
  final Map<String, String> packageType = {};
  final Map<String, String> packageUnit = {};
  final Map<String, String> sizeUnit = {};

  CollectionReference get _productsRef => db.collection(collectionPath);

  FirestoreServicesCubit() : super(FirestoreServicesInitial());

  /// Get store IDs from admin_data/storesIDs
  Future<List<String>> _getStoreIds() async {
    try {
      debugPrint('🔍 Fetching store IDs from admin_data/storesIDs...');

      final storesIDsDoc =
          await db.collection('admin_data').doc('storesIDs').get();

      if (!storesIDsDoc.exists || storesIDsDoc.data()?['storesIDs'] == null) {
        debugPrint('⚠️ No store IDs found in admin_data/storesIDs');
        return [];
      }

      final List<String> storeIds =
          List<String>.from(storesIDsDoc.data()!['storesIDs']);
      debugPrint('✅ Found ${storeIds.length} store IDs: $storeIds');

      return storeIds;
    } catch (e) {
      debugPrint('❌ Error fetching store IDs: $e');
      return [];
    }
  }

  /// Sync static product data across all stores (using stored IDs)
  Future<SyncResult> syncProductToAllStores(
      String productId, Map<String, dynamic> staticData) async {
    debugPrint(
        '🔄 syncProductToAllStores: Starting sync for productId: $productId');
    debugPrint('📝 Static data to sync:');
    staticData.forEach((key, value) {
      debugPrint('   - $key: $value');
    });

    try {
      // Get store IDs from admin_data
      final storeIds = await _getStoreIds();

      if (storeIds.isEmpty) {
        debugPrint('⚠️ No store IDs available for sync');
        return SyncResult(
          success: false,
          error: 'لا توجد متاجر للمزامنة',
        );
      }

      debugPrint('🏪 Will sync to ${storeIds.length} stores');

      int totalStores = storeIds.length;
      int updatedCount = 0;
      int notFoundCount = 0;

      WriteBatch batch = db.batch();
      int batchCount = 0;
      const int batchLimit = 500;

      for (String storeId in storeIds) {
        debugPrint('  📦 Processing store: $storeId');

        final storeProductsRef =
            db.collection('stores').doc(storeId).collection('products');

        // Query for products with this productId
        debugPrint('     🔍 Searching for productId: $productId');
        final productsSnapshot = await storeProductsRef
            .where('productId', isEqualTo: productId)
            .get();

        debugPrint('     📊 Found ${productsSnapshot.docs.length} matches');

        if (productsSnapshot.docs.isEmpty) {
          notFoundCount++;
          debugPrint('     ℹ️ Product not found in store $storeId');
          continue;
        }

        for (var productDoc in productsSnapshot.docs) {
          debugPrint('        ✏️ Updating document: ${productDoc.id}');
          debugPrint('           Current data: ${productDoc.data()}');

          // Update only static fields
          batch.update(productDoc.reference, staticData);
          updatedCount++;
          batchCount++;

          debugPrint(
              '        ✅ Queued update (total: $updatedCount, batch: $batchCount)');

          // Commit batch if reached limit
          if (batchCount >= batchLimit) {
            debugPrint(
                '     🚀 Committing batch (reached limit of $batchLimit)');
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        debugPrint('🚀 Committing final batch ($batchCount updates)');
        await batch.commit();
      }

      debugPrint('✅ Sync completed successfully!');
      debugPrint('   Total stores: $totalStores');
      debugPrint('   Updated: $updatedCount');
      debugPrint('   Not found: $notFoundCount');

      return SyncResult(
        success: true,
        totalStores: totalStores,
        updatedCount: updatedCount,
        notFoundCount: notFoundCount,
      );
    } catch (e) {
      debugPrint('❌ Error in syncProductToAllStores: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Sync multiple products to all stores (using stored IDs)
  Future<BatchSyncResult> syncMultipleProductsToAllStores(
    List<String> productIds,
    Map<String, Map<String, dynamic>> productsStaticData,
  ) async {
    debugPrint('🔄 syncMultipleProductsToAllStores: Starting sync...');
    debugPrint('   Products to sync: ${productIds.length}');
    debugPrint('   Product IDs: $productIds');

    try {
      // Get store IDs from admin_data
      final storeIds = await _getStoreIds();

      if (storeIds.isEmpty) {
        debugPrint('⚠️ No store IDs available for sync');
        return BatchSyncResult(
          success: false,
          error: 'لا توجد متاجر للمزامنة',
        );
      }

      debugPrint('🏪 Will sync to ${storeIds.length} stores');

      int totalUpdates = 0;
      Map<String, int> productUpdateCounts = {};

      WriteBatch batch = db.batch();
      int batchCount = 0;
      const int batchLimit = 500;

      for (String storeId in storeIds) {
        debugPrint('  📦 Processing store: $storeId');

        for (String productId in productIds) {
          final storeProductsRef =
              db.collection('stores').doc(storeId).collection('products');

          debugPrint(
              '     🔍 Searching for productId: $productId in store $storeId');

          final productsSnapshot = await storeProductsRef
              .where('productId', isEqualTo: productId)
              .get();

          debugPrint(
              '     📊 Found ${productsSnapshot.docs.length} matches for productId: $productId');

          final staticData = productsStaticData[productId];
          if (staticData == null) {
            debugPrint(
                '     ⚠️ No static data found for productId: $productId');
            continue;
          }

          if (productsSnapshot.docs.isEmpty) {
            debugPrint(
                '     ℹ️ Product $productId not found in store $storeId');
            continue;
          }

          debugPrint('     📝 Static data to apply:');
          staticData.forEach((key, value) {
            debugPrint('        - $key: $value');
          });

          for (var productDoc in productsSnapshot.docs) {
            debugPrint('        ✏️ Updating document: ${productDoc.id}');
            debugPrint('           Current data: ${productDoc.data()}');

            batch.update(productDoc.reference, staticData);
            totalUpdates++;
            productUpdateCounts[productId] =
                (productUpdateCounts[productId] ?? 0) + 1;
            batchCount++;

            debugPrint('        ✅ Queued update (batch count: $batchCount)');

            if (batchCount >= batchLimit) {
              debugPrint(
                  '     🚀 Committing batch (reached limit of $batchLimit)');
              await batch.commit();
              batch = db.batch();
              batchCount = 0;
            }
          }
        }
      }

      if (batchCount > 0) {
        debugPrint('🚀 Committing final batch ($batchCount updates)');
        await batch.commit();
      }

      debugPrint('✅ Sync completed successfully!');
      debugPrint('   Total updates: $totalUpdates');
      debugPrint('   Updates per product:');
      productUpdateCounts.forEach((productId, count) {
        debugPrint('     - $productId: $count updates');
      });

      return BatchSyncResult(
        success: true,
        totalUpdates: totalUpdates,
        productUpdateCounts: productUpdateCounts,
      );
    } catch (e) {
      debugPrint('❌ Error in syncMultipleProductsToAllStores: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return BatchSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addProduct(
      BuildContext context, Product product, String fileName) async {
    emit(FirestoreServicesLoading());

    try {
      await db
          .collection(collectionPath)
          .doc(product.productId)
          .set(product.toMap());

      context.read<FetchProductsCubit>().addProductToList(product);

      showSuccessMessage(context, 'تمت إضافة المنتج بنجاح');
      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء إضافة المنتج: $e'));
    }
  }

  Future<List<QueryDocumentSnapshot>> searchByWords(String searchQuery) async {
    if (searchQuery.trim().isEmpty) return [];

    String cleanQuery = searchQuery.toLowerCase().trim();
    List<String> searchWords =
        cleanQuery.split(' ').where((word) => word.isNotEmpty).toList();

    QuerySnapshot allProducts = await _productsRef.get();

    List<SearchResult> scoredResults = [];

    for (var doc in allProducts.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String productName = (data['name'] ?? '').toString().toLowerCase();

      double score = 0.0;

      if (productName.contains(cleanQuery)) {
        score += 10.0;

        if (productName.startsWith(cleanQuery)) {
          score += 5.0;
        }
      }

      int matchedWords = 0;
      for (String word in searchWords) {
        if (productName.contains(word)) {
          matchedWords++;
          score += 3.0;

          if (productName.startsWith(word)) {
            score += 2.0;
          }
        }
      }

      if (score > 0) {
        if (matchedWords == searchWords.length) {
          score += 5.0;
        }

        scoredResults.add(SearchResult(doc, score));
      }
    }

    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    return scoredResults.map((result) => result.document).toList();
  }

  Future<List<QueryDocumentSnapshot>> searchProductsByName(
      String searchQuery) async {
    if (searchQuery.trim().isEmpty) return [];

    String cleanQuery = searchQuery.toLowerCase().trim();

    QuerySnapshot allProducts = await _productsRef.get();

    List<QueryDocumentSnapshot> results = allProducts.docs.where((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String productName = (data['name'] ?? '').toString().toLowerCase();

      return productName.contains(cleanQuery);
    }).toList();

    return results;
  }

  Future<void> getProductsClassifications() async {
    CollectionReference adminData = db.collection('admin_data');

    try {
      emit(FirestoreServicesLoading());

      DocumentSnapshot classificationsDoc =
          await adminData.doc('classification').get();
      DocumentSnapshot manufacturerDoc =
          await adminData.doc('manufacturer').get();
      DocumentSnapshot packageTypeDoc =
          await adminData.doc('package_type').get();
      DocumentSnapshot packageUnitDoc =
          await adminData.doc('package_unit').get();
      DocumentSnapshot sizeUnitDoc = await adminData.doc('size_unit').get();

      classification
          .addAll(Map<String, String>.from(classificationsDoc.data() as Map));
      manufacturer
          .addAll(Map<String, String>.from(manufacturerDoc.data() as Map));
      packageType
          .addAll(Map<String, String>.from(packageTypeDoc.data() as Map));
      packageUnit
          .addAll(Map<String, String>.from(packageUnitDoc.data() as Map));
      sizeUnit.addAll(Map<String, String>.from(sizeUnitDoc.data() as Map));
      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء جلب التصنيفات: $e'));
    }
  }

  void emitLoading() {
    emit(FirestoreServicesLoading());
  }

  void emitError() {
    emit(FirestoreServicesError('نقص فالبيانات'));
  }

  /// Returns SyncResult so caller can handle UI
  Future<SyncResult?> updateProduct(
    BuildContext context,
    Product product,
    FetchProductsCubit fetchProductsCubit,
  ) async {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🚀 updateProduct: STARTED');
    debugPrint('   Product ID: ${product.productId}');
    debugPrint('   Product Name: ${product.name}');
    debugPrint('   Size: ${product.size}');
    debugPrint('   Package: ${product.package}');
    debugPrint('   Classification: ${product.classification}');
    debugPrint('   Manufacturer: ${product.manufacturer}');
    debugPrint('════════════════════════════════════════════════════════');

    emit(FirestoreServicesLoading());
    debugPrint('✅ Emitted FirestoreServicesLoading state');

    try {
      // Update main products collection
      debugPrint('📦 Step 1: Updating main products collection...');
      debugPrint('   Collection: products');
      debugPrint('   Document ID: ${product.productId}');

      await db
          .collection(collectionPath)
          .doc(product.productId)
          .update(product.toMap());

      debugPrint('✅ Step 1 COMPLETED: Main products collection updated');

      // Update local cache
      debugPrint('💾 Step 2: Updating local cache...');
      fetchProductsCubit.updateProductInList(product);
      debugPrint('✅ Step 2 COMPLETED: Local cache updated');

      // Extract static data
      debugPrint('📋 Step 3: Extracting static data...');
      final staticData = _extractStaticData(product);
      debugPrint('   Static data prepared:');
      staticData.forEach((key, value) {
        debugPrint('     - $key: $value');
      });
      debugPrint('✅ Step 3 COMPLETED: Static data extracted');

      // Sync to all stores
      debugPrint('🔄 Step 4: Starting sync to all stores...');
      debugPrint('   Calling syncProductToAllStores...');

      final syncResult =
          await syncProductToAllStores(product.productId, staticData);

      debugPrint('✅ Step 4 COMPLETED: Sync finished');
      debugPrint('   Sync success: ${syncResult.success}');
      debugPrint('   Total stores: ${syncResult.totalStores}');
      debugPrint('   Updated count: ${syncResult.updatedCount}');
      debugPrint('   Not found count: ${syncResult.notFoundCount}');
      if (syncResult.error != null) {
        debugPrint('   ⚠️ Sync error: ${syncResult.error}');
      }

      debugPrint('🎯 Step 5: Emitting final state...');
      emit(FirestoreServicesLoaded());
      debugPrint('✅ Step 5 COMPLETED: Emitted FirestoreServicesLoaded state');

      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('✅ updateProduct: COMPLETED SUCCESSFULLY');
      debugPrint('════════════════════════════════════════════════════════');

      return syncResult;
    } catch (e, stackTrace) {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('❌❌❌ ERROR IN updateProduct ❌❌❌');
      debugPrint('Error: $e');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('════════════════════════════════════════════════════════');

      emit(FirestoreServicesError('حدث خطأ أثناء تحديث المنتج: $e'));
      return null;
    }
  }

  /// Extract only static fields from product
  Map<String, dynamic> _extractStaticData(Product product) {
    debugPrint('🔧 _extractStaticData: Extracting fields...');

    final data = {
      'name': product.name,
      'classification': product.classification,
      'imageUrl': product.imageUrl,
      'manufacturer': product.manufacturer,
      'size': product.size,
      'package': product.package,
      'note': product.note,
    };

    debugPrint('   Extracted ${data.length} fields');
    return data;
  }

  Future<void> deleteProduct(BuildContext context, Product product) async {
    emit(FirestoreServicesLoading());
    try {
      await db.collection(collectionPath).doc(product.productId).delete();

      context
          .read<FetchProductsCubit>()
          .removeProductFromList(product.productId);

      showSuccessMessage(context, 'تم حذف المنتج بنجاح');
      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء حذف المنتج: $e'));
    }
  }
}

class SearchResult {
  final QueryDocumentSnapshot document;
  final double score;

  SearchResult(this.document, this.score);
}

class SyncResult {
  final bool success;
  final int totalStores;
  final int updatedCount;
  final int notFoundCount;
  final String? error;

  SyncResult({
    required this.success,
    this.totalStores = 0,
    this.updatedCount = 0,
    this.notFoundCount = 0,
    this.error,
  });
}

class BatchSyncResult {
  final bool success;
  final int totalUpdates;
  final Map<String, int> productUpdateCounts;
  final String? error;

  BatchSyncResult({
    required this.success,
    this.totalUpdates = 0,
    this.productUpdateCounts = const {},
    this.error,
  });
}

/// Syncing progress dialog
class SyncProgressDialog extends StatelessWidget {
  const SyncProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'جاري مزامنة البيانات...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'يتم تحديث المنتج في جميع المتاجر',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sync result details dialog
class SyncResultDialog extends StatelessWidget {
  final SyncResult result;

  const SyncResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تفاصيل المزامنة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('إجمالي المتاجر', '${result.totalStores}'),
          const SizedBox(height: 8),
          _buildInfoRow('تم التحديث', '${result.updatedCount}', Colors.green),
          const SizedBox(height: 8),
          _buildInfoRow('غير موجود', '${result.notFoundCount}', Colors.orange),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسناً'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
