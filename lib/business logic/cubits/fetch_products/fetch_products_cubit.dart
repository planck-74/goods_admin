import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:meta/meta.dart';

part 'fetch_products_state.dart';

class FetchProductsCubit extends Cubit<FetchProductsState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FetchProductsCubit() : super(FetchProductsInitial());
  Future<void> fetchProducts() async {
    try {
      emit(FetchProductsLoading());
      QuerySnapshot snapshot = await firestore.collection('products').get();

      List<Product> products = snapshot.docs
          .map((e) => Product.fromMap(e.data() as Map<String, dynamic>))
          .toList();
      emit(FetchProductsLoaded(products));
    } catch (e) {
      emit(FetchProductsError(e.toString()));
    }
  }
}
