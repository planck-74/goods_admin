part of 'get_classifications_cubit.dart';

@immutable
sealed class GetClassificationsState {}

final class GetClassificationsInitial extends GetClassificationsState {}

final class GetClassificationsLoading extends GetClassificationsState {}

final class GetClassificationsSuccess extends GetClassificationsState {
  GetClassificationsSuccess();
}

final class GetClassificationsError extends GetClassificationsState {
  final String message;

  GetClassificationsError(this.message);
}
