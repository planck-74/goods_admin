import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:goods_admin/business%20logic/cubits/image_picker_cubit/image_state.dart';
import 'package:image_picker/image_picker.dart';

class ImageCubit extends Cubit<ImageState> {
  ImageCubit() : super(ImageInitial());

  XFile? image;
  Future<void> pickImage() async {
    try {
      emit(ImageLoading());
      final ImagePicker picker = ImagePicker();
      image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        emit(ImageLoaded(File(image!.path)));
      } else {
        emit(ImageError('No image selected'));
      }
    } catch (e) {
      emit(ImageError('Failed to pick image: $e'));
      ('Error picking image: $e');
    }
  }
}
