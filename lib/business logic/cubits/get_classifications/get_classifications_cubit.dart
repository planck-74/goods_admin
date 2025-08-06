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

  // Cache management
  DateTime? _lastFetched;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  GetClassificationsCubit() : super(GetClassificationsInitial());

  // Check if data is cached and still valid
  bool get _isCacheValid {
    if (_lastFetched == null) return false;
    return DateTime.now().difference(_lastFetched!) < _cacheTimeout;
  }

  // Check if data is loaded
  bool get isDataLoaded {
    return classification.isNotEmpty &&
        manufacturer.isNotEmpty &&
        packageType.isNotEmpty &&
        packageUnit.isNotEmpty &&
        sizeUnit.isNotEmpty;
  }

  Future<void> getProductsClassifications({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && isDataLoaded) {
      emit(GetClassificationsSuccess());
      return;
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    CollectionReference adminData = db.collection('admin_data');

    try {
      emit(GetClassificationsLoading());

      // Clear existing data before fetching new
      _clearData();

      // Parallel fetch for better performance
      final futures = await Future.wait([
        adminData.doc('classification').get(),
        adminData.doc('manufacturer').get(),
        adminData.doc('package_type').get(),
        adminData.doc('package_unit').get(),
        adminData.doc('size_unit').get(),
      ]);

      // Process results
      final classificationsDoc = futures[0];
      final manufacturerDoc = futures[1];
      final packageTypeDoc = futures[2];
      final packageUnitDoc = futures[3];
      final sizeUnitDoc = futures[4];

      // Safely add data with null checks
      _safelyAddData(classification, classificationsDoc);
      _safelyAddData(manufacturer, manufacturerDoc);
      _safelyAddData(packageType, packageTypeDoc);
      _safelyAddData(packageUnit, packageUnitDoc);
      _safelyAddData(sizeUnit, sizeUnitDoc);

      _lastFetched = DateTime.now();
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('حدث خطأ أثناء جلب التصنيفات: $e'));
    }
  }

  // Safely add data from document to map
  void _safelyAddData(Map<String, String> targetMap, DocumentSnapshot doc) {
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      for (final entry in data.entries) {
        if (entry.value is String) {
          targetMap[entry.key] = entry.value;
        }
      }
    }
  }

  // Clear all data
  void _clearData() {
    classification.clear();
    manufacturer.clear();
    packageType.clear();
    packageUnit.clear();
    sizeUnit.clear();
  }

  // Add new classification
  Future<void> addClassification(String key, String value) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('classification').update({
        key: value,
      });

      classification[key] = value;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في إضافة التصنيف: $e'));
    }
  }

  // Add new manufacturer
  Future<void> addManufacturer(String key, String value) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('manufacturer').update({
        key: value,
      });

      manufacturer[key] = value;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في إضافة الشركة المصنعة: $e'));
    }
  }

  // Add new package type
  Future<void> addPackageType(String key, String value) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('package_type').update({
        key: value,
      });

      packageType[key] = value;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في إضافة نوع العبوة: $e'));
    }
  }

  // Add new package unit
  Future<void> addPackageUnit(String key, String value) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('package_unit').update({
        key: value,
      });

      packageUnit[key] = value;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في إضافة وحدة العبوة: $e'));
    }
  }

  // Add new size unit
  Future<void> addSizeUnit(String key, String value) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('size_unit').update({
        key: value,
      });

      sizeUnit[key] = value;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في إضافة وحدة الحجم: $e'));
    }
  }

  // Delete classification
  Future<void> deleteClassification(String key) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('classification').update({
        key: FieldValue.delete(),
      });

      classification.remove(key);
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في حذف التصنيف: $e'));
    }
  }

  // Delete manufacturer
  Future<void> deleteManufacturer(String key) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('manufacturer').update({
        key: FieldValue.delete(),
      });

      manufacturer.remove(key);
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في حذف الشركة المصنعة: $e'));
    }
  }

  // Delete package type
  Future<void> deletePackageType(String key) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('package_type').update({
        key: FieldValue.delete(),
      });

      packageType.remove(key);
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في حذف نوع العبوة: $e'));
    }
  }

  // Delete package unit
  Future<void> deletePackageUnit(String key) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('package_unit').update({
        key: FieldValue.delete(),
      });

      packageUnit.remove(key);
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في حذف وحدة العبوة: $e'));
    }
  }

  // Delete size unit
  Future<void> deleteSizeUnit(String key) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('size_unit').update({
        key: FieldValue.delete(),
      });

      sizeUnit.remove(key);
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في حذف وحدة الحجم: $e'));
    }
  }

  // Update classification
  Future<void> updateClassification(String key, String newValue) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('classification').update({
        key: newValue,
      });

      classification[key] = newValue;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في تحديث التصنيف: $e'));
    }
  }

  // Update manufacturer
  Future<void> updateManufacturer(String key, String newValue) async {
    try {
      emit(GetClassificationsLoading());

      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('admin_data').doc('manufacturer').update({
        key: newValue,
      });

      manufacturer[key] = newValue;
      emit(GetClassificationsSuccess());
    } catch (e) {
      emit(GetClassificationsError('فشل في تحديث الشركة المصنعة: $e'));
    }
  }

  // Get sorted lists for UI
  List<MapEntry<String, String>> get sortedClassifications {
    final list = classification.entries.toList();
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  List<MapEntry<String, String>> get sortedManufacturers {
    final list = manufacturer.entries.toList();
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  List<MapEntry<String, String>> get sortedPackageTypes {
    final list = packageType.entries.toList();
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  List<MapEntry<String, String>> get sortedPackageUnits {
    final list = packageUnit.entries.toList();
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  List<MapEntry<String, String>> get sortedSizeUnits {
    final list = sizeUnit.entries.toList();
    list.sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  // Clear cache manually
  void clearCache() {
    _lastFetched = null;
    _clearData();
  }

  // Get cache info for debugging
  Map<String, dynamic> get cacheInfo {
    return {
      'lastFetched': _lastFetched?.toIso8601String(),
      'isValid': _isCacheValid,
      'isDataLoaded': isDataLoaded,
      'classificationsCount': classification.length,
      'manufacturersCount': manufacturer.length,
      'packageTypesCount': packageType.length,
      'packageUnitsCount': packageUnit.length,
      'sizeUnitsCount': sizeUnit.length,
    };
  }
}
