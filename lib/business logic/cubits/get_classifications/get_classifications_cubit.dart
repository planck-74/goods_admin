import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

part 'get_classifications_state.dart';

class GetClassificationsCubit extends Cubit<GetClassificationsState> {
  final Map<String, String> classification = {};
  final Map<String, String> manufacturer = {};
  final Map<String, String> packageType = {};
  final Map<String, String> packageUnit = {};
  final Map<String, String> sizeUnit = {};
  GetClassificationsCubit() : super(GetClassificationsInitial());

  Future<void> getProductsClassifications() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference adminData = db.collection('admin_data');

    try {
      emit(GetClassificationsLoading());
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

      // تحديث الخرائط إذا كانت البيانات موجودة
      classification
          .addAll(Map<String, String>.from(classificationsDoc.data() as Map));
      manufacturer
          .addAll(Map<String, String>.from(manufacturerDoc.data() as Map));
      packageType
          .addAll(Map<String, String>.from(packageTypeDoc.data() as Map));
      packageUnit
          .addAll(Map<String, String>.from(packageUnitDoc.data() as Map));
      sizeUnit.addAll(Map<String, String>.from(sizeUnitDoc.data() as Map));
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('حدث خطأ أثناء جلب التصنيفات: $e'));
    }
  }
}
