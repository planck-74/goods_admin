import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:goods_admin/data/models/order_model.dart';

class OrdersRepository {
  final FirebaseFirestore _firestore;

  OrdersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Order>> getOrders({
    String? stateFilter,
    String? supplierIdFilter,
  }) {
    Query query = _firestore.collection('orders');

    if (stateFilter != null && stateFilter.isNotEmpty) {
      query = query.where('state', isEqualTo: stateFilter);
    }

    if (supplierIdFilter != null && supplierIdFilter.isNotEmpty) {
      query = query.where('supplierId', isEqualTo: supplierIdFilter);
    }

    return query.orderBy('date', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
        );
  }

  Future<List<Order>> searchOrders(String searchTerm) async {
    final allOrders = await _firestore.collection('orders').get();

    return allOrders.docs
        .map((doc) => Order.fromFirestore(doc))
        .where((order) =>
            order.orderCode.toString().contains(searchTerm) ||
            order.clientId.toLowerCase().contains(searchTerm.toLowerCase()))
        .toList();
  }

  Future<void> updateOrderState(String orderId, String newState) async {
    final updates = <String, dynamic>{'state': newState};

    if (newState == 'تم التوصيل') {
      updates['doneAt'] = DateTime.now().toIso8601String();
    }

    await _firestore.collection('orders').doc(orderId).update(updates);
  }

  Future<Order?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return Order.fromFirestore(doc);
    }
    return null;
  }
}
