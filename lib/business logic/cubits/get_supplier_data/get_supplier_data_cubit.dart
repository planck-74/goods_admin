import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goods_admin/business%20logic/cubits/get_supplier_data/get_supplier_data_state.dart';

class GetSupplierDataCubit extends Cubit<GetSupplierDataState> {
  List<Map<String, dynamic>> suppliers = [];

  GetSupplierDataCubit() : super(GetSupplierDataInitial());

  Future<void> getSupplierData() async {
    emit(GetSupplierDataLoading());
    print('🔍 بدء جلب بيانات الموردين...');

    final collectionRef = FirebaseFirestore.instance.collection('suppliers');
    print('📂 الوصول إلى كولكشن: ${collectionRef.path}');

    final querySnapshot = await collectionRef.get();
    print('📊 تم جلب ${querySnapshot.docs.length} مستند من Firestore');

    suppliers = querySnapshot.docs.where((doc) {
      final data = doc.data();
      final hasPhone = data.containsKey('phoneNumber') &&
          data['phoneNumber'] != null &&
          (data['phoneNumber'] as String).trim().isNotEmpty;

      final isValid = doc.id.length <= 11 && hasPhone;
      print(
          '🧾 مورد ID=${doc.id}, hasPhone=$hasPhone → ${(isValid ? "✔️ مقبول" : "❌ مرفوض")}');

      return isValid;
    }).map((doc) {
      final data = doc.data();
      print('✅ إضافة المورد: ${data['businessName']}');
      return {
        'id': doc.id,
        'businessName': data['businessName'] ?? '',
        'imageUrl': data['imageUrl'] ?? '',
        'town': data['town'] ?? '',
        'government': data['government'] ?? '',
        'phoneNumber': data['phoneNumber'] ?? '',
        'minOrderPrice': data['minOrderPrice'] ?? 3000,
        'minOrderProducts': data['minOrderProducts'] ?? 5,
      };
    }).toList();

    print('📦 عدد الموردين النهائي بعد الفلترة: ${suppliers.length}');
    emit(GetSupplierDataSuccess(suppliers));
  }
}
