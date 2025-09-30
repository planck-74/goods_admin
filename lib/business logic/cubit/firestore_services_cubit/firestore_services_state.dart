abstract class FirestoreServicesState {}

class FirestoreServicesInitial extends FirestoreServicesState {}

class FirestoreServicesLoading extends FirestoreServicesState {}

class FirestoreServicesLoaded extends FirestoreServicesState {}

class FirestoreServicesError extends FirestoreServicesState {
  final String message;

  FirestoreServicesError(this.message);
}
