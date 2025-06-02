import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String?> uploadImage(context, File imageFile, String fileName) async {
    try {
      var uuid = const Uuid();
      String uniqueName =
          '${fileName}_${uuid.v1()}_${DateTime.now().millisecondsSinceEpoch}';

      Reference ref = storage.ref('product_images').child(uniqueName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
