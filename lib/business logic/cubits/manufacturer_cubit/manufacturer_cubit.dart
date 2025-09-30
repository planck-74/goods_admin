// lib/cubits/manufacturer_cubit.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/manufacturer_cubit/manufacturer_state.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';
import 'package:goods_admin/repos/manufacturer_repository.dart';

// Cubit
class ManufacturerCubit extends Cubit<ManufacturerState> {
  final ManufacturerRepository _repository;
  StreamSubscription<List<Manufacturer>>? _subscription;

  ManufacturerCubit(this._repository) : super(ManufacturerInitial());

  void loadManufacturers() {
    emit(ManufacturerLoading());
    _subscription?.cancel();
    _subscription = _repository.getManufacturers().listen(
      (manufacturers) {
        if (!isClosed) emit(ManufacturerLoaded(manufacturers));
      },
      onError: (error) {
        if (!isClosed) emit(ManufacturerError(error.toString()));
      },
    );
  }

  Future<void> addManufacturer({
    required String name,
    required File? imageFile,
    required int number,
  }) async {
    try {
      emit(ManufacturerOperationInProgress());

      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _repository.uploadImage(imageFile);
      }

      final manufacturer = Manufacturer(
        id: name, // Use name as the document ID
        name: name,
        imageUrl: imageUrl,
        productsIds: [],
        number: number,
      );

      // Save and get the manufacturer with the name as the ID
      final savedManufacturer = await _repository.addManufacturer(manufacturer);
      // Optionally, you could emit a state with the new manufacturer here
      loadManufacturers();
    } catch (e) {
      emit(ManufacturerError(e.toString()));
    }
  }

  Future<void> updateManufacturer({
    required Manufacturer manufacturer,
    File? newImageFile,
  }) async {
    try {
      emit(ManufacturerOperationInProgress());

      String imageUrl = manufacturer.imageUrl;
      if (newImageFile != null) {
        if (manufacturer.imageUrl.isNotEmpty) {
          await _repository.deleteImage(manufacturer.imageUrl);
        }
        imageUrl = await _repository.uploadImage(newImageFile);
      }

      final updatedManufacturer = manufacturer.copyWith(imageUrl: imageUrl);
      await _repository.updateManufacturer(updatedManufacturer);
      loadManufacturers();
    } catch (e) {
      emit(ManufacturerError(e.toString()));
    }
  }

  Future<void> deleteManufacturer(Manufacturer manufacturer) async {
    try {
      emit(ManufacturerOperationInProgress());

      if (manufacturer.imageUrl.isNotEmpty) {
        await _repository.deleteImage(manufacturer.imageUrl);
      }

      await _repository.deleteManufacturer(manufacturer.name);
      loadManufacturers();
    } catch (e) {
      emit(ManufacturerError(e.toString()));
    }
  }

  Future<void> reorderManufacturers(List<Manufacturer> manufacturers) async {
    try {
      await _repository.reorderManufacturers(manufacturers);
    } catch (e) {
      emit(ManufacturerError(e.toString()));
    }
  }

  Future<void> updateManufacturerNumber(
      Manufacturer manufacturer, int newNumber) async {
    try {
      final updatedManufacturer = manufacturer.copyWith(number: newNumber);
      await _repository.updateManufacturer(updatedManufacturer);
      loadManufacturers();
    } catch (e) {
      emit(ManufacturerError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
