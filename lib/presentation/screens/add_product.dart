import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/controller/controllers_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/firestore_services_cubit/firestore_services_cubit.dart';
import 'package:goods_admin/business%20logic/cubits/get_classifications/get_classifications_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/data/models/product_model.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_buttons/custom_circular_eleveted_button.dart';
import 'package:goods_admin/services/storage_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  File? selectedImage;
  String? imageUrl;
  @override
  void initState() {
    super.initState();
    context.read<GetClassificationsCubit>().getProductsClassifications();
  }

  void _clearForm() {
    setState(() {
      selectedImage = null;
      imageUrl = null;
      context.read<ControllersCubit>().name.clear();
      context.read<ControllersCubit>().textSizeController.clear();
      context.read<ControllersCubit>().packageNumber.clear();
      context.read<ControllersCubit>().note.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String fileName = context.read<ControllersCubit>().name.text;

    var uuid = const Uuid();

    return Scaffold(
      appBar: customAppBar(
        context,
        Row(
          children: [
            const Text(
              'إضافة منتج',
              style: TextStyle(color: kWhiteColor),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/EditProductsClassification');
              },
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
      body: BlocBuilder<GetClassificationsCubit, GetClassificationsState>(
        builder: (context, state) {
          if (state is GetClassificationsLoading) {
            return const Center(
                child: CircularProgressIndicator(
              color: kPrimaryColor,
            ));
          }
          if (state is GetClassificationsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context
                  .read<GetClassificationsCubit>()
                  .getProductsClassifications();
              _clearForm();
              context.read<ControllersCubit>().selectedSizeValue == null;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Form(
                key: formKey,
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );

                          if (pickedFile != null) {
                            final imageFile = File(pickedFile.path);

                            if (pickedFile.path
                                .toLowerCase()
                                .endsWith('.png')) {
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
                        child: CircleAvatar(
                          radius: 72,
                          backgroundColor: kPrimaryColor,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!)
                                : null,
                            child: selectedImage == null
                                ? const Icon(
                                    Icons.shopping_bag_rounded,
                                    color: kPrimaryColor,
                                    size: 64,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: screenWidth * 0.95,
                        child: TextField(
                          maxLength: 50,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          controller: context.read<ControllersCubit>().name,
                          decoration: const InputDecoration(
                            labelText: 'اسم المنتج',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const SizeWidget(),
                      const SizedBox(height: 12),
                      const PackageTypeWidget(),
                      const SizedBox(height: 12),
                      DropdownMenu(
                        width: screenWidth * 0.95,
                        dropdownMenuEntries: context
                            .read<GetClassificationsCubit>()
                            .classification
                            .entries
                            .map((entry) => DropdownMenuEntry(
                                  value: entry.value,
                                  label: entry.value,
                                ))
                            .toList(),
                        label: const Text('تصنيف المنتج'),
                        onSelected: (value) {
                          setState(() {
                            context.read<ControllersCubit>().classification =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu(
                        width: screenWidth * 0.95,
                        dropdownMenuEntries: context
                            .read<GetClassificationsCubit>()
                            .manufacturer
                            .entries
                            .map((entry) => DropdownMenuEntry(
                                  value: entry.key, // 🔹 Store key as value
                                  label: entry.value, // 🔹 Show value as label
                                ))
                            .toList(),
                        label: const Text('الشركة المصنعة'),
                        onSelected: (value) {
                          // 🔹 Update state when selected
                          setState(() {
                            context.read<ControllersCubit>().manufacturer =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: screenWidth * 0.95,
                        child: TextField(
                          maxLength: 100,
                          maxLines: 3,
                          controller: context.read<ControllersCubit>().note,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      customCircularElevatedButton(
                        icon: Icons.send,
                        context: context,
                        backgroundColor: Theme.of(context).primaryColor,
                        iconColor: Colors.white,
                        iconSize: 24,
                        onPressed: () async {
                          String name =
                              context.read<ControllersCubit>().name.text;
                          String manufacturer =
                              context.read<ControllersCubit>().manufacturer ??
                                  '';
                          String size =
                              '${context.read<ControllersCubit>().textSizeController.text} ${context.read<ControllersCubit>().selectedSizeValue}';

                          String package =
                              '${context.read<ControllersCubit>().packageType} = ${context.read<ControllersCubit>().packageNumber.text} × ${context.read<ControllersCubit>().packageUnit} ';
                          String classification =
                              context.read<ControllersCubit>().classification ??
                                  '';

                          if (selectedImage != null &&
                              name.isNotEmpty &&
                              manufacturer.isNotEmpty &&
                              context.read<ControllersCubit>().packageType !=
                                  null &&
                              classification.isNotEmpty) {
                            context
                                .read<FirestoreServicesCubit>()
                                .emitLoading();
                            imageUrl = await StorageService()
                                .uploadImage(context, selectedImage!, fileName)
                                .then((imageUrl) {
                              context
                                  .read<FirestoreServicesCubit>()
                                  .addProduct(
                                      context,
                                      Product(
                                          productId: uuid.v1(),
                                          imageUrl: imageUrl!,
                                          name: name,
                                          manufacturer: manufacturer,
                                          size: size,
                                          package: package,
                                          classification: classification,
                                          salesCount: 0,
                                          note: context
                                              .read<ControllersCubit>()
                                              .note
                                              .text),
                                      fileName)
                                  .then((_) {
                                _clearForm();
                              });

                              return null;
                            });
                          } else {
                            context.read<FirestoreServicesCubit>().emitError();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يجب ملء جميع الحقول'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SizeWidget extends StatefulWidget {
  const SizeWidget({super.key});

  @override
  _SizeWidgetState createState() => _SizeWidgetState();
}

class _SizeWidgetState extends State<SizeWidget> {
  @override
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    TextEditingController? textSizeController =
        context.read<ControllersCubit>().textSizeController;
    return SizedBox(
      width: screenWidth * 0.95,
      height: 60,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: textSizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الحجم',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: DropdownMenu<String>(
              label: const Text('مقدار'),
              width: double.infinity,
              onSelected: (value) {
                setState(() {
                  context.read<ControllersCubit>().selectedSizeValue = value;
                });
              },
              dropdownMenuEntries: context
                  .read<GetClassificationsCubit>()
                  .sizeUnit
                  .entries
                  .map((entry) => DropdownMenuEntry<String>(
                        value: entry.key,
                        label: entry.value,
                      ))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }
}

class PackageTypeWidget extends StatefulWidget {
  const PackageTypeWidget({super.key});

  @override
  State<PackageTypeWidget> createState() => _PackageTypeWidgetState();
}

class _PackageTypeWidgetState extends State<PackageTypeWidget> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.95,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownMenu(
              width: double.infinity, // ✅ Force it to take full width
              label: const Text(
                'نوع العبوة',
                style: TextStyle(fontSize: 12),
              ),
              dropdownMenuEntries: context
                  .read<GetClassificationsCubit>()
                  .packageType
                  .entries
                  .map((entry) => DropdownMenuEntry(
                        value: entry.key,
                        label: entry.value,
                      ))
                  .toList(),
              onSelected: (value) {
                context.read<ControllersCubit>().packageType = value;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 60,
              child: TextField(
                maxLength: 3,
                keyboardType: TextInputType.number,
                controller: context.read<ControllersCubit>().packageNumber,
                decoration: const InputDecoration(
                  labelText: 'عدد',
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '×',
            style: TextStyle(
              fontSize: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownMenu(
              width: double.infinity, // ✅ Force it to take full width
              label: const Text(
                'الوحدة',
                style: TextStyle(fontSize: 12),
              ),
              dropdownMenuEntries: context
                  .read<GetClassificationsCubit>()
                  .packageUnit
                  .entries
                  .map((entry) => DropdownMenuEntry(
                        value: entry.key,
                        label: entry.value,
                      ))
                  .toList(),
              onSelected: (value) {
                context.read<ControllersCubit>().packageUnit = value;
              },
            ),
          ),
        ],
      ),
    );
  }
}
