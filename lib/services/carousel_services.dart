import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:goods_admin/data/models/carousel_image_model.dart';
import 'package:image_picker/image_picker.dart';

class CarouselService {
  static const String _collectionName = 'admin_data';
  static const String _subCollectionName = 'carousel_images';
  static const String _storagePath = 'carousel_images';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get carousel images stream
  Stream<List<CarouselImageModel>> getCarouselImages() {
    return _firestore
        .collection(_collectionName)
        .doc('carousel')
        .collection(_subCollectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CarouselImageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('$_storagePath/$fileName');

    final UploadTask uploadTask = ref.putFile(imageFile);
    final TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // Add new carousel image
  Future<void> addCarouselImage(File imageFile, int order) async {
    try {
      final String imageUrl = await _uploadImage(imageFile);

      final CarouselImageModel newImage = CarouselImageModel(
        id: '',
        imageUrl: imageUrl,
        order: order,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc('carousel')
          .collection(_subCollectionName)
          .add(newImage.toMap());
    } catch (e) {
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  // Delete carousel image
  Future<void> deleteCarouselImage(String imageId, String imageUrl) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection(_collectionName)
          .doc('carousel')
          .collection(_subCollectionName)
          .doc(imageId)
          .delete();

      // Delete from Storage
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      throw Exception('فشل في حذف الصورة: $e');
    }
  }

  // Update image order
  Future<void> updateImageOrder(String imageId, int newOrder) async {
    await _firestore
        .collection(_collectionName)
        .doc('carousel')
        .collection(_subCollectionName)
        .doc(imageId)
        .update({'order': newOrder});
  }

  // Pick image from gallery
  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    return image != null ? File(image.path) : null;
  }
}
