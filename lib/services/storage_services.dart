import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String?> uploadImage(context, File imageFile, String fileName) async {
    try {
      var uuid = const Uuid();
      String uniqueName =
          '${fileName}_${uuid.v1()}_${DateTime.now().millisecondsSinceEpoch}';

      Reference ref = storage.ref('products_images').child(uniqueName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteOldImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
        debugPrint("Old image deleted successfully");
      }
    } catch (e) {
      debugPrint("Error deleting old image: $e");
    }
  }
}
