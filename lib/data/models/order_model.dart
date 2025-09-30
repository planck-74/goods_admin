import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:goods_admin/data/models/product_model.dart';

class OrderProduct extends Equatable {
  final int addedAt;
  final int controller;
  final Product product;

  const OrderProduct({
    required this.addedAt,
    required this.controller,
    required this.product,
  });

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      addedAt: map['addedAt'] ?? 0,
      controller: map['controller'] ?? 0,
      product: Product.fromMap(map['product'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addedAt': addedAt,
      'controller': controller,
      'product': product.toMap(),
    };
  }

  @override
  List<Object?> get props => [addedAt, controller, product];
}

class Order extends Equatable {
  final String id;
  final String clientId;
  final DateTime date;
  final DateTime? doneAt;
  final int itemCount;
  final int orderCode;
  final List<OrderProduct> products;
  final String state;
  final String supplierId;
  final double total;
  final double totalWithOffer;

  const Order({
    required this.id,
    required this.clientId,
    required this.date,
    this.doneAt,
    required this.itemCount,
    required this.orderCode,
    required this.products,
    required this.state,
    required this.supplierId,
    required this.total,
    required this.totalWithOffer,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      doneAt: (data['doneAt'] is Timestamp)
          ? (data['doneAt'] as Timestamp).toDate()
          : (data['doneAt'] != null
              ? DateTime.tryParse(data['doneAt'].toString())
              : null),
      itemCount: data['itemCount'] ?? 0,
      orderCode: data['orderCode'] ?? 0,
      products: (data['products'] as List<dynamic>?)
              ?.map((p) => OrderProduct.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      state: data['state'] ?? '',
      supplierId: data['supplierId'] ?? '',
      total: (data['total'] ?? 0).toDouble(),
      totalWithOffer: (data['totalWithOffer'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': date.toIso8601String(),
      'doneAt': doneAt?.toIso8601String(),
      'itemCount': itemCount,
      'orderCode': orderCode,
      'products': products.map((p) => p.toMap()).toList(),
      'state': state,
      'supplierId': supplierId,
      'total': total,
      'totalWithOffer': totalWithOffer,
    };
  }

  Order copyWith({
    String? id,
    String? clientId,
    DateTime? date,
    DateTime? doneAt,
    int? itemCount,
    int? orderCode,
    List<OrderProduct>? products,
    String? state,
    String? supplierId,
    double? total,
    double? totalWithOffer,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      doneAt: doneAt ?? this.doneAt,
      itemCount: itemCount ?? this.itemCount,
      orderCode: orderCode ?? this.orderCode,
      products: products ?? this.products,
      state: state ?? this.state,
      supplierId: supplierId ?? this.supplierId,
      total: total ?? this.total,
      totalWithOffer: totalWithOffer ?? this.totalWithOffer,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        date,
        doneAt,
        itemCount,
        orderCode,
        products,
        state,
        supplierId,
        total,
        totalWithOffer,
      ];
}
