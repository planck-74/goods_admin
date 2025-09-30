import 'dart:io';

abstract class ImageState {}

class ImageInitial extends ImageState {}

class ImageLoading extends ImageState {}

class ImageLoaded extends ImageState {
  final File image;

  ImageLoaded(this.image);
}

class ImageError extends ImageState {
  final String message;

  ImageError(this.message);
}
