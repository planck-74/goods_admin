part of 'fetch_products_cubit.dart';

@immutable
sealed class FetchProductsState {}

final class FetchProductsInitial extends FetchProductsState {}

final class FetchProductsLoading extends FetchProductsState {}

final class FetchProductsLoaded extends FetchProductsState {
  final List<Product> products;

  FetchProductsLoaded(this.products);
}

final class FetchProductsError extends FetchProductsState {
  final String message;

  FetchProductsError(this.message);
}
