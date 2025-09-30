import 'package:equatable/equatable.dart';
import 'package:goods_admin/data/models/manufacturer_model.dart';

abstract class ManufacturerState extends Equatable {
  const ManufacturerState();

  @override
  List<Object?> get props => [];
}

class ManufacturerInitial extends ManufacturerState {}

class ManufacturerLoading extends ManufacturerState {}

class ManufacturerLoaded extends ManufacturerState {
  final List<Manufacturer> manufacturers;

  const ManufacturerLoaded(this.manufacturers);

  @override
  List<Object?> get props => [manufacturers];
}

class ManufacturerError extends ManufacturerState {
  final String message;

  const ManufacturerError(this.message);

  @override
  List<Object?> get props => [message];
}

class ManufacturerOperationInProgress extends ManufacturerState {}
