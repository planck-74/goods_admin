import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

part 'add_location_state.dart';

class AddLocationCubit extends Cubit<AddLocationState> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<String> governmentList = [];
  String selectedGovernment = '';
  List<String> cityList = [];

  AddLocationCubit() : super(AddLocationInitial());
  Future<void> addGovernment(String governmentName) async {
    emit(AddLocationLoading());
    try {
      await FirebaseFirestore.instance
          .collection('admin_data')
          .doc('locations')
          .collection('governments')
          .doc(governmentName)
          .set({
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(AddLocationSuccess());
    } catch (e) {
      emit(AddLocationError(e.toString()));
    }
  }

  Future<void> fetchGovernments() async {
    try {
      emit(AddLocationLoading());

      final snapshot = await FirebaseFirestore.instance
          .collection('admin_data')
          .doc('locations')
          .collection('governments')
          .get();

      governmentList = snapshot.docs.map((doc) => doc.id).toList();
      emit(AddLocationSuccess());
    } catch (e) {
      emit(AddLocationError(e.toString()));
    }
  }

  Future<void> addCity(String governmentName, String cityName) async {
    emit(AddLocationLoading());
    try {
      await FirebaseFirestore.instance
          .collection('admin_data')
          .doc('locations')
          .collection('governments')
          .doc(governmentName)
          .collection('cities')
          .doc(cityName)
          .set({
        'name': cityName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(AddLocationSuccess());
    } catch (e) {
      emit(AddLocationError(e.toString()));
    }
  }

  Future<void> fetchCities(String government) async {
    cityList.clear();
    final snapshot = await FirebaseFirestore.instance
        .collection('admin_data')
        .doc('locations')
        .collection('governments')
        .doc(government)
        .collection('cities')
        .get();

    for (var doc in snapshot.docs) {
      cityList.add(doc.id);
    }
    emit(AddLocationSuccess());
  }

  Future<void> addArea(String government, String city, String areaName,
      BuildContext context) async {
    emit(AddLocationLoading());
    try {
      await FirebaseFirestore.instance
          .collection('admin_data')
          .doc('locations')
          .collection('governments')
          .doc(government)
          .collection('cities')
          .doc(city)
          .collection('areas')
          .doc(areaName)
          .set({
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(AddLocationSuccess());
    } catch (e) {
      emit(AddLocationError(e.toString()));
    }
  }
}
