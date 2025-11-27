import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/fetch_products/fetch_products_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_state.dart';
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

  String? selectedManufacturer;
  String? selectedClassification;
  String? updatedImageUrl = product.imageUrl;
  File? selectedImage;
  bool isSaving = false;

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
                        enabled: !isSaving,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Size Field
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: sizeController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'الحجم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Package Field
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: packageController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'العبوة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2, size: 20),
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
                          selectedClassification ??= product.classification;

                          String? validInitialSelection;
                          final classificationExists = cubit
                              .classification.values
                              .contains(selectedClassification);

                          if (classificationExists) {
                            validInitialSelection = selectedClassification;
                          }

                          return DropdownMenu(
                            width: screenWidth * 0.9,
                            enabled: !isSaving,
                            initialSelection: validInitialSelection,
                            dropdownMenuEntries: cubit.classification.entries
                                .map((entry) => DropdownMenuEntry<String>(
                                      value: entry.value,
                                      label: entry.value,
                                    ))
                                .toList(),
                            label: const Text('تصنيف المنتج'),
                            leadingIcon: const Icon(Icons.category, size: 20),
                            onSelected: (value) {
                              setState(() {
                                selectedClassification = value;
                              });
                            },
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Manufacturer Dropdown
                    BlocBuilder<GetClassificationsCubit,
                        GetClassificationsState>(
                      builder: (context, state) {
                        if (state is GetClassificationsSuccess) {
                          final cubit = context.read<GetClassificationsCubit>();

                          if (selectedManufacturer == null) {
                            final manufacturerEntry = cubit.manufacturer.entries
                                .where((entry) =>
                                    entry.key == product.manufacturer ||
                                    entry.value == product.manufacturer)
                                .firstOrNull;
                            selectedManufacturer = manufacturerEntry?.key;
                          }

                          String? validInitialSelection;
                          if (selectedManufacturer != null &&
                              cubit.manufacturer
                                  .containsKey(selectedManufacturer)) {
                            validInitialSelection = selectedManufacturer;
                          }

                          return DropdownMenu(
                            width: screenWidth * 0.9,
                            enabled: !isSaving,
                            initialSelection: validInitialSelection,
                            dropdownMenuEntries: cubit.manufacturer.entries
                                .map((entry) => DropdownMenuEntry<String>(
                                      value: entry.key,
                                      label: entry.value,
                                    ))
                                .toList(),
                            label: const Text('الشركة المصنعة'),
                            leadingIcon: const Icon(Icons.business, size: 20),
                            onSelected: (value) {
                              setState(() {
                                selectedManufacturer = value;
                              });
                            },
                          );
                        }
                        return const CircularProgressIndicator();
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
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons with BlocConsumer
                    BlocConsumer<FirestoreServicesCubit,
                        FirestoreServicesState>(
                      listener: (context, state) {
                        if (state is FirestoreServicesLoaded) {
                          // Success - show message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم التحديث بنجاح!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (state is FirestoreServicesError) {
                          // Error - show message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state is FirestoreServicesLoading;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: (isSaving || isLoading)
                                    ? null
                                    : () async {
                                        setState(() {
                                          isSaving = true;
                                        });

                                        try {
                                          // Upload new image if selected
                                          if (selectedImage != null) {
                                            final fileName = product.productId;

                                            if (product.imageUrl.isNotEmpty &&
                                                product.imageUrl
                                                    .contains('firebase')) {
                                              try {
                                                await StorageService()
                                                    .deleteOldImage(
                                                        product.imageUrl);
                                              } catch (e) {
                                                debugPrint(
                                                    'Error deleting old image: $e');
                                              }
                                            }

                                            try {
                                              updatedImageUrl =
                                                  await StorageService()
                                                      .uploadImage(
                                                          context,
                                                          selectedImage!,
                                                          fileName);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'فشل في رفع الصورة: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                              setState(() {
                                                isSaving = false;
                                              });
                                              return;
                                            }
                                          }

                                          // Create updated product
                                          Product updatedProduct = Product(
                                            name: nameController.text,
                                            manufacturer:
                                                selectedManufacturer ?? '',
                                            size: sizeController.text,
                                            package: packageController.text,
                                            classification:
                                                selectedClassification ?? '',
                                            note: noteController.text,
                                            salesCount: product.salesCount,
                                            imageUrl: updatedImageUrl ??
                                                product.imageUrl,
                                            productId: product.productId,
                                          );

                                          if (context.mounted) {
                                            // Get cubits and close sheet BEFORE calling update
                                            final firestoreServicesCubit =
                                                context.read<
                                                    FirestoreServicesCubit>();
                                            final fetchProductsCubit = context
                                                .read<FetchProductsCubit>();

                                            // Close the sheet
                                            Navigator.pop(context);

                                            // Call update - the BlocConsumer will handle the dialog
                                            await firestoreServicesCubit
                                                .updateProduct(
                                              context,
                                              updatedProduct,
                                              fetchProductsCubit,
                                            );
                                          }
                                        } catch (e, stackTrace) {
                                          debugPrint(
                                              'Error in save operation: $e');
                                          debugPrint(
                                              'Stack trace: $stackTrace');

                                          setState(() {
                                            isSaving = false;
                                          });

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('حدث خطأ: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                icon: (isSaving || isLoading)
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.save,
                                        color: Colors.white),
                                label: Text(
                                  (isSaving || isLoading)
                                      ? "جاري الحفظ..."
                                      : "حفظ",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (isSaving || isLoading)
                                    ? null
                                    : () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.close,
                                    color: darkBlueColor),
                                label: const Text(
                                  "إلغاء",
                                  style: TextStyle(color: darkBlueColor),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Avatar with image
            Positioned(
              top: -72,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: isSaving
                    ? null
                    : () async {
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
                                content:
                                    Text('يجب اختيار صورة بامتداد .png فقط'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
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
                        child:
                            (selectedImage == null && product.imageUrl.isEmpty)
                                ? const Icon(Icons.shopping_bag_rounded,
                                    color: primaryColor, size: 64)
                                : null,
                      ),
                    ),
                    if (!isSaving)
                      Positioned(
                        bottom: 0,
                        right: MediaQuery.of(context).size.width / 2 - 90,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Title
            Positioned(
              top: -130,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "تعديل المنتج",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
