import 'package:equatable/equatable.dart';
import 'package:goods_admin/data/models/order_model.dart';

class ReportsData extends Equatable {
  final int totalOrders;
  final int completedOrders;
  final double totalRevenue;
  final Map<String, double> revenueByDate;
  final Map<String, double> revenueBySupplier;
  final Map<String, double> revenueByClassification;
  final List<Order> allOrders;

  const ReportsData({
    required this.totalOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.revenueByDate,
    required this.revenueBySupplier,
    required this.revenueByClassification,
    required this.allOrders,
  });

  @override
  List<Object?> get props => [
        totalOrders,
        completedOrders,
        totalRevenue,
        revenueByDate,
        revenueBySupplier,
        revenueByClassification,
        allOrders,
      ];
}

abstract class ReportsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final ReportsData data;

  ReportsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ReportsError extends ReportsState {
  final String message;

  ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
