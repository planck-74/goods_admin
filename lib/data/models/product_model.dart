class Product {
  final String productId;
  final String imageUrl;
  final String name;
  final String manufacturer;
  final String? size;
  final String package;
  final String classification;
  final String? note;
  final int salesCount;

  Product({
    required this.productId,
    required this.imageUrl,
    required this.name,
    required this.manufacturer,
    this.size,
    required this.package,
    required this.classification,
    this.note,
    required this.salesCount,
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
    };
  }
}
