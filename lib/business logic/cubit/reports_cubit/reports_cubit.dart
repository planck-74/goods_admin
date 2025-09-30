import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goods_admin/business%20logic/cubit/reports_cubit/reports_state.dart';
import 'package:goods_admin/data/models/order_model.dart';
import 'package:goods_admin/repos/orders_repository.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final OrdersRepository _repository;
  StreamSubscription<List<Order>>? _subscription;

  ReportsCubit(this._repository) : super(ReportsInitial());

  void loadReports() {
    emit(ReportsLoading());

    _subscription?.cancel();
    _subscription = _repository.getOrders().listen(
      (orders) {
        final data = _calculateReports(orders);
        emit(ReportsLoaded(data));
      },
      onError: (error) => emit(ReportsError(error.toString())),
    );
  }

  ReportsData _calculateReports(List<Order> orders) {
    final completedOrders =
        orders.where((o) => o.state == 'تم التوصيل').toList();
    final totalRevenue = completedOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalWithOffer,
    );

    // Revenue by date (last 7 days)
    final revenueByDate = <String, double>{};
    for (var i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      revenueByDate[dateKey] = 0;
    }

    for (var order in completedOrders) {
      final dateKey = '${order.date.month}/${order.date.day}';
      if (revenueByDate.containsKey(dateKey)) {
        revenueByDate[dateKey] =
            (revenueByDate[dateKey] ?? 0) + order.totalWithOffer;
      }
    }

    // Revenue by supplier
    final revenueBySupplier = <String, double>{};
    for (var order in completedOrders) {
      revenueBySupplier[order.supplierId] =
          (revenueBySupplier[order.supplierId] ?? 0) + order.totalWithOffer;
    }

    // Revenue by classification
    final revenueByClassification = <String, double>{};
    for (var order in completedOrders) {
      for (var product in order.products) {
        final classification = product.product.classification;
        final productTotal =
            (product.product.offerPrice ?? 0) * product.controller;
        revenueByClassification[classification] =
            (revenueByClassification[classification] ?? 0) + productTotal;
      }
    }

    return ReportsData(
      totalOrders: orders.length,
      completedOrders: completedOrders.length,
      totalRevenue: totalRevenue,
      revenueByDate: revenueByDate,
      revenueBySupplier: revenueBySupplier,
      revenueByClassification: revenueByClassification,
      allOrders: orders,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
