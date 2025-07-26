import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:image_picker/image_picker.dart';

/// Helper function to upload an image file to Firebase Storage and return the download URL.
Future<String?> uploadImage(File imageFile, String productId) async {
  try {
    final storageRef =
        FirebaseStorage.instance.ref().child('product_images/$productId.png');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print("Error uploading image: $e");
    return null;
  }
}

class EditProducts extends StatefulWidget {
  const EditProducts({super.key});

  @override
  State<EditProducts> createState() => _EditProductsState();
}

class _EditProductsState extends State<EditProducts> {
  final TextEditingController _searchController = TextEditingController();
  List<Product>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Safe to use context here as the widget is still active.
    context.read<FetchProductsCubit>().fetchProducts();
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });

    try {
      List<QueryDocumentSnapshot> docs = await context
          .read<FirestoreServicesCubit>()
          .searchProductsByName(query);
      List<Product> products = docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      setState(() {
        _searchResults = products;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint("Error searching products: $e");
    }
  }

  Future<void> _refreshSearchResults() async {
    if (_searchController.text.isNotEmpty) {
      await _searchProducts(_searchController.text);
    } else {
      context.read<FetchProductsCubit>().fetchProducts();
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close the dialog
              // Pass both context and product as parameters.
              await context
                  .read<FirestoreServicesCubit>()
                  .deleteProduct(context, product);
              await _refreshSearchResults();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('تم حذف المنتج "${product.name}" بنجاح')),
              );
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        cursorHeight: 25,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث عن منتج',
          hintStyle: TextStyle(color: kDarkBlueColor, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onChanged: (value) {
          _searchProducts(value);
        },
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        Product product = products[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
          child: GestureDetector(
            onTap: () {
              showEditProductSheet(context, product);
            },
            child: _buildProductCard(product),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 120,
              width: 1,
              color: kDarkBlueColor,
            ),
          ),
          Expanded(child: _buildProductDetails(product)),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmationDialog(context, product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(product.name),
        const SizedBox(height: 5),
        Text('شركة: ${product.manufacturer}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        if (product.size?.isNotEmpty ?? false)
          Text('الحجم: ${product.size}', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        Text('العبوة: ${product.package}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        Text('التصنيف: ${product.classification}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        Text('عدد البيعات: ${product.salesCount}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        if (product.note?.isNotEmpty ?? false)
          Text('ملحوظة: ${product.note}', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Text('المنتجات', style: TextStyle(color: kWhiteColor)),
            const SizedBox(width: 10),
            Expanded(child: _buildSearchField()),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults != null
                    ? RefreshIndicator(
                        onRefresh: _refreshSearchResults,
                        child: _buildProductList(_searchResults!),
                      )
                    : BlocBuilder<FetchProductsCubit, FetchProductsState>(
                        builder: (context, state) {
                          if (state is FetchProductsLoading) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: kPrimaryColor));
                          } else if (state is FetchProductsLoaded) {
                            return RefreshIndicator(
                              onRefresh: _refreshSearchResults,
                              child: _buildProductList(state.products),
                            );
                          } else if (state is FetchProductsError) {
                            return Center(child: Text(state.message));
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// A bottom sheet to edit product details with image change feature.
void showEditProductSheet(BuildContext context, Product product) {
  // Controllers for text fields (initialized with product values)
  final TextEditingController nameController =
      TextEditingController(text: product.name);
  final TextEditingController manufacturerController =
      TextEditingController(text: product.manufacturer);
  final TextEditingController sizeController =
      TextEditingController(text: product.size);
  final TextEditingController packageController =
      TextEditingController(text: product.package);
  final TextEditingController classificationController =
      TextEditingController(text: product.classification);
  final TextEditingController noteController =
      TextEditingController(text: product.note);
  final TextEditingController salesCountController =
      TextEditingController(text: product.salesCount.toString());

  // Local variables to hold image file and new URL.
  File? selectedImage;
  String? newImageUrl;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content pushed down to make space for the avatar.
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 100,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "اسم المنتج",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: manufacturerController,
                        decoration: const InputDecoration(
                          labelText: "الشركة المصنعة",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: "الحجم",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: packageController,
                        decoration: const InputDecoration(
                          labelText: "العبوة",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: classificationController,
                        decoration: const InputDecoration(
                          labelText: "التصنيف",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: "ملاحظات",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: salesCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "عدد المبيعات",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor),
                            onPressed: () async {
                              if (selectedImage != null) {
                                newImageUrl = await uploadImage(
                                    selectedImage!, product.productId);
                              }

                              Product updatedProduct = Product(
                                name: nameController.text,
                                manufacturer: manufacturerController.text,
                                size: sizeController.text,
                                package: packageController.text,
                                classification: classificationController.text,
                                note: noteController.text,
                                salesCount:
                                    int.tryParse(salesCountController.text) ??
                                        product.salesCount,
                                imageUrl: newImageUrl ?? product.imageUrl,
                                productId: product.productId,
                              );
                              context
                                  .read<FirestoreServicesCubit>()
                                  .updateProduct(context, updatedProduct);
                              Navigator.pop(context);
                            },
                            child: const Text("حفظ",
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white),
                            child: const Text("إلغاء"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -72,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final imageFile = File(pickedFile.path);
                      if (pickedFile.path.toLowerCase().endsWith('.png')) {
                        setState(() {
                          selectedImage = imageFile;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يجب اختيار صورة بامتداد .png فقط'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: CircleAvatar(
                    radius: 72,
                    backgroundColor: kPrimaryColor,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (newImageUrl ?? product.imageUrl).isNotEmpty
                              ? NetworkImage(newImageUrl ?? product.imageUrl)
                              : null,
                      child: (selectedImage == null &&
                              (newImageUrl ?? product.imageUrl).isEmpty)
                          ? const Icon(
                              Icons.shopping_bag_rounded,
                              color: kPrimaryColor,
                              size: 64,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              // A title above the avatar.
              const Positioned(
                top: -130,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "تعديل المنتج",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
