import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';

class ManufacturerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _manufacturersRef => _firestore
      .collection('admin_data')
      .doc('manufacturers')
      .collection('manufacturers');

  Stream<List<Manufacturer>> getManufacturers() {
    return _manufacturersRef.orderBy('number').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Manufacturer.fromFirestore(doc)).toList());
  }

  Future<Manufacturer> addManufacturer(Manufacturer manufacturer) async {
    final docRef = _manufacturersRef.doc(manufacturer.name);
    await docRef.set(manufacturer.toMap());
    // Return a new Manufacturer with the name as the ID
    return manufacturer.copyWith(id: manufacturer.name);
  }

  Future<void> updateManufacturer(Manufacturer manufacturer) async {
    await _manufacturersRef.doc(manufacturer.name).update(manufacturer.toMap());
  }

  Future<void> deleteManufacturer(String id) async {
    await _manufacturersRef.doc(id).delete();
  }

  Future<String> uploadImage(File imageFile) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('manufacturers/$fileName');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> updateProductAssignments(
      String manufacturerId, List<String> productIds) async {
    await _manufacturersRef.doc(manufacturerId).update({
      'productsIds': productIds,
    });
  }

  Future<void> reorderManufacturers(List<Manufacturer> manufacturers) async {
    final batch = _firestore.batch();
    for (int i = 0; i < manufacturers.length; i++) {
      batch.update(_manufacturersRef.doc(manufacturers[i].id), {'number': i});
    }
    await batch.commit();
  }
}
