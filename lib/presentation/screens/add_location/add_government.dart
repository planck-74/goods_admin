import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/add_location/add_location_cubit.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_app_bar%20copy.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_buttons/custom_outlinedButton.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';

class AddGovernment extends StatefulWidget {
  const AddGovernment({super.key});

  @override
  State<AddGovernment> createState() => _AddGovernmentState();
}

class _AddGovernmentState extends State<AddGovernment> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: customAppBar(
        context,
        const Text(
          'إضافة محافظة',
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
                'إضافة محافظة',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'أدخل إسم المحافظة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<AddLocationCubit, AddLocationState>(
                builder: (context, state) {
                  return customOutlinedButton2(
                    width: screenWidth * 0.95,
                    height: 50,
                    context: context,
                    child: state is AddLocationLoading
                        ? const CircularProgressIndicator()
                        : const Text('إضافة المحافظة'),
                    onPressed: () {
                      final govName = controller.text.trim();
                      if (govName.isEmpty) {
                        snackBarErrors(context, 'الرجاء إدخال إسم المحافظة');
                      } else {
                        context
                            .read<AddLocationCubit>()
                            .addGovernment(govName)
                            .then((_) {
                          controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تمت إضافة المحافظة بنجاح')));
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
