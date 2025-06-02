import 'package:goods_admin/data/models/client_model.dart';
import 'package:meta/meta.dart';

@immutable
abstract class GetClientDataState {}

class GetClientDataInitial extends GetClientDataState {}

class GetClientDataLoading extends GetClientDataState {}

class GetClientDataSuccess extends GetClientDataState {
  final List<ClientModel> clients;

  GetClientDataSuccess(this.clients);
}

class GetClientDataError extends GetClientDataState {
  final String message;

  GetClientDataError(this.message);
}
