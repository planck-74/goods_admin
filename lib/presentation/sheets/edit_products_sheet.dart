import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/services/storage_services.dart';
import 'package:image_picker/image_picker.dart';

void showEditProductSheet(BuildContext context, Product product) {
  final TextEditingController nameController =
      TextEditingController(text: product.name);
  final TextEditingController sizeController =
      TextEditingController(text: product.size);
  final TextEditingController packageController =
      TextEditingController(text: product.package);
  final TextEditingController noteController =
      TextEditingController(text: product.note);

  // Find the correct keys for current values
  String? selectedManufacturer;
  String? selectedClassification;
  String? updatedImageUrl = product.imageUrl;
  File? selectedImage;

  // Load classifications data first
  context.read<GetClassificationsCubit>().getProductsClassifications();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Stack(
          clipBehavior: Clip.none,
          children: [
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

                    // Product Name Field
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: nameController,
                        maxLength: 50,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Size Field
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'الحجم',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Package Field
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: packageController,
                        decoration: const InputDecoration(
                          labelText: 'العبوة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Classification Dropdown
                    BlocBuilder<GetClassificationsCubit,
                        GetClassificationsState>(
                      builder: (context, state) {
                        if (state is GetClassificationsSuccess) {
                          final cubit = context.read<GetClassificationsCubit>();

                          // Find current classification value or set it initially
                          selectedClassification ??= product.classification;

                          // Ensure the current value exists in the dropdown options
                          String? validInitialSelection;
                          final classificationExists = cubit
                              .classification.values
                              .contains(selectedClassification);

                          if (classificationExists) {
                            validInitialSelection = selectedClassification;
                          }

                          return DropdownMenu(
                            width: screenWidth * 0.9,
                            initialSelection: validInitialSelection,
                            dropdownMenuEntries: cubit.classification.entries
                                .map((entry) => DropdownMenuEntry<String>(
                                      value: entry.value,
                                      label: entry.value,
                                    ))
                                .toList(),
                            label: const Text('تصنيف المنتج'),
                            onSelected: (value) {
                              setState(() {
                                selectedClassification = value;
                              });
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Manufacturer Dropdown
                    BlocBuilder<GetClassificationsCubit,
                        GetClassificationsState>(
                      builder: (context, state) {
                        if (state is GetClassificationsSuccess) {
                          final cubit = context.read<GetClassificationsCubit>();

                          // Find current manufacturer key or set it initially
                          if (selectedManufacturer == null) {
                            // Find the key for current manufacturer value
                            final manufacturerEntry = cubit.manufacturer.entries
                                .where((entry) =>
                                    entry.key == product.manufacturer ||
                                    entry.value == product.manufacturer)
                                .firstOrNull;
                            selectedManufacturer = manufacturerEntry?.key;
                          }

                          // Ensure the current value exists in the dropdown options
                          String? validInitialSelection;
                          if (selectedManufacturer != null &&
                              cubit.manufacturer
                                  .containsKey(selectedManufacturer)) {
                            validInitialSelection = selectedManufacturer;
                          }

                          return DropdownMenu(
                            width: screenWidth * 0.9,
                            initialSelection: validInitialSelection,
                            dropdownMenuEntries: cubit.manufacturer.entries
                                .map((entry) => DropdownMenuEntry<String>(
                                      value: entry.key,
                                      label: entry.value,
                                    ))
                                .toList(),
                            label: const Text('الشركة المصنعة'),
                            onSelected: (value) {
                              setState(() {
                                selectedManufacturer = value;
                              });
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Notes Field
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: noteController,
                        maxLength: 100,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor),
                          onPressed: () async {
                            // Upload new image if selected
                            if (selectedImage != null) {
                              final fileName = product
                                  .productId; // Use productId for consistency

                              // Delete old image if exists and has valid URL
                              if (product.imageUrl.isNotEmpty &&
                                  product.imageUrl.contains('firebase')) {
                                try {
                                  await StorageService()
                                      .deleteOldImage(product.imageUrl);
                                  print('Old image deleted successfully');
                                } catch (e) {
                                  print(
                                      'Error deleting old image (might not exist): $e');
                                  // Continue anyway - it's not critical if old image doesn't exist
                                }
                              }

                              // Upload new image
                              try {
                                updatedImageUrl = await StorageService()
                                    .uploadImage(
                                        context, selectedImage!, fileName);
                                print('New image uploaded successfully');
                              } catch (e) {
                                print('Error uploading new image: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('فشل في رفع الصورة: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return; // Don't continue if upload failed
                              }
                            }

                            Product updatedProduct = Product(
                              name: nameController.text,
                              manufacturer: selectedManufacturer ?? '',
                              size: sizeController.text,
                              package: packageController.text,
                              classification: selectedClassification ?? '',
                              note: noteController.text,
                              salesCount: product
                                  .salesCount, // Keep original sales count
                              imageUrl: updatedImageUrl ?? product.imageUrl,
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

            // Avatar with image - Clickable to change image
            Positioned(
              top: -72,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );

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
                  backgroundColor: primaryColor,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white,
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : (product.imageUrl.isNotEmpty
                            ? NetworkImage(product.imageUrl)
                            : null),
                    child: (selectedImage == null && product.imageUrl.isEmpty)
                        ? const Icon(Icons.shopping_bag_rounded,
                            color: primaryColor, size: 64)
                        : null,
                  ),
                ),
              ),
            ),

            // Title
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
                      color: primaryColor),
                ),
              ),
            ),

            // Info text about image editing
            const Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "اضغط على الصورة لتعديلها",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
