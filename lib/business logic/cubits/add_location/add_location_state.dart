part of 'add_location_cubit.dart';

@immutable
sealed class AddLocationState {}

final class AddLocationInitial extends AddLocationState {}

final class AddLocationLoading extends AddLocationState {}

final class AddLocationSuccess extends AddLocationState {
  AddLocationSuccess();
}

final class AddLocationError extends AddLocationState {
  final String error;

  AddLocationError(this.error);
}
