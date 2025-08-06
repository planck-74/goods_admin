import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/add_location/add_location_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_buttons/custom_outlinedButton.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_progress_indicator.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';

class AddCity extends StatefulWidget {
  const AddCity({super.key});

  @override
  State<AddCity> createState() => _AddCityState();
}

class _AddCityState extends State<AddCity> {
  TextEditingController controller = TextEditingController();
  String? selectedGovernment;

  @override
  void initState() {
    super.initState();
    context.read<AddLocationCubit>().fetchGovernments().then((_) {
      if (context.read<AddLocationCubit>().governmentList.isNotEmpty) {
        setState(() {
          selectedGovernment =
              context.read<AddLocationCubit>().governmentList.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> governmentList =
        context.watch<AddLocationCubit>().governmentList;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: customAppBar(
        context,
        const Text(
          'إضافة مدينة',
          style: TextStyle(color: whiteColor),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.95,
          child: BlocBuilder<AddLocationCubit, AddLocationState>(
            builder: (context, state) {
              if (state is AddLocationLoading) {
                return SizedBox(
                    height: 30,
                    width: 30,
                    child: customCircularProgressIndicator(context: context));
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'إضافة مدينة',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 24),
                  DropdownMenu<String>(
                    label: const Text(
                      'اختر المحافظة التابع لها المدينة',
                      style: TextStyle(fontSize: 16),
                    ),
                    width: screenWidth * 0.95,
                    textStyle: const TextStyle(
                      fontSize: 16,
                    ),
                    initialSelection: selectedGovernment,
                    dropdownMenuEntries: governmentList
                        .map((name) => DropdownMenuEntry<String>(
                              value: name,
                              label: name,
                            ))
                        .toList(),
                    onSelected: (newValue) {
                      setState(() {
                        selectedGovernment = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'أدخل إسم المدينة',
                    ),
                  ),
                  const SizedBox(height: 12),
                  customOutlinedButton2(
                    width: screenWidth * 0.95,
                    height: 50,
                    context: context,
                    child: state is AddLocationLoading
                        ? const CircularProgressIndicator()
                        : const Text('إضافة المدينة'),
                    onPressed: () {
                      if (selectedGovernment != null &&
                          controller.text.isNotEmpty) {
                        context
                            .read<AddLocationCubit>()
                            .addCity(selectedGovernment!, controller.text)
                            .then((_) {
                          controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تمت إضافة المدينة بنجاح')));
                        });
                      } else {
                        snackBarErrors(context, 'أدخل جميع الحقول');
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
