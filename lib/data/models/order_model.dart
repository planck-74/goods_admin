import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:goods_admin/data/models/product_model.dart';

/// Represents a product inside an order (wraps your Product model).
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
      addedAt: map['addedAt'] is int ? map['addedAt'] as int : 0,
      controller: map['controller'] is int ? map['controller'] as int : 0,
      product: Product.fromMap(map['product'] is Map<String, dynamic>
          ? (map['product'] as Map<String, dynamic>)
          : <String, dynamic>{}),
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

/// Unified Order model combining fields/logic from both variants.
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
  final String supplierName;
  final String storeId;
  final double total;
  final double totalWithOffer;
  final String? note;
  final DateTime? createdAt;
  final DateTime? lastModified;

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
    this.supplierName = '',
    this.storeId = '',
    required this.total,
    required this.totalWithOffer,
    this.note,
    this.createdAt,
    this.lastModified,
  });

  /// Create from a Firestore DocumentSnapshot
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Order.fromMap(map, id: doc.id);
  }

  /// Create from a plain map (e.g. fromMap usage or Firestore doc data)
  factory Order.fromMap(Map<String, dynamic> map, {String? id}) {
    // parse date (Timestamp or ISO string or DateTime)
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      return parseDate(value);
    }

    // parse products: could be list of maps or list of already OrderProduct-like objects
    List<OrderProduct> parseProducts(dynamic value) {
      if (value is List) {
        return value.map<OrderProduct>((p) {
          if (p is OrderProduct) return p;
          if (p is Map<String, dynamic>) return OrderProduct.fromMap(p);
          // sometimes products are raw product maps without wrapper:
          if (p is Map) {
            final mapP = Map<String, dynamic>.from(p as Map);
            return OrderProduct.fromMap({
              'addedAt': mapP['addedAt'] ?? 0,
              'controller': mapP['controller'] ?? 0,
              'product': mapP['product'] ?? mapP,
            });
          }
          return OrderProduct.fromMap({});
        }).toList();
      }
      return <OrderProduct>[];
    }

    return Order(
      id: id ?? (map['id']?.toString() ?? ''),
      clientId: map['clientId'] ?? '',
      date: parseDate(map['date'] ?? map['createdAt'] ?? Timestamp.now()),
      doneAt: parseNullableDate(map['doneAt']),
      itemCount: (map['itemCount'] is int)
          ? map['itemCount'] as int
          : int.tryParse(map['itemCount']?.toString() ?? '') ?? 0,
      orderCode: (map['orderCode'] is int)
          ? map['orderCode'] as int
          : int.tryParse(map['orderCode']?.toString() ?? '') ?? 0,
      products: parseProducts(map['products']),
      state: map['state'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      storeId: map['storeId'] ?? map['supplierId'] ?? '',
      total: (map['total'] != null)
          ? (map['total'] is num
              ? (map['total'] as num).toDouble()
              : double.tryParse(map['total'].toString()) ?? 0.0)
          : 0.0,
      totalWithOffer: (map['totalWithOffer'] != null)
          ? (map['totalWithOffer'] is num
              ? (map['totalWithOffer'] as num).toDouble()
              : double.tryParse(map['totalWithOffer'].toString()) ?? 0.0)
          : 0.0,
      note: map['note'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'])
              : null),
      lastModified: map['lastModified'] is Timestamp
          ? (map['lastModified'] as Timestamp).toDate()
          : (map['lastModified'] is String
              ? DateTime.tryParse(map['lastModified'])
              : null),
    );
  }

  /// Convert to map ready for Firestore.
  /// - date/doneAt/createdAt/lastModified are converted to Timestamp if not null.
  /// - createdAt/lastModified default to server timestamp when null (if you want that behaviour).
  Map<String, dynamic> toMap({bool setServerTimestampsIfNull = true}) {
    Object? timestampOrDate(DateTime? d) {
      if (d == null) {
        return (setServerTimestampsIfNull
            ? FieldValue.serverTimestamp()
            : null);
      }
      return Timestamp.fromDate(d);
    }

    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
      'doneAt': doneAt != null
          ? Timestamp.fromDate(doneAt!)
          : (setServerTimestampsIfNull ? null : null),
      'itemCount': itemCount,
      'orderCode': orderCode,
      'products': products.map((p) => p.toMap()).toList(),
      'state': state,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'storeId': storeId,
      'total': total,
      'totalWithOffer': totalWithOffer,
      'note': note,
      // server timestamps (optional)
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!)
      else if (setServerTimestampsIfNull)
        'createdAt': FieldValue.serverTimestamp(),
      if (lastModified != null)
        'lastModified': Timestamp.fromDate(lastModified!)
      else if (setServerTimestampsIfNull)
        'lastModified': FieldValue.serverTimestamp(),
    }..removeWhere((key, value) => value == null);
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
    String? supplierName,
    String? storeId,
    double? total,
    double? totalWithOffer,
    String? note,
    DateTime? createdAt,
    DateTime? lastModified,
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
      supplierName: supplierName ?? this.supplierName,
      storeId: storeId ?? this.storeId,
      total: total ?? this.total,
      totalWithOffer: totalWithOffer ?? this.totalWithOffer,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
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
        supplierName,
        storeId,
        total,
        totalWithOffer,
        note,
        createdAt,
        lastModified,
      ];

  @override
  String toString() {
    return 'Order(id: $id, orderCode: $orderCode, supplierId: $supplierId, supplierName: $supplierName, totalWithOffer: $totalWithOffer)';
  }
}
