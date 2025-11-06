// lib/data/repositories/supplier_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goods_admin/data/models/location_model.dart';

class SupplierRepository {
  final FirebaseFirestore _firestore;

  SupplierRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<SupplierModel>> getAllSuppliers() async {
    try {
      final snapshot = await _firestore.collection('suppliers').get();

      return snapshot.docs
          .where((doc) => _isValidSupplier(doc.id, doc.data()))
          .map((doc) => SupplierModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب بيانات الموردين: $e');
    }
  }

  bool _isValidSupplier(String id, Map<String, dynamic> data) {
    final hasPhone = data.containsKey('phoneNumber') &&
        data['phoneNumber'] != null &&
        (data['phoneNumber'] as String).trim().isNotEmpty;

    return id.length <= 11 && hasPhone;
  }

  Future<void> addCoverageArea(
      String supplierId, CoverageAreaModel coverage) async {
    try {
      await _firestore.collection('suppliers').doc(supplierId).update({
        'coverageAreas': FieldValue.arrayUnion([coverage.toJson()])
      });
    } catch (e) {
      throw Exception('فشل في إضافة منطقة التغطية: $e');
    }
  }

  Future<void> removeCoverageArea(
      String supplierId, CoverageAreaModel coverage) async {
    try {
      await _firestore.collection('suppliers').doc(supplierId).update({
        'coverageAreas': FieldValue.arrayRemove([coverage.toJson()])
      });
    } catch (e) {
      throw Exception('فشل في حذف منطقة التغطية: $e');
    }
  }

  Future<SupplierModel?> getSupplier(String supplierId) async {
    try {
      final doc =
          await _firestore.collection('suppliers').doc(supplierId).get();

      if (!doc.exists) return null;

      return SupplierModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('فشل في جلب بيانات المورد: $e');
    }
  }

  Future<void> updateCoverageAreas(
      String supplierId, List<CoverageAreaModel> coverages) async {
    try {
      await _firestore.collection('suppliers').doc(supplierId).update({
        'coverageAreas': coverages.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث مناطق التغطية: $e');
    }
  }
}

// lib/data/repositories/location_repository.dart

class LocationRepository {
  final FirebaseFirestore _firestore;

  LocationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<String>> getGovernments() async {
    try {
      final snapshot = await _firestore
          .collection('admin_data')
          .doc('locations')
          .collection('governments')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList()..sort();
    } catch (e) {
      throw Exception('فشل في جلب المحافظات: $e');
    }
  }

  Future<List<String>> getCities(String government) async {
    try {
      final snapshot = await _firestore
          .collection('admin_data')
          .doc('locations')
          .collection('governments')
          .doc(government)
          .collection('cities')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList()..sort();
    } catch (e) {
      throw Exception('فشل في جلب المدن: $e');
    }
  }
}
