import 'package:equatable/equatable.dart';
import 'package:goods_admin/data/models/order_model.dart';

abstract class OrdersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final String? currentFilter;
  final String? supplierFilter;

  OrdersLoaded({
    required this.orders,
    this.currentFilter,
    this.supplierFilter,
  });

  @override
  List<Object?> get props => [orders, currentFilter, supplierFilter];
}

class OrdersError extends OrdersState {
  final String message;

  OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrdersSearchResults extends OrdersState {
  final List<Order> results;

  OrdersSearchResults(this.results);

  @override
  List<Object?> get props => [results];
}
