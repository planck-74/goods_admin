abstract class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final ReportsData data;
  ReportsLoaded(this.data);
}

class ReportsError extends ReportsState {
  final String message;
  ReportsError(this.message);
}

class ReportsData {
  final int totalOrders;
  final int completedOrders;
  final double totalRevenue;
  final Map<String, double> revenueByDate;
  final Map<String, double> revenueBySupplier;
  final Map<String, double> revenueByClassification;
  final List allOrders;

  ReportsData({
    required this.totalOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.revenueByDate,
    required this.revenueBySupplier,
    required this.revenueByClassification,
    required this.allOrders,
  });
}
