import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubit/orders_cubit/orders_state.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/repos/orders_repository.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository _repository;
  StreamSubscription<List<Order>>? _ordersSubscription;

  OrdersCubit(this._repository) : super(OrdersInitial());

  void loadOrders({String? stateFilter, String? supplierFilter}) {
    emit(OrdersLoading());

    _ordersSubscription?.cancel();
    _ordersSubscription = _repository
        .getOrders(
          stateFilter: stateFilter,
          supplierIdFilter: supplierFilter,
        )
        .listen(
          (orders) => emit(OrdersLoaded(
            orders: orders,
            currentFilter: stateFilter,
            supplierFilter: supplierFilter,
          )),
          onError: (error) => emit(OrdersError(error.toString())),
        );
  }

  Future<void> searchOrders(String searchTerm) async {
    try {
      final results = await _repository.searchOrders(searchTerm);
      emit(OrdersSearchResults(results));
    } catch (e) {
      emit(OrdersError('Search failed: $e'));
    }
  }

  Future<void> updateOrderState(String orderId, String newState) async {
    try {
      await _repository.updateOrderState(orderId, newState);
    } catch (e) {
      emit(OrdersError('Failed to update order: $e'));
    }
  }

  void resetToOrders() {
    loadOrders();
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
