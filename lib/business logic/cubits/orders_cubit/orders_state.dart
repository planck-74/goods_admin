abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List orders;
  final String? currentFilter;
  final String? supplierFilter;

  OrdersLoaded({
    required this.orders,
    this.currentFilter,
    this.supplierFilter,
  });
}

class OrdersSearchResults extends OrdersState {
  final List results;
  OrdersSearchResults(this.results);
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}
