import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/add_location/add_location_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_buttons/custom_outlinedButton.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';

class AddArea extends StatefulWidget {
  const AddArea({super.key});

  @override
  State<AddArea> createState() => _AddAreaState();
}

class _AddAreaState extends State<AddArea> {
  final TextEditingController controller = TextEditingController();

  String? selectedGovernment;
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    context.read<AddLocationCubit>().fetchGovernments();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cubit = context.watch<AddLocationCubit>();

    return Scaffold(
      appBar: customAppBar(
        context,
        const Text(
          'إضافة منطقة',
          style: TextStyle(color: whiteColor),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.95,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'إضافة منطقة',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 24),
              DropdownMenu<String>(
                width: screenWidth * 0.95,
                label: const Text('اختر المحافظة'),
                dropdownMenuEntries: cubit.governmentList
                    .map((gov) => DropdownMenuEntry(value: gov, label: gov))
                    .toList(),
                onSelected: (newValue) {
                  setState(() {
                    selectedGovernment = newValue;
                    selectedCity = null;
                    cubit.fetchCities(newValue!);
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                width: screenWidth * 0.95,
                label: const Text('اختر المدينة'),
                dropdownMenuEntries: cubit.cityList
                    .map((city) => DropdownMenuEntry(value: city, label: city))
                    .toList(),
                onSelected: (newValue) {
                  setState(() {
                    selectedCity = newValue;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'أدخل إسم المنطقة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              customOutlinedButton2(
                width: screenWidth * 0.95,
                height: 50,
                context: context,
                child: cubit.state is AddLocationLoading
                    ? const CircularProgressIndicator()
                    : const Text('إضافة المنطقة'),
                onPressed: () {
                  final name = controller.text.trim();
                  if (selectedGovernment != null &&
                      selectedCity != null &&
                      name.isNotEmpty) {
                    cubit
                        .addArea(
                            selectedGovernment!, selectedCity!, name, context)
                        .then((_) {
                      controller.clear();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تمت إضافة المنطقة بنجاح')));
                    });
                  } else {
                    snackBarErrors(context, 'الرجاء إدخال جميع الحقول');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
