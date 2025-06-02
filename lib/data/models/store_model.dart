class Store {
  String storeId; // معرف المتجر
  String supplierId; // معرف المورد
  List<StoreProduct> products; // قائمة بالمنتجات في المتجر

  Store({
    required this.storeId,
    required this.supplierId,
    required this.products,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'supplierId': supplierId,
      'products': products.map((product) => product.toMap()).toList(),
    };
  }

  Store.fromMap(Map<String, dynamic> map)
      : storeId = map['storeId'],
        supplierId = map['supplierId'],
        products = List<StoreProduct>.from(
            map['products'].map((product) => StoreProduct.fromMap(product)));
}

class StoreProduct {
  String productId;
  String availability; 
  String? offer;

  StoreProduct({
    required this.productId,
    required this.availability,
    this.offer,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'availability': availability,
      'offer': offer,
    };
  }

  StoreProduct.fromMap(Map<String, dynamic> map)
      : productId = map['productId'],
        availability = map['availability'],
        offer = map['offer'];
}
