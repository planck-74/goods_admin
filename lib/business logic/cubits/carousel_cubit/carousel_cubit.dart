import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubits/carousel_cubit/carousel_state.dart';
import 'package:goods_admin/data/models/carousel_image_model.dart';
import 'package:goods_admin/services/carousel_services.dart';

class CarouselCubit extends Cubit<CarouselState> {
  final CarouselService _carouselService = CarouselService();

  static const List<String> _fallbackImages = [
    'assets/images/1000002880.png',
    'assets/images/1000002880.png',
    'assets/images/1000002880.png',
    'assets/images/1000002880.png',
  ];

  CarouselCubit() : super(CarouselInitial());

  void loadCarouselImages() {
    emit(CarouselLoading());

    _carouselService.getAllCarouselImages().listen(
      (images) {
        emit(CarouselLoaded(
          images: images,
          fallbackImages: _fallbackImages,
        ));
      },
      onError: (error) {
        emit(CarouselError('فشل في تحميل الصور: $error'));
      },
    );
  }

  Future<void> uploadImage() async {
    try {
      emit(CarouselUploading());

      final File? imageFile = await _carouselService.pickImage();
      if (imageFile == null) {
        emit(const CarouselUploadError('لم يتم اختيار صورة'));
        loadCarouselImages();
        return;
      }

      final currentState = state;
      int nextOrder = 0;
      if (currentState is CarouselLoaded) {
        nextOrder = currentState.images.length;
      }

      await _carouselService.addCarouselImage(imageFile, nextOrder);
      emit(CarouselUploadSuccess());

      loadCarouselImages();
    } catch (e) {
      emit(CarouselUploadError(e.toString()));
      loadCarouselImages();
    }
  }

  Future<void> deleteImage(String imageId, String imageUrl) async {
    try {
      await _carouselService.deleteCarouselImage(imageId, imageUrl);
    } catch (e) {
      emit(CarouselError('فشل في حذف الصورة: $e'));
    }
  }

  Future<void> toggleImageStatus(String imageId, bool currentStatus) async {
    try {
      await _carouselService.toggleImageStatus(imageId, !currentStatus);
    } catch (e) {
      emit(CarouselError('فشل في تحديث حالة الصورة: $e'));
    }
  }

  Future<void> reorderImages(List<CarouselImageModel> reorderedImages) async {
    try {
      // تحديث الترتيب مؤقتاً في الـ UI
      if (state is CarouselLoaded) {
        emit(CarouselLoaded(
          images: reorderedImages,
          fallbackImages: _fallbackImages,
        ));
      }

      // حفظ الترتيب الجديد في Firebase
      await _carouselService.reorderImages(reorderedImages);
    } catch (e) {
      emit(CarouselError('فشل في إعادة الترتيب: $e'));
      loadCarouselImages();
    }
  }

  Future<void> updateImageOrder(String imageId, int newOrder) async {
    try {
      await _carouselService.updateImageOrder(imageId, newOrder);
    } catch (e) {
      emit(CarouselError('فشل في تحديث الترتيب: $e'));
    }
  }
}
