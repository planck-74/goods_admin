// cubit/carousel_cubit.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/data/models/carousel_image_model.dart';

// States
abstract class CarouselState extends Equatable {
  const CarouselState();

  @override
  List<Object?> get props => [];
}

class CarouselInitial extends CarouselState {}

class CarouselLoading extends CarouselState {}

class CarouselLoaded extends CarouselState {
  final List<CarouselImageModel> images;
  final List<String> fallbackImages;

  const CarouselLoaded({
    required this.images,
    required this.fallbackImages,
  });

  @override
  List<Object?> get props => [images, fallbackImages];
}

class CarouselError extends CarouselState {
  final String message;

  const CarouselError(this.message);

  @override
  List<Object?> get props => [message];
}

class CarouselUploading extends CarouselState {}

class CarouselUploadSuccess extends CarouselState {}

class CarouselUploadError extends CarouselState {
  final String message;

  const CarouselUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
