import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String productId;
  final String imageUrl;
  final String name;
  final String manufacturer;
  final String? size;
  final String package;
  final String classification;
  final String? note;
  final int salesCount;
  final double? price; // اختياري
  final double? offerPrice; // اختياري
  final bool? availability; // اختياري

  const Product({
    required this.productId,
    required this.imageUrl,
    required this.name,
    required this.manufacturer,
    this.size,
    required this.package,
    required this.classification,
    this.note,
    required this.salesCount,
    this.price,
    this.offerPrice,
    this.availability,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['productId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      name: map['name'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      size: map['size'],
      package: map['package'] ?? '',
      classification: map['classification'] ?? '',
      note: map['note'],
      salesCount: map['salesCount'] ?? 0,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      offerPrice: map['offerPrice'] != null
          ? (map['offerPrice'] as num).toDouble()
          : null,
      availability: map['availability'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'imageUrl': imageUrl,
      'name': name,
      'manufacturer': manufacturer,
      'size': size,
      'package': package,
      'classification': classification,
      'note': note,
      'salesCount': salesCount,
      if (price != null) 'price': price,
      if (offerPrice != null) 'offerPrice': offerPrice,
      if (availability != null) 'availability': availability,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        imageUrl,
        name,
        manufacturer,
        size,
        package,
        classification,
        note,
        salesCount,
        price,
        offerPrice,
        availability,
      ];
}
