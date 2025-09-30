part of 'add_classification_cubit.dart';

@immutable
sealed class AddClassificationState {}

final class AddClassificationInitial extends AddClassificationState {}

final class AddClassificationLoading extends AddClassificationState {}

final class AddClassificationLoaded extends AddClassificationState {}
