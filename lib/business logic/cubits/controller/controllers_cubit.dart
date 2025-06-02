import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/controller/controller_state.dart';

class ControllersCubit extends Cubit<ControllersState> {
  ControllersCubit() : super(ControllersInitial());

  // sign in controllers
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  // add product contorollers
  TextEditingController name = TextEditingController();
  TextEditingController note = TextEditingController();

  String? manufacturer;
  // size controllers
  TextEditingController textSizeController = TextEditingController();
  String? selectedSizeValue;
  TextEditingController packageNumber = TextEditingController();
  String? packageUnit;
  String? packageType;
  String? classification;
  void resetControllers() {
    name.clear();
    textSizeController.clear();
    packageNumber.clear();
    selectedSizeValue = null;
    packageType = null;
    packageUnit = null;
    classification = null;
    manufacturer = null;
    emit(ControllersUpdatedState()); // 🔹 تأكد من تحديث الحالة هنا
  }
}
