import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  FirestoreServicesCubit() : super(FirestoreServicesInitial());

  Future<void> addProduct(
      BuildContext context, Product product, String fileName) async {
    emit(FirestoreServicesLoading());

    try {
      await db
          .collection(collectionPath)
          .doc(product.productId)
          .set(product.toMap());

      showSuccessMessage(context, 'تمت إضافة المنتج بنجاح');

      emit(FirestoreServicesLoaded());
    } catch (e) {
      print('Error adding product: $e');
      emit(FirestoreServicesError('حدث خطأ أثناء إضافة المنتج: $e'));
    }
  }

  Future<List<QueryDocumentSnapshot>> searchProductsByName(
      String searchQuery) async {
    CollectionReference productsRef =
        FirebaseFirestore.instance.collection('products');

    QuerySnapshot querySnapshot = await productsRef
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff')
        .get();

    return querySnapshot.docs;
  }

  Future<void> getProductsClassifications() async {
    CollectionReference adminData = db.collection('admin_data');

    try {
      emit(FirestoreServicesLoading());
      // جلب البيانات من المستندات وتحديث الخرائط
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
      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء تحديث المنتج: $e'));
    }
  }

  // New deleteProduct method
  Future<void> deleteProduct(BuildContext context, Product product) async {
    emit(FirestoreServicesLoading());
    try {
      await db.collection(collectionPath).doc(product.productId).delete();
      showSuccessMessage(context, 'تم حذف المنتج بنجاح');
      emit(FirestoreServicesLoaded());
    } catch (e) {
      emit(FirestoreServicesError('حدث خطأ أثناء حذف المنتج: $e'));
    }
  }
}
