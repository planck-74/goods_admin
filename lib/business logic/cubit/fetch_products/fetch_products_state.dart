part of 'fetch_products_cubit.dart';

@immutable
sealed class FetchProductsState {}

final class FetchProductsInitial extends FetchProductsState {}

final class FetchProductsLoading extends FetchProductsState {}

final class FetchProductsLoaded extends FetchProductsState {
  final List<Product> products;

  FetchProductsLoaded(this.products);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchProductsLoaded &&
        other.products.length == products.length &&
        other.products.every((product) => products.contains(product));
  }

  @override
  int get hashCode => products.hashCode;
}

final class FetchProductsError extends FetchProductsState {
  final String message;

  FetchProductsError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FetchProductsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
