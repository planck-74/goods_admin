import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goods_admin/presentation/custom_widgets/snack_bar.dart';

part 'add_classification_state.dart';

class AddClassificationCubit extends Cubit<AddClassificationState> {
  AddClassificationCubit() : super(AddClassificationInitial());
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future uploadNewClassification(String newClassification,
      String classificationName, BuildContext context) async {
    emit(AddClassificationLoading());

    // Await the asynchronous update call
    await db
        .collection('admin_data')
        .doc(newClassification)
        .update({classificationName: classificationName});

    emit(AddClassificationLoaded());
    showSuccessMessage(context, 'تمت الإضافة');
  }
}
