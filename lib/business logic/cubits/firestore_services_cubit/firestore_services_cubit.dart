// Fixed FirestoreServicesCubit with proper sync function
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

  Future<void> addProduct(
      BuildContext context, Product product, String fileName) async {
    emit(FirestoreServicesLoading());

    try {
      await db
          .collection(collectionPath)
          .doc(product.productId)
          .set(product.toMap());

      // Update local cache instead of refetching
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

  Future<void> updateProduct(BuildContext context, Product product) async {
    emit(FirestoreServicesLoading());

    try {
      await db
          .collection(collectionPath)
          .doc(product.productId)
          .update(product.toMap());

      // Update local cache instead of refetching
      context.read<FetchProductsCubit>().updateProductInList(product);

      // Call sync function properly
      await syncStoreProductsByIds(
          context, 'cafb6e90-0ab1-11f0-b25a-8b76462b3bd5', [product.productId]);

      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء تحديث المنتج: $e'));
    }
  }

  Future<void> deleteProduct(BuildContext context, Product product) async {
    emit(FirestoreServicesLoading());
    try {
      await db.collection(collectionPath).doc(product.productId).delete();

      // Update local cache instead of refetching
      context
          .read<FetchProductsCubit>()
          .removeProductFromList(product.productId);

      showSuccessMessage(context, 'تم حذف المنتج بنجاح');
      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء حذف المنتج: $e'));
    }
  }

  // Move the sync function here to make it accessible
  Future<void> syncStoreProductsByIds(
    BuildContext context,
    String storeId,
    List<String> productDocIds,
  ) async {
    try {
      print('🔄 Starting synchronization by product IDs...');
      print('🏪 Store ID: $storeId');
      print('🧾 Provided product IDs: $productDocIds');

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();
      int updatedCount = 0;

      for (String storeProductId in productDocIds) {
        final storeDocRef = firestore
            .collection('stores')
            .doc(storeId)
            .collection('products')
            .doc(storeProductId);

        final storeDoc = await storeDocRef.get();

        if (!storeDoc.exists) {
          print('⚠️ Store product not found: $storeProductId');
          continue;
        }

        final storeProduct = storeDoc.data()!;
        final mainProductId = storeProduct['productId'];

        print(
            '🔍 Processing store product: ${storeProduct['name']} (ID: $mainProductId)');

        final mainProductDoc =
            await firestore.collection('products').doc(mainProductId).get();

        if (mainProductDoc.exists) {
          final mainProduct = mainProductDoc.data()!;

          final updatedData = {
            ...storeProduct,
            'name': mainProduct['name'],
            'classification': mainProduct['classification'],
            'imageUrl': mainProduct['imageUrl'],
            'manufacturer': mainProduct['manufacturer'],
            'size': mainProduct['size'],
            'package': mainProduct['package'],
            'note': mainProduct['note'],
          };

          batch.update(storeDocRef, updatedData);
          updatedCount++;
          print('📝 Prepared update for product');
        } else {
          print('⚠️ Product not found in main collection: $mainProductId');
        }
      }

      print('💾 Saving batch updates...');
      await batch.commit();

      print('✅ Successfully updated $updatedCount products');
    } catch (e) {
      print('❌ Error in syncStoreProductsByIds: $e');
    }
  }
}

class SearchResult {
  final QueryDocumentSnapshot document;
  final double score;

  SearchResult(this.document, this.score);
}

// Alternative: Create a standalone function if you prefer
Future<void> syncStoreProductsByIds(
  BuildContext context,
  String storeId,
  List<String> productDocIds,
) async {
  try {
    print('🔄 Starting synchronization by product IDs...');
    print('🏪 Store ID: $storeId');
    print('🧾 Provided product IDs: $productDocIds');

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    int updatedCount = 0;

    for (String storeProductId in productDocIds) {
      final storeDocRef = firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(storeProductId);

      final storeDoc = await storeDocRef.get();

      if (!storeDoc.exists) {
        print('⚠️ Store product not found: $storeProductId');
        continue;
      }

      final storeProduct = storeDoc.data()!;
      final mainProductId = storeProduct['productId'];

      print(
          '🔍 Processing store product: ${storeProduct['name']} (ID: $mainProductId)');

      final mainProductDoc =
          await firestore.collection('products').doc(mainProductId).get();

      if (mainProductDoc.exists) {
        final mainProduct = mainProductDoc.data()!;

        final updatedData = {
          ...storeProduct,
          'name': mainProduct['name'],
          'classification': mainProduct['classification'],
          'imageUrl': mainProduct['imageUrl'],
          'manufacturer': mainProduct['manufacturer'],
          'size': mainProduct['size'],
          'package': mainProduct['package'],
          'note': mainProduct['note'],
        };

        batch.update(storeDocRef, updatedData);
        updatedCount++;
        print('📝 Prepared update for product');
      } else {
        print('⚠️ Product not found in main collection: $mainProductId');
      }
    }

    print('💾 Saving batch updates...');
    await batch.commit();

    print('✅ Successfully updated $updatedCount products');
  } catch (e) {
    print('❌ Error in syncStoreProductsByIds: $e');
  }
}
