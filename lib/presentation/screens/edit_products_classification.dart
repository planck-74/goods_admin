import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/add_classification_cubit/add_classification_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_buttons/custom_outlinedButton.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';

class EditProductsClassification extends StatefulWidget {
  const EditProductsClassification({super.key});

  @override
  State<EditProductsClassification> createState() =>
      _EditProductsClassificationState();
}

class _EditProductsClassificationState
    extends State<EditProductsClassification> {
  TextEditingController controller = TextEditingController();
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: customAppBar(
          context,
          const Text(
            'تعديل التصنيفات',
            style: TextStyle(color: kWhiteColor),
          ),
        ),
        body: Center(
          child: SizedBox(
            width: screenWidth * 0.95,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'تعديل التصنيفات',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(
                  height: 24,
                ),
                DropdownMenu(
                  label: const Text(
                    'اختر ما تريد إضافته',
                    style: TextStyle(fontSize: 16),
                  ),
                  width: screenWidth * 0.95,
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(
                        value: 'classification', label: 'تصنيف المنتج'),
                    DropdownMenuEntry(
                        value: 'manufacturer', label: 'الشركة المصنعة'),
                    DropdownMenuEntry(value: 'size_unit', label: 'وحدة الحجم'),
                    DropdownMenuEntry(
                        value: 'package_type', label: 'نوع العبوة'),
                    DropdownMenuEntry(
                        value: 'package_unit', label: 'وحدة العبوة'),
                  ],
                  onSelected: (newValue) {
                    setState(() {
                      selectedValue = newValue; // Update selected value
                    });
                    print(
                        'Selected Value: $selectedValue'); // Print the selected value
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'أدخل ما ترغب في إضافته',
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                customOutlinedButton2(
                    width: screenWidth * 0.95,
                    height: 50,
                    context: context,
                    child: BlocBuilder<AddClassificationCubit,
                        AddClassificationState>(
                      builder: (context, state) {
                        if (state is AddClassificationLoading) {
                          return const CircularProgressIndicator();
                        }
                        return const Text('إضافة');
                      },
                    ),
                    onPressed: () {
                      if (selectedValue != null && controller.text.isNotEmpty) {
                        context
                            .read<AddClassificationCubit>()
                            .uploadNewClassification(
                                selectedValue!, controller.text, context)
                            .then((_) {
                          controller.clear();
                        });
                      } else {
                        snackBarErrors(context, 'أدخل جميع الحقول');
                      }
                    }),
              ],
            ),
          ),
        ));
  }
}
