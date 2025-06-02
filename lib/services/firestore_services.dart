// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:goods_admin/business%20logic/cubits/image_picker_cubit/image_cubit.dart';
// import 'package:goods_admin/data/models/product_model.dart';
// import 'package:goods_admin/services/storage_services.dart';
// import 'package:image_picker/image_picker.dart';

// class FirestoreService {
//   final FirebaseFirestore db = FirebaseFirestore.instance;

//   final String collectionPath = 'products';

//   Future<void> addProduct(
//       BuildContext context, Product product, fileName) async {
//     XFile? image = context.read<ImageCubit>().image;
//     File? pickedImage;

//     if (image != null) {
//       pickedImage = File(image.path);
//     }

//     if (pickedImage != null) {
//       try {
//         String? imageUrl =
//             await StorageService().uploadImage(context, pickedImage, fileName);

//         if (imageUrl != null) {
//           product.imageUrl = imageUrl;

//           await db.collection('products').add(product.toMap());
//           print('Product added successfully');
//         } else {
//           print('Image upload failed');
//         }
//       } catch (e) {
//         print('Error adding product: $e');
//       }
//     } else {
//       print('No image selected');
//     }
//   }

//   Future<List<Product>> getProducts() async {
//     try {
//       QuerySnapshot querySnapshot = await db.collection(collectionPath).get();
//       return querySnapshot.docs
//           .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       print('Error fetching products: $e');
//       return [];
//     }
//   }

//   Future<Product?> getProductById(String id) async {
//     try {
//       DocumentSnapshot docSnapshot =
//           await db.collection(collectionPath).doc(id).get();
//       if (docSnapshot.exists) {
//         return Product.fromMap(docSnapshot.data() as Map<String, dynamic>);
//       } else {
//         print('Product not found');
//         return null;
//       }
//     } catch (e) {
//       print('Error fetching product: $e');
//       return null;
//     }
//   }

//   Future<void> updateProduct(String id, Product updatedProduct) async {
//     try {
//       await db
//           .collection(collectionPath)
//           .doc(id)
//           .update(updatedProduct.toMap());
//       print('Product updated successfully');
//     } catch (e) {
//       print('Error updating product: $e');
//     }
//   }

//   Future<void> deleteProduct(String id) async {
//     try {
//       await db.collection(collectionPath).doc(id).delete();
//       print('Product deleted successfully');
//     } catch (e) {
//       print('Error deleting product: $e');
//     }
//   }
// }
